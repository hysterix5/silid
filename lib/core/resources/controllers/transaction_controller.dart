import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class TransactionController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  var transactions = <Map<String, dynamic>>[].obs; // List of transactions

  /// ✅ Add a new transaction log
  Future<void> addTransaction({
    required String teacherId,
    required double amount,
    required String status, // "success" or "failed"
    required String referenceNumber,
  }) async {
    try {
      await _firestore.collection('transaction_logs').add({
        "teacherId": teacherId,
        "amount": amount,
        "status": status,
        "referenceNumber": referenceNumber,
        "timestamp": FieldValue.serverTimestamp(),
      });

      Get.snackbar("Transaction Logged", "Your transaction has been recorded.");
    } catch (e) {
      Get.snackbar("Error", "Failed to log transaction: $e");
    }
  }

  /// ✅ Fetch all transactions (for admin view)
  Future<void> fetchAllTransactions() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('transaction_logs')
          .orderBy("timestamp", descending: true)
          .get();

      transactions.value = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch transactions: $e");
    }
  }

  /// ✅ Fetch transactions for a specific teacher
  Future<void> fetchTransactionsForTeacher(String teacherId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('transaction_logs')
          .where("teacherId", isEqualTo: teacherId)
          .orderBy("timestamp", descending: true)
          .get();

      transactions.value = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch transactions: $e");
    }
  }
}
