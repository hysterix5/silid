import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:silid/core/resources/controllers/teacher_controller.dart';
import 'package:silid/core/resources/models/teacher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;

class PaymentController extends GetxController {
  var hasPendingPayment = false.obs;
  var teacher = Rx<Teacher?>(null);
  var referenceNumber = "".obs;

  void setTeacher(Teacher? teacherData) {
    teacher.value = teacherData;
    startPayment();
  }

  @override
  void onInit() {
    super.onInit();

    // Listen for URL hash changes (detects redirection back from PayMaya)
    html.window.onHashChange.listen((event) {
      handlePaymentOnLoad();
    });

    // Check the URL on app load (in case user reloads)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      handlePaymentOnLoad();
    });
  }

  void handlePaymentOnLoad() {
    String currentUrl = html.window.location.href;
    if (currentUrl.contains("payment-success") ||
        currentUrl.contains("payment-failed") ||
        currentUrl.contains("payment-cancelled")) {
      handlePayment();
    }
  }

  /// Generates a unique reference number
  String generateReferenceNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9000) + 1000;
    return "SILID-$timestamp-$random";
  }

  Future<void> startPayment() async {
    if (teacher.value == null) {
      debugPrint("Teacher data is not available.");
      return;
    }

    hasPendingPayment.value = true;

    // ✅ Store teacherId & reference number in localStorage
    html.window.localStorage['teacherId'] = teacher.value!.uid;
    referenceNumber.value = generateReferenceNumber();
    html.window.localStorage['referenceNumber'] = referenceNumber.value;

    const String publicKey = "pk-gZogC1BA5NyJGvhqmJemiRdti4SqoqCcGNgnA1lOsS9";
    const String checkoutUrl = "https://pg.paymaya.com/checkout/v1/checkouts";

    final Map<String, dynamic> checkoutData = {
      "totalAmount": {
        "value": 0.01,
        "currency": "PHP",
      },
      "buyer": {
        "firstName": teacher.value!.firstName,
        "lastName": teacher.value!.lastName,
        "contact": {"email": teacher.value!.email, "phone": ""}
      },
      "redirectUrl": {
        "success": "https://silid-b01f6.web.app/#/payment-success",
        "failure": "https://silid-b01f6.web.app/#/payment-failed",
        "cancel": "https://silid-b01f6.web.app/#/payment-cancelled"
      },
      "requestReferenceNumber": referenceNumber.value,
    };

    try {
      final response = await http.post(
        Uri.parse(checkoutUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Basic ${base64Encode(utf8.encode('$publicKey:'))}",
        },
        body: jsonEncode(checkoutData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final paymentUrl = data['redirectUrl'];

        if (paymentUrl != null) {
          // ✅ Use `html.window.open` for better Web redirection handling
          html.window.open(paymentUrl, "_self");
        } else {
          debugPrint("Invalid payment URL.");
          hasPendingPayment.value = false;
        }
      } else {
        debugPrint("Error creating checkout: ${response.body}");
        hasPendingPayment.value = false;
      }
    } catch (e) {
      debugPrint("Payment error: $e");
      hasPendingPayment.value = false;
    }
  }

  Future<void> handlePayment() async {
    String? teacherId = html.window.localStorage['teacherId'];
    String? storedReference = html.window.localStorage['referenceNumber'];

    if (teacherId == null || storedReference == null) {
      debugPrint("Error: Missing transaction details.");
      return;
    }

    bool isSuccess = html.window.location.href.contains('payment-success');
    bool isFailed = html.window.location.href.contains('payment-failed');

    if (isSuccess || isFailed) {
      // ✅ Check if transaction already exists before adding to Firestore
      var existingTransaction = await FirebaseFirestore.instance
          .collection('transaction_logs')
          .where('referenceNumber', isEqualTo: storedReference)
          .get();

      if (existingTransaction.docs.isNotEmpty) {
        debugPrint("Duplicate transaction detected, skipping...");
      } else {
        await FirebaseFirestore.instance.collection('transaction_logs').add({
          "teacherId": teacherId,
          "amount": 1.00,
          "status": isSuccess ? "success" : "failed",
          "referenceNumber": storedReference,
          "timestamp": Timestamp.now(),
        });

        if (isSuccess) {
          final docRef =
              FirebaseFirestore.instance.collection('teachers').doc(teacherId);

          await docRef.get().then((doc) async {
            if (doc.exists) {
              // ✅ Get the current subscription date
              Timestamp? currentTimestamp = doc['subscribed_until'];
              DateTime currentDate =
                  currentTimestamp?.toDate() ?? DateTime.now();

              // ✅ Add 30 days
              DateTime newDate = currentDate.add(const Duration(days: 30));

              // ✅ Update Firestore with the new subscription date
              await docRef.update({
                "subscribed_until": Timestamp.fromDate(newDate),
              });

              // ✅ Refresh teacher data in GetX state
              await Get.find<TeacherController>().fetchTeacherData(teacherId);
            }
          });
        }
      }

      // ✅ Clear stored values after processing
      html.window.localStorage.remove('teacherId');
      html.window.localStorage.remove('referenceNumber');
    }
  }
}
