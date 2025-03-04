import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:silid/core/resources/controllers/student_controller.dart';
import 'package:silid/core/resources/controllers/teacher_controller.dart';
import 'package:silid/core/resources/models/teacher.dart';
import 'package:silid/core/utility/widgets/snackbar.dart';

class DataController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  var teachers = <Teacher>[].obs;
  var schedules = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    Get.put(TeacherController());
    Get.put(StudentController());
    super.onInit();
  }

  Future<void> checkUserAndNavigate(String? userId) async {
    if (userId == null) {
      Get.snackbar('Error', 'User not authenticated.');
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;

    try {
      // Admin Check FIRST before fetching Firestore
      if (user?.email == "test@admin.com") {
        await _firestore.collection('administrators').doc(user?.uid).set({
          "email": user?.email,
          "name": "Test Admin",
          "uid": user?.uid,
        });

        Get.offAllNamed('/admin');
        return;
      }

      // Fetch user roles in parallel
      var results = await Future.wait([
        _firestore.collection('teachers').doc(userId).get(),
        _firestore.collection('students').doc(userId).get(),
        _firestore.collection('administrators').doc(userId).get(),
      ]);

      var teacherDoc = results[0];
      var studentDoc = results[1];
      var adminDoc = results[2];

      if (teacherDoc.exists) {
        await Get.find<TeacherController>().fetchTeacherData(userId);
        Get.offAllNamed('/teacher-dashboard');
        return;
      }

      if (studentDoc.exists) {
        await Get.find<StudentController>().fetchStudentData(userId);
        Get.offAllNamed('/student-dashboard');
        return;
      }

      if (adminDoc.exists) {
        Get.offAllNamed('/admin');
        return;
      }

      // No role found, navigate to Newcomer page
      Get.offAllNamed('/newcomer');
    } catch (e) {
      SnackbarWidget.showError("An error occurred: $e");
    }
  }

  Future<void> fetchSchedules(String teacherId) async {
    isLoading.value = true;
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('teachers')
          .doc(teacherId)
          .collection('schedules')
          .get();

      if (querySnapshot.docs.isEmpty) {
        // 🛑 No schedules found, handle accordingly (optional)
        schedules.value = [];
        return;
      }

      schedules.value = querySnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return {
          'uid': doc.id,
          'date': (data['date'] as Timestamp)
              .toDate(), // ✅ Ensure proper date conversion
          'timeslots': List.from(data['timeslots'] ?? []),
        };
      }).toList();
    } catch (e) {
      SnackbarWidget.showError("Failed to fetch schedules: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateTimeslotStatus(
      String scheduleId, String teacherId, int index) async {
    try {
      var scheduleIndex =
          schedules.indexWhere((schedule) => schedule['uid'] == scheduleId);
      if (scheduleIndex == -1) return;

      var schedule = schedules[scheduleIndex];
      List<dynamic> timeslots = List.from(schedule['timeslots']);

      // ✅ Toggle status
      timeslots[index]['status'] =
          timeslots[index]['status'] == 'open' ? 'booked' : 'open';

      // ✅ Update Firestore
      await FirebaseFirestore.instance
          .collection('teachers')
          .doc(teacherId)
          .collection('schedules')
          .doc(scheduleId)
          .update({'timeslots': timeslots});

      // ✅ Update observable list (triggers UI update)
      schedules[scheduleIndex]['timeslots'] = timeslots;
      schedules.refresh(); // 🔥 UI updates automatically
    } catch (e) {
      SnackbarWidget.showError("Failed to update timeslot $e");
    }
  }
}
