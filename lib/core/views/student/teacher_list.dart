// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:silid/core/resources/controllers/teacher_controller.dart';
// import 'package:silid/core/views/student/bookpage.dart';

// class TeachersList extends StatelessWidget {
//   final TeacherController teacherController = Get.put(TeacherController());

//   TeachersList({super.key}) {
//     teacherController.fetchTeachers();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Teachers")),
//       body: Obx(() {
//         if (teacherController.isLoading.value) {
//           return const Center(child: CircularProgressIndicator());
//         }
//         if (teacherController.teachers.isEmpty) {
//           return const Center(child: Text("No teachers found"));
//         }
//         return ListView.builder(
//           itemCount: teacherController.teachers.length,
//           itemBuilder: (context, index) {
//             final teacher = teacherController.teachers[index];
//             return ListTile(
//               title: Text(teacher.name),
//               subtitle: Text(teacher.email),
//               trailing: const Icon(Icons.schedule),
//               onTap: () {
//                 // Navigate to TeacherSchedulePage and pass teacher.uid
//                 Get.to(() => TeacherSchedulePage(
//                     teacherId: teacher.uid, teacherName: teacher.name));
//               },
//             );
//           },
//         );
//       }),
//     );
//   }
// }
