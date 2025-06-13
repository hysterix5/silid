import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:silid/core/resources/models/student.dart';
import 'package:silid/core/utility/widgets/snackbar.dart';

class StudentController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Rx<Student?> student = Rx<Student?>(null);

  // 🔹 Treat assignedTeacher as a list
  RxList<Map<String, dynamic>> assignedTeacher = <Map<String, dynamic>>[].obs;
  RxList<Student> students = <Student>[].obs;
  var studentClasses = [].obs;
  RxBool isLoading = false.obs;

  // 🔹 Submit full student data
  Future<void> submitStudentData(Student student) async {
    try {
      await _firestore
          .collection('students')
          .doc(student.uid)
          .set(student.toFirestore());
      this.student.value = student;
      assignedTeacher.assignAll(student.assignedTeacher);
    } catch (e) {
      rethrow;
    }
  }

  // 🔹 Fetch one student
  Future<Student?> fetchStudentData(String uid) async {
    try {
      DocumentSnapshot studentDoc =
          await _firestore.collection('students').doc(uid).get();
      if (studentDoc.exists) {
        Student student = Student.fromFirestore(studentDoc);
        this.student.value = student;
        assignedTeacher.assignAll(student.assignedTeacher);
        return student;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // 🔹 Fetch all students
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

  // 🔹 Add one teacher (preventing duplicates)
  Future<void> addAssignedTeacher(
      String studentUid, Map<String, dynamic> teacherData) async {
    try {
      await _firestore.collection('students').doc(studentUid).update({
        'assigned_teacher': FieldValue.arrayUnion([teacherData]),
      });

      // Update local list without duplicates
      if (!assignedTeacher.any((t) => t['uid'] == teacherData['uid'])) {
        assignedTeacher.add(teacherData);
      }

      // Optional: update student model locally
      if (student.value != null && student.value!.uid == studentUid) {
        final updatedList = [...student.value!.assignedTeacher, teacherData];
        student.value = student.value!.copyWith(assignedTeacher: updatedList);
      }
    } catch (e) {
      SnackbarWidget.showError("Failed to add assigned teacher: $e");
    }
  }

  // 🔹 Remove teacher
  Future<void> removeAssignedTeacher(
      String studentUid, Map<String, dynamic> teacherData) async {
    try {
      await _firestore.collection('students').doc(studentUid).update({
        'assigned_teacher': FieldValue.arrayRemove([teacherData]),
      });
      assignedTeacher.removeWhere((t) => t['uid'] == teacherData['uid']);
    } catch (e) {
      SnackbarWidget.showError("Failed to remove teacher: $e");
    }
  }

  // 🔹 Delete student (and subcollection)
  Future<void> deleteStudent(String studentUid) async {
    try {
      isLoading(true);
      final subcollectionRef = _firestore
          .collection('students')
          .doc(studentUid)
          .collection('notifications');

      final snapshot = await subcollectionRef.get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      await _firestore.collection('students').doc(studentUid).delete();
      students.removeWhere((student) => student.uid == studentUid);

      SnackbarWidget.showSuccess("Student deletion successful");
    } catch (e) {
      SnackbarWidget.showError('Error deleting Student: $e');
    } finally {
      isLoading(false);
    }
  }

  // 🔹 Fetch classes this student is enrolled in
  void fetchStudentClass(String studentUid) async {
    final snapshot = await _firestore.collection("classes").get();
    final filteredDocs = snapshot.docs.where((doc) {
      final studentsList = doc.data()['students'] as List<dynamic>?;
      if (studentsList == null) return false;
      return studentsList.any((student) => student['uid'] == studentUid);
    }).toList();

    studentClasses.value = filteredDocs.map((doc) => doc.data()).toList();
  }
}
