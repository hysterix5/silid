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
  var bugReports = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    Get.put(StudentController());
    Get.put(TeacherController());
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
          "admin_permissions": true,
        });

        Get.offAllNamed('/admin');
        return;
      }
      if (user?.email == "assistant@admin.com") {
        await _firestore.collection('administrators').doc(user?.uid).set({
          "email": user?.email,
          "name": "Admin Assistant",
          "uid": user?.uid,
          "admin_permissions": false,
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

  Future<void> fetchGroupSchedules(String teacherId) async {
    isLoading.value = true;
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('teachers')
          .doc(teacherId)
          .collection('class_schedules')
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
      SnackbarWidget.showError("Failed to fetch class schedules: $e");
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

  Future<void> addAnnouncement(
      String creator, String subject, String message) async {
    try {
      await FirebaseFirestore.instance.collection('announcements').add({
        'creator': creator,
        'subject': subject,
        'message': message,
        'created_at': FieldValue.serverTimestamp(),
      });
      SnackbarWidget.showSuccess("Announcement added successfully!");
    } catch (e) {
      SnackbarWidget.showError("Error adding announcement: $e");
    }
  }

  Future<void> fetchBugReports() async {
    try {
      isLoading.value = true;

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('bug_reports')
          .orderBy('timestamp', descending: true)
          .get();

      bugReports.value = querySnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'description': data['description'] ?? '',
          'category': data['category'] ?? 'Unknown',
          'imageUrl': data['imageUrl'], // Nullable field
          'timestamp':
              (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();
    } catch (e) {
      SnackbarWidget.showError("Failed to fetch bug reports: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Stream<List<Map<String, dynamic>>> getMessages(String chatId) {
    return _firestore
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .orderBy("timestamp", descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> deductCredits(String teacherId, String studentId) async {
    final firestore = FirebaseFirestore.instance;

    try {
      // Get the current credits from the teacher's student collection
      final teacherStudentDoc = await firestore
          .collection('teachers')
          .doc(teacherId)
          .collection('students')
          .doc(studentId)
          .get();

      if (!teacherStudentDoc.exists) {
        SnackbarWidget.showError("Student not found in teacher's collection.");
        return;
      }

      int currentCredits = (teacherStudentDoc.data()?['credits'] ?? 0) as int;
      int newCredits = (currentCredits - 1).clamp(0, currentCredits);

      // Update the credits in the teacher's student subcollection
      await firestore
          .collection('teachers')
          .doc(teacherId)
          .collection('students')
          .doc(studentId)
          .update({'credits': newCredits});

      // Fetch current assigned_teacher list from student
      final studentDoc =
          await firestore.collection('students').doc(studentId).get();

      if (!studentDoc.exists) {
        SnackbarWidget.showError("Student not found.");
        return;
      }

      final data = studentDoc.data()!;
      final List assigned = data['assigned_teacher'];

      // Type safety: ensure we have a list of maps
      final List<Map<String, dynamic>> assignedTeachers =
          List<Map<String, dynamic>>.from(assigned);

      // Update the matching teacher's credits
      for (var teacher in assignedTeachers) {
        if (teacher['uid'] == teacherId) {
          teacher['credits'] = newCredits;
          break;
        }
      }

      // Save the updated list back
      await firestore
          .collection('students')
          .doc(studentId)
          .update({'assigned_teacher': assignedTeachers});
    } catch (e) {
      SnackbarWidget.showError("Error deducting credits: $e");
    }
  }
}
