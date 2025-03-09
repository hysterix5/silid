import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:silid/core/resources/controllers/auth_controller.dart';
import 'package:silid/core/resources/controllers/student_controller.dart';
import 'package:silid/core/resources/models/teacher.dart';
import 'package:silid/core/utility/widgets/snackbar.dart';
import 'package:silid/core/views/student/bookpage.dart';

class TeacherController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Rx<Teacher?> teacher = Rx<Teacher?>(null);
  var teachers = <Teacher>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    final user = Get.find<AuthController>().currentUser.value;
    if (user != null) {
      listenToTeacherUpdates(user.uid);
    }
    fetchTeachers(); // Keep fetching all teachers
  }

  void listenToTeacherUpdates(String teacherId) {
    _firestore.collection('teachers').doc(teacherId).snapshots().listen((doc) {
      if (doc.exists) {
        teacher.value = Teacher.fromFirestore(doc);
      }
    });
  }

  Future<void> submitTeacherData(Teacher teacher) async {
    try {
      isLoading(true);
      await _firestore
          .collection('teachers')
          .doc(teacher.uid)
          .set(teacher.toFirestore());
      this.teacher.value = teacher; // Update local state
      isLoading(false);
    } catch (e) {
      rethrow;
    }
  }

  Future<Teacher?> fetchTeacherData(String uid) async {
    try {
      DocumentSnapshot teacherDoc =
          await _firestore.collection('teachers').doc(uid).get();

      if (!teacherDoc.exists) {
        SnackbarWidget.showError("Teacher not found.");
        return null;
      }
      Teacher teacher = Teacher.fromFirestore(teacherDoc);
      this.teacher.value = teacher;

      // ✅ Start real-time listener after fetching data
      listenToTeacherUpdates(uid);

      return teacher;
    } catch (e) {
      SnackbarWidget.showError("Failed to fetch teacher data: $e");
      return null;
    }
  }

  void fetchTeachers() async {
    try {
      isLoading(true);

      var snapshot = await _firestore.collection('teachers').get();

      if (snapshot.docs.isEmpty) {
        SnackbarWidget.showError("No teachers found");
      }
      teachers.value =
          snapshot.docs.map((doc) => Teacher.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint("Error fetching teachers: $e");
      SnackbarWidget.showError("Failed to fetch teachers $e");
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchTeacherByCode(String teacherCode, String studentId,
      String studentFirstName, String studentLastName) async {
    final StudentController studentController = Get.find<StudentController>();
    try {
      isLoading(true);
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('teachers')
          .where('uniqueCode', isEqualTo: teacherCode)
          .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint("Code Invalid");
      } else {
        // Get teacher data safely
        var teacherData =
            querySnapshot.docs.first.data() as Map<String, dynamic>;

        final String teacherId = teacherData['uid'] ?? '';
        final String teacherName =
            "${teacherData['firstName'] ?? ''} ${teacherData['lastName'] ?? 'Unknown'}"
                .trim();

        // Update student's assignedTeacher field
        await FirebaseFirestore.instance
            .collection('students')
            .doc(studentId) // Use student's document ID
            .update({
          'assigned_teacher': {'name': teacherName, 'uid': teacherId}
        });
        await FirebaseFirestore.instance
            .collection('teachers')
            .doc(teacherId)
            .update({
          'students': FieldValue.arrayUnion([
            {'name': '$studentFirstName $studentLastName', 'uid': studentId}
          ])
        });
        await studentController.fetchStudentData(studentId);
        Get.to(() => TeacherSchedulePage(
              teacherId: teacherId,
              teacherName: teacherName,
            ));
      }
    } catch (e) {
      SnackbarWidget.showError("Error fetching/updating teacher: $e");
    } finally {
      isLoading(false);
    }
  }

  Future<void> assignTeacher(String teacherCode, String studentId,
      String studentFirstName, String studentLastName) async {
    try {
      isLoading(true);
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('teachers')
          .where('uniqueCode', isEqualTo: teacherCode)
          .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint("Code Invalid");
      } else {
        // Get teacher data safely
        var teacherData =
            querySnapshot.docs.first.data() as Map<String, dynamic>;

        final String teacherId = teacherData['uid'] ?? '';
        final String teacherName = teacherData['name'] ?? 'Unknown';

        // Update student's assignedTeacher field
        await FirebaseFirestore.instance
            .collection('students')
            .doc(studentId) // Use student's document ID
            .update({
          'assigned_teacher': {'name': teacherName, 'uid': teacherId}
        });
        await FirebaseFirestore.instance
            .collection('teachers')
            .doc(teacherId)
            .update({
          'students': FieldValue.arrayUnion([
            {'name': '$studentFirstName $studentLastName', 'uid': studentId}
          ])
        });
      }
    } catch (e) {
      SnackbarWidget.showError("Error fetching/updating teacher: $e");
    } finally {
      isLoading(false);
    }
  }

  Future<void> deleteTeacher(String teacherUid) async {
    try {
      isLoading(true);
      // First, delete all documents in the subcollection (e.g., 'teacher_subcollection')
      final subcollectionRef = FirebaseFirestore.instance
          .collection('teachers')
          .doc(teacherUid)
          .collection('schedules'); // Replace with your subcollection name

      // Get all documents in the subcollection
      final snapshot = await subcollectionRef.get();

      // Delete each document in the subcollection
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      // Then delete the teacher document itself
      await FirebaseFirestore.instance
          .collection('teachers')
          .doc(teacherUid)
          .delete();
      teachers.removeWhere((teacher) => teacher.uid == teacherUid);

      SnackbarWidget.showSuccess("Teacher deletion successful");
    } catch (e) {
      SnackbarWidget.showSuccess('Error deleting teacher: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> extendSubscription(String teacherId, DateTime newDate) async {
    try {
      isLoading(true);
      await FirebaseFirestore.instance
          .collection('teachers')
          .doc(teacherId)
          .update({'subscribed_until': Timestamp.fromDate(newDate)});

      SnackbarWidget.showSuccess(
          "Subscription extended to ${DateFormat.yMMMMd().format(newDate)}");
      fetchTeachers(); // Refresh UI
    } catch (e) {
      SnackbarWidget.showError("Failed to extend subscription: $e");
    } finally {
      isLoading(false);
    }
  }
}
