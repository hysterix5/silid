import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:silid/core/resources/models/student.dart';

class StudentController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Rx<Student?> student = Rx<Student?>(null);

  Future<void> submitStudentData(Student student) async {
    try {
      await _firestore
          .collection('students')
          .doc(student.uid)
          .set(student.toFirestore());
      this.student.value = student; // Update local state
    } catch (e) {
      rethrow;
    }
  }

  Future<Student?> fetchStudentData(String uid) async {
    try {
      DocumentSnapshot studentDoc =
          await _firestore.collection('students').doc(uid).get();
      if (studentDoc.exists) {
        Student student = Student.fromFirestore(studentDoc);
        this.student.value = student; // Update local state
        return student;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}