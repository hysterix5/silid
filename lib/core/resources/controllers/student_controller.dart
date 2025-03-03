import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:silid/core/resources/models/student.dart';
import 'package:silid/core/utility/widgets/snackbar.dart';

class StudentController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Rx<Student?> student = Rx<Student?>(null);
  RxMap<String, dynamic> assignedTeacher =
      <String, dynamic>{}.obs; // 🔹 Make assignedTeacher observable
  RxList<Student> students = <Student>[].obs;
  RxBool isLoading = false.obs;

  Future<void> submitStudentData(Student student) async {
    try {
      await _firestore
          .collection('students')
          .doc(student.uid)
          .set(student.toFirestore());
      this.student.value = student; // Update local state
      assignedTeacher.value =
          student.assignedTeacher; // 🔹 Update assignedTeacher
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
        assignedTeacher.value =
            student.assignedTeacher; // 🔹 Update assignedTeacher
        return student;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> fetchStudents() async {
    try {
      isLoading.value = true;
      QuerySnapshot querySnapshot =
          await _firestore.collection('students').get();
      students.value =
          querySnapshot.docs.map((doc) => Student.fromFirestore(doc)).toList();
    } catch (e) {
      SnackbarWidget.showError("Failed to load students $e");
    } finally {
      isLoading.value = false;
    }
  }

  // 🔹 Update Assigned Teacher
  void updateAssignedTeacher(Map<String, dynamic> teacherData) async {
    if (student.value != null) {
      await _firestore.collection('students').doc(student.value!.uid).update({
        'assigned_teacher': teacherData,
      });
      assignedTeacher.value =
          teacherData; // 🔹 Update observable assignedTeacher
    }
  }
}
