import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:silid/core/resources/controllers/auth_controller.dart';
import 'package:silid/core/resources/controllers/student_controller.dart';
import 'package:silid/core/resources/models/teacher.dart';
import 'package:silid/core/utility/widgets/snackbar.dart';

class TeacherController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Rx<Teacher?> teacher = Rx<Teacher?>(null);
  RxList<QueryDocumentSnapshot> students = <QueryDocumentSnapshot>[].obs;
  var teachers = <Teacher>[].obs;
  var teacherClasses = [].obs;
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

/* ────────────────────────────────────────────────────────────────
 *  Add a teacher to a student by code  ➜  supports MULTIPLE teachers
 * ──────────────────────────────────────────────────────────────── */
  Future<void> fetchTeacherByCode(
    String teacherCode,
    String studentId,
    String studentFirstName,
    String studentLastName,
  ) async {
    final StudentController studentController = Get.find<StudentController>();

    try {
      isLoading(true);

      // Find teacher by code
      final query = await _firestore
          .collection('teachers')
          .where('uniqueCode', isEqualTo: teacherCode)
          .get();

      if (query.docs.isEmpty) {
        SnackbarWidget.showError("Invalid code");
        return;
      }

      final data = query.docs.first.data();
      final String teacherId = data['uid'];
      final String teacherName =
          "${data['firstName']} ${data['lastName']}".trim();

      /* 👇 1.  PUSH the teacher map into the student's array (no duplicates) */
      await _firestore.collection('students').doc(studentId).update({
        'assigned_teacher': FieldValue.arrayUnion([
          {'name': teacherName, 'uid': teacherId, 'credits': 1}
        ]),
      });

      /* 👇 2.  Add the student under the teacher’s own sub‑collection */
      await _firestore
          .collection('teachers')
          .doc(teacherId)
          .collection('students')
          .doc(studentId)
          .set({
        'name': '$studentFirstName $studentLastName',
        'uid': studentId,
        'credits': 1,
      });

      /* 👇 3.  Refresh local student state */
      await studentController.fetchStudentData(studentId);

      // Get.to(
      //   () => TeacherSchedulePage(
      //     teacherId: teacherId,
      //     teacherName: teacherName,
      //     assignedTeacher: const {}, // kept for page argument
      //   ),
      // );
    } catch (e) {
      SnackbarWidget.showError("Error linking teacher: $e");
    } finally {
      isLoading(false);
    }
  }

/* ────────────────────────────────────────────────────────────────
 *  Simple helper used by Admin to assign a teacher (same logic)
 * ──────────────────────────────────────────────────────────────── */
  Future<void> assignTeacher(
    String teacherCode,
    String studentId,
    String studentFirstName,
    String studentLastName,
  ) async {
    try {
      isLoading(true);

      final query = await _firestore
          .collection('teachers')
          .where('uniqueCode', isEqualTo: teacherCode)
          .get();

      if (query.docs.isEmpty) {
        SnackbarWidget.showError("Invalid code");
        return;
      }

      final data = query.docs.first.data();
      final String teacherId = data['uid'];
      final String teacherName =
          "${data['firstName']} ${data['lastName']}".trim();

      await _firestore.collection('students').doc(studentId).update({
        'assigned_teacher': FieldValue.arrayUnion([
          {'name': teacherName, 'uid': teacherId, 'credits': 1}
        ]),
      });

      await _firestore
          .collection('teachers')
          .doc(teacherId)
          .collection('students')
          .doc(studentId)
          .set({
        'name': '$studentFirstName $studentLastName',
        'uid': studentId,
        'credits': 1,
      });
    } catch (e) {
      SnackbarWidget.showError("Error assigning teacher: $e");
    } finally {
      isLoading(false);
    }
  }

