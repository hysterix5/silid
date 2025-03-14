import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:silid/core/resources/controllers/teacher_controller.dart';
import 'package:silid/core/utility/widgets/dialogs.dart';

class TeacherStudentList extends StatelessWidget {
  final TeacherController teacherController = Get.find<TeacherController>();

  TeacherStudentList({super.key}) {
    teacherController.fetchStudents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      body: Obx(() {
        if (teacherController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (teacherController.students.isEmpty) {
          return const Center(child: Text("No students found"));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: teacherController.students.length,
          itemBuilder: (context, index) {
            final studentDoc = teacherController.students[index];
            final studentData = studentDoc.data() as Map<String, dynamic>?;

            return _buildStudentCard(studentData);
          },
        );
      }),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic>? student) {
    if (student == null) return const SizedBox();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        title: Text(
          student['name'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("ID: ${student['uid'] ?? 'N/A'}"),
            Text("Credits: ${student['credits'] ?? 'N/A'}"),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => ShowDialogUtil.showCreditUpdateDialog(
              student['uid'], student['credits']),
        ),
      ),
    );
  }
}
