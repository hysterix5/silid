import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:silid/core/resources/controllers/teacher_controller.dart';

class TeacherList extends StatelessWidget {
  final TeacherController teacherController = Get.put(TeacherController());

  TeacherList({super.key}) {
    teacherController.fetchTeachers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teachers')),
      body: SingleChildScrollView(
        child: Obx(() {
          if (teacherController.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (teacherController.teachers.isEmpty) {
            return const Center(child: Text("No students found"));
          }

          return ListView.builder(
            itemCount: teacherController.teachers.length,
            itemBuilder: (context, index) {
              final teacher = teacherController.teachers[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(teacher.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(teacher.email),
                  trailing: IconButton(
                    icon: const Icon(Icons.info),
                    onPressed: () {},
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
