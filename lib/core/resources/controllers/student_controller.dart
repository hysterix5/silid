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

  var studentClasses = [].obs;
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

  Future<void> deleteStudent(String studentUid) async {
    try {
      isLoading(true);
      // First, delete all documents in the subcollection (e.g., 'teacher_subcollection')
      final subcollectionRef = FirebaseFirestore.instance
          .collection('students')
          .doc(studentUid)
          .collection('notifications'); // Replace with your subcollection name

      // Get all documents in the subcollection
      final snapshot = await subcollectionRef.get();

      // Delete each document in the subcollection
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      // Then delete the teacher document itself
      await FirebaseFirestore.instance
          .collection('students')
          .doc(studentUid)
          .delete();
      students.removeWhere((student) => student.uid == studentUid);

      SnackbarWidget.showSuccess("Student deletion successful");
    } catch (e) {
      SnackbarWidget.showSuccess('Error deleting Student: $e');
    } finally {
      isLoading(false);
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

  void fetchStudentClass(String studentUid) async {
    final snapshot = await FirebaseFirestore.instance
        .collection("classes")
        .get(); // Get all documents

    // Filter the documents where the student UID exists in the students list
    final filteredDocs = snapshot.docs.where((doc) {
      final data = doc.data();
      final studentsList =
          data['students'] as List<dynamic>?; // Get students array

      if (studentsList == null) return false; // If no students, skip

      // Check if any student in the list has a matching UID
      return studentsList.any((student) => student['uid'] == studentUid);
    }).toList();

    // Convert the filtered documents into a usable list
    studentClasses.value = filteredDocs.map((doc) => doc.data()).toList();
  }
}
