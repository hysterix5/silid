import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:silid/core/resources/models/teacher.dart';
import 'package:silid/core/utility/widgets/snackbar.dart';

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
}
