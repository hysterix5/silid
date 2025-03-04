import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:silid/core/resources/controllers/teacher_controller.dart';
import 'package:silid/core/utility/widgets/dialogs.dart';

class TeacherList extends StatelessWidget {
  final TeacherController teacherController = Get.put(TeacherController());

  TeacherList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teachers')),
      body: Obx(() {
        if (teacherController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (teacherController.teachers.isEmpty) {
          return const Center(child: Text("No teachers found"));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: teacherController.teachers.length,
          itemBuilder: (context, index) {
            final teacher = teacherController.teachers[index];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                title: Text(
                  '${teacher.firstName} ${teacher.lastName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Email: ${teacher.email}"),
                    Text("Unique Code: ${teacher.uniqueCode}"),
                    Text(
                      "Subscribed Until: ${DateFormat.yMMMMd().format(teacher.subscribedUntil)}",
                      style: TextStyle(
                        color: teacher.subscribedUntil.isBefore(DateTime.now())
                            ? Colors.red
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    Wrap(
                      spacing: 10,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            ShowDialogUtil.showConfirmDialog(
                              title: "Confirm Deletion",
                              message: "Are you sure to delete this teacher?",
                              onConfirm: () {
                                teacherController.deleteTeacher(teacher.uid);
                              },
                            );
                          },
                          icon: const Icon(Icons.delete, color: Colors.white),
                          label: const Text("Delete"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            _extendSubscription(context, teacher.uid);
                          },
                          icon: const Icon(
                            Icons.calendar_month,
                            color: Colors.white,
                          ),
                          label: const Text("Extend Subscription"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.info),
                  onPressed: () {
                    // Navigate to teacher details page if needed
                  },
                ),
              ),
            );
          },
        );
      }),
    );
  }

  /// Opens a date picker for extending the subscription
  Future<void> _extendSubscription(
      BuildContext context, String teacherId) async {
    DateTime? newDate = await showDatePicker(
      context: context,
      initialDate:
          DateTime.now().add(const Duration(days: 30)), // Default +30 days
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (newDate != null) {
      teacherController.extendSubscription(teacherId, newDate);
    }
  }
}
