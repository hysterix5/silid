import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:silid/core/resources/controllers/student_controller.dart';

class StudentList extends StatelessWidget {
  final StudentController studentController = Get.put(StudentController());

  StudentList({super.key}) {
    studentController.fetchStudents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      body: Obx(() {
        if (studentController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (studentController.students.isEmpty) {
          return const Center(child: Text("No students found"));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 10), // Add padding
          itemCount: studentController.students.length,
          itemBuilder: (context, index) {
            final student = studentController.students[index];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text('${student.firstName} ${student.lastName}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(student.email),
                trailing: IconButton(
                  icon: const Icon(Icons.info),
                  onPressed: () {
                    // Navigate or show student details
                  },
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
