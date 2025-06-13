import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:silid/core/resources/controllers/student_controller.dart';
import 'package:silid/core/resources/controllers/teacher_controller.dart';
import 'package:silid/core/utility/widgets/dialogs.dart';
import 'package:silid/core/utility/widgets/snackbar.dart';
import 'package:silid/core/views/student/bookpage.dart';

class SubscribedTeacherList extends StatelessWidget {
  final String studentId;

  // Controllers
  final StudentController _studentCtrl = Get.find<StudentController>();
  final TeacherController _teacherCtrl = Get.find<TeacherController>();

  // Loading flag
  final RxBool _isProcessing = false.obs;

  SubscribedTeacherList({super.key, required this.studentId});

  /* ─────────────  add teacher  ───────────── */
  void _addTeacher() {
    ShowDialogUtil.showTeacherCodeDialog(
      title: "Enter Teacher Code",
      onConfirm: (code) async {
        final student = _studentCtrl.student.value;
        if (student == null) {
          SnackbarWidget.showError("Student data not loaded.");
          return;
        }

        _isProcessing(true);
        await _teacherCtrl.fetchTeacherByCode(
          code,
          student.uid,
          student.firstName,
          student.lastName,
        );
        _isProcessing(false);

        SnackbarWidget.showSuccess("Teacher added!");
      },
    );
  }

  /* ─────────────  delete teacher  ───────────── */
  Future<void> _removeTeacher(
    Map<String, dynamic> teacherData,
  ) async {
    final String teacherUid = teacherData['uid'];
    try {
      _isProcessing(true);

      // 1️⃣  Remove from student array
      await FirebaseFirestore.instance
          .collection('students')
          .doc(studentId)
          .update({
        'assigned_teacher': FieldValue.arrayRemove([teacherData]),
      });

      // 2️⃣  Remove reciprocal link under teacher
      await FirebaseFirestore.instance
          .collection('teachers')
          .doc(teacherUid)
          .collection('students')
          .doc(studentId)
          .delete();

      SnackbarWidget.showSuccess("Teacher removed");
    } catch (e) {
      SnackbarWidget.showError("Failed to remove teacher: $e");
    } finally {
      _isProcessing(false);
    }
  }

  /* ─────────────────────────────── UI ─────────────────────────────── */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscribed Teachers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Teacher',
            onPressed: _addTeacher,
          ),
        ],
      ),
      body: Obx(
        () => Stack(
          children: [
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('students')
                  .doc(studentId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('Student not found.'));
                }

                final data = snapshot.data!.data()!;
                final List assignedTeachers = data['assigned_teacher'] ?? [];

                if (assignedTeachers.isEmpty) {
                  return const Center(child: Text('No assigned teachers.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: assignedTeachers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final teacher =
                        Map<String, dynamic>.from(assignedTeachers[index]);

                    return InkWell(
                        onTap: () {
                          Get.to(() => TeacherSchedulePage(
                                teacherData: teacher,
                              ));
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          tileColor: Colors.blue.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          leading: const Icon(Icons.person, color: Colors.blue),
                          title: Text(teacher['name'] ?? 'Unknown'),
                          subtitle: Text('Credits: ${teacher['credits'] ?? 0}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Remove',
                            onPressed: () => ShowDialogUtil.showConfirmDialog(
                              title: "Remove Teacher",
                              message:
                                  "Are you sure you want to remove this teacher?",
                              onConfirm: () => _removeTeacher(teacher),
                            ),
                          ),
                        ));
                  },
                );
              },
            ),
            if (_isProcessing.value)
              Container(
                color: Colors.black45,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
