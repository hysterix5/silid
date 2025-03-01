import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:silid/core/resources/models/teacher.dart';

class TeacherController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Rx<Teacher?> teacher = Rx<Teacher?>(null);

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
}