/* ────────────────────────────────────────────────────────────────
 *  Update credits for *this* teacher in the student's teacher list
 * ──────────────────────────────────────────────────────────────── */
  Future<void> updateStudentCredits(String studentId, int newCredits) async {
    try {
      isLoading(true);

      /* 1️⃣  Update credits in teacher → students sub‑collection */
      await _firestore
          .collection('teachers')
          .doc(teacher.value!.uid)
          .collection('students')
          .doc(studentId)
          .update({'credits': newCredits});

      /* 2️⃣  Pull the student's teacher list, update the matching entry */
      final studentRef = _firestore.collection('students').doc(studentId);
      final snap = await studentRef.get();

      if (snap.exists) {
        final List list = List.from(snap['assigned_teacher'] ?? []);

        for (final item in list) {
          if (item is Map && item['uid'] == teacher.value!.uid) {
            item['credits'] = newCredits;
            break;
          }
        }

        await studentRef.update({'assigned_teacher': list});
      }

      SnackbarWidget.showSuccess("Credits updated");
      await fetchStudents(); // refresh sidebar
    } catch (e) {
      SnackbarWidget.showError("Failed to update credits: $e");
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
      final studentSubcollectionRef = FirebaseFirestore.instance
          .collection('teachers')
          .doc(teacherUid)
          .collection('students'); // Replace with your subcollection name

      // Get all documents in the subcollection
      final studentSnapshot = await studentSubcollectionRef.get();

      // Delete each document in the subcollection
      for (var doc in studentSnapshot.docs) {
        await doc.reference.delete();
      }
      final notifSubcollectionRef = FirebaseFirestore.instance
          .collection('teachers')
          .doc(teacherUid)
          .collection('notifications'); // Replace with your subcollection name

      // Get all documents in the subcollection
      final notifSnapshot = await notifSubcollectionRef.get();

      // Delete each document in the subcollection
      for (var doc in notifSnapshot.docs) {
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

  Future<void> fetchStudents() async {
    if (teacher.value == null) return; // Ensure teacher data exists

    Future.microtask(() => isLoading(true)); // Deferring state update

    try {
      var snapshot = await _firestore
          .collection('teachers')
          .doc(teacher.value!.uid)
          .collection("students")
          .get();

      students
          .assignAll(snapshot.docs); // Assign safely to avoid rebuild issues
    } catch (e) {
      debugPrint("Error fetching students: $e");
    } finally {
      Future.microtask(() => isLoading(false)); // Deferring state update
    }
  }

  // Future<void> updateStudentCredits(String studentId, int newCredits) async {
  //   try {
  //     isLoading(true); // Show loading state

  //     // Update Firestore document
  //     await _firestore
  //         .collection('teachers')
  //         .doc(teacher.value!.uid)
  //         .collection("students")
  //         .doc(studentId)
  //         .update({'credits': newCredits});
  //     await _firestore.collection('students').doc(studentId).update({
  //       'assigned_teacher.credits': newCredits, // Update only the credits field
  //     });

  //     // Refresh the student list after update
  //     await fetchStudents();

  //     SnackbarWidget.showSuccess("Credits updated successfully");
  //   } catch (e) {
  //     SnackbarWidget.showError("Failed to update credits: $e");
  //   } finally {
  //     isLoading(false); // Hide loading state
  //   }
  // }

  void fetchTeacherClasses(String teacherName) async {
    final snapshot = await FirebaseFirestore.instance
        .collection("classes")
        .where("teacher", isEqualTo: teacherName)
        .get();

    teacherClasses.value = snapshot.docs.map((doc) => doc.data()).toList();
    // for (var doc in snapshot.docs) {
    //   debugPrint("Class Data: ${doc.data()}"); // Print raw document data
    // }
  }

  Future<void> deleteClass(String classId, String teacherName) async {
    try {
      isLoading(true);

      // Delete class document
      await _firestore.collection('classes').doc(classId).delete();

      // Refresh class list
      fetchTeacherClasses(teacherName);

      SnackbarWidget.showSuccess("Class deleted successfully");
    } catch (e) {
      SnackbarWidget.showError("Failed to delete class: $e");
    } finally {
      isLoading(false);
    }
  }

  Future<void> cancelClass(String classId) async {
    try {
      isLoading(true);
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .update({
        'status': 'Cancelled',
      });

      // Remove from local list if needed
      // teacherClasses.removeWhere((classData) => classData['class_id'] == classId);
      isLoading(false);
      SnackbarWidget.showSuccess("Class cancelled successfully");
    } catch (e) {
      SnackbarWidget.showError("Failed to cancel class: $e");
    }
  }
}
