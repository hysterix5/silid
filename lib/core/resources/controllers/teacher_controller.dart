import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:silid/core/resources/controllers/student_controller.dart';
import 'package:silid/core/resources/models/teacher.dart';
import 'package:silid/core/utility/widgets/snackbar.dart';
import 'package:silid/core/views/student/bookpage.dart';

class TeacherController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Rx<Teacher?> teacher = Rx<Teacher?>(null);
  var teachers = <Teacher>[].obs;
  var isLoading = true.obs;

  Future<void> submitTeacherData(Teacher teacher) async {
    try {
      await _firestore
          .collection('teachers')
          .doc(teacher.uid)
          .set(teacher.toFirestore());
      this.teacher.value = teacher; // Update local state
    } catch (e) {
      rethrow;
    }
  }

  Future<Teacher?> fetchTeacherData(String uid) async {
    try {
      DocumentSnapshot teacherDoc =
          await _firestore.collection('teachers').doc(uid).get();
      if (teacherDoc.exists) {
        Teacher teacher = Teacher.fromFirestore(teacherDoc);
        this.teacher.value = teacher; // Update local state
        return teacher;
      }
      return null;
    } catch (e) {
      rethrow;
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

  Future<void> fetchTeacherByCode(String teacherCode, String studentId) async {
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
        final String teacherName = teacherData['name'] ?? 'Unknown';

        // Update student's assignedTeacher field
        await FirebaseFirestore.instance
            .collection('students')
            .doc(studentId) // Use student's document ID
            .update({
          'assigned_teacher': {'name': teacherName, 'uid': teacherId}
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

  Future<void> assignTeacher(String teacherCode, String studentId) async {
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
      }
    } catch (e) {
      SnackbarWidget.showError("Error fetching/updating teacher: $e");
    } finally {
      isLoading(false);
    }
  }
}
