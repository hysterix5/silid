import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:silid/core/resources/controllers/data_controller.dart';
import 'package:silid/core/views/student/bookpage.dart';

class TeachersList extends StatelessWidget {
  final DataController dataController = Get.put(DataController());

  TeachersList({super.key}) {
    dataController.fetchTeachers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Teachers")),
      body: Obx(() {
        if (dataController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (dataController.teachers.isEmpty) {
          return const Center(child: Text("No teachers found"));
        }
        return ListView.builder(
          itemCount: dataController.teachers.length,
          itemBuilder: (context, index) {
            final teacher = dataController.teachers[index];
            return ListTile(
              title: Text(teacher.name),
              subtitle: Text(teacher.email),
              trailing: const Icon(Icons.schedule),
              onTap: () {
                // Navigate to TeacherSchedulePage and pass teacher.uid
                Get.to(() => TeacherSchedulePage(
                    teacherId: teacher.uid, teacherName: teacher.name));
              },
            );
          },
        );
      }),
    );
  }
}
