// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:silid/core/resources/controllers/teacher_controller.dart';
import 'package:silid/core/utility/widgets/snackbar.dart';

class ShowDialogUtil {
  /// Shows an information dialog with a title and message.
  static void showInfoDialog(String title, String message) {
    Get.defaultDialog(
      title: title,
      middleText: message,
      textConfirm: "OK",
      confirmTextColor: Colors.white,
      onConfirm: () => Get.back(),
    );
  }

  /// Shows a confirmation dialog with customizable actions.
  static void showConfirmDialog({
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String confirmText = "Yes",
    String cancelText = "No",
  }) {
    Get.defaultDialog(
      title: title,
      middleText: message,
      textConfirm: confirmText,
      textCancel: cancelText,
      confirmTextColor: Colors.white,
      onConfirm: () {
        onConfirm();
        Get.back(); // Close dialog after confirming
      },
      onCancel: () => Get.back(),
    );
  }

  /// Shows a loading dialog
  static void showLoadingDialog({String message = "Loading..."}) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
      barrierDismissible: false, // Prevent dismissing by tapping outside
    );
  }

  /// Hides any currently open dialog
  static void hideDialog() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  /// Shows a dialog with cards
  static void showCardsDialog({
    required BuildContext context, // Add context parameter
    required String title,
    required List<Widget> cards,
  }) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Column(
                children: cards.map((card) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: card,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true, // Allow dismissing by tapping outside
    );
  }

  static Future<Map<String, dynamic>?> showTimeslotDialog(BuildContext context,
      DateTime selectedDay, List<Map<String, String>> existingTimeslots) {
    final selectedTimeslots = List<Map<String, String>>.from(existingTimeslots);

    return Get.dialog<Map<String, dynamic>>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Timeslots',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Selected Date: ${DateFormat('yyyy-MM-dd').format(selectedDay)}',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.maxFinite,
                height: 400,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return ListView.builder(
                      itemCount: 48, // 24 hours * 2 (30-minute intervals)
                      itemBuilder: (context, index) {
                        final time = DateTime(0, 0, 0, 0, 0)
                            .add(Duration(minutes: 30 * index));
                        final formattedTime =
                            DateFormat('hh:mm a').format(time);
                        final isSelected = selectedTimeslots
                            .any((element) => element['time'] == formattedTime);

                        return CheckboxListTile(
                          title: Text(formattedTime),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedTimeslots.add(
                                    {'time': formattedTime, 'status': 'open'});
                              } else {
                                selectedTimeslots.removeWhere((element) =>
                                    element['time'] == formattedTime);
                              }
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, {'status': 'cancel', 'time': []});
                    },
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context,
                          {'status': 'confirm', 'time': selectedTimeslots});
                    },
                    child: const Text('Confirm'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true, // Allow dismissing by tapping outside
    );
  }

  static void showCancellationDialog({
    required String title,
    required String message,
    required Function(String) onConfirm,
  }) {
    TextEditingController reasonController = TextEditingController();

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Enter reason for cancellation",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text("Close"),
                  ),
                  TextButton(
                    onPressed: () {
                      onConfirm(reasonController.text);
                      Get.back();
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text("Cancel Booking"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true, // Allow dismissing by tapping outside
    );
  }

  static void showTeacherCodeDialog({
    required String title,
    required Function(String) onConfirm,
  }) {
    TextEditingController codeController = TextEditingController();

    Get.defaultDialog(
      title: title,
      content: Column(
        children: [
          TextField(
            controller: codeController,
            decoration: InputDecoration(
              labelText: "Enter Teacher Code",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      textConfirm: "Submit",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      onConfirm: () {
        String code = codeController.text.trim();
        if (code.isNotEmpty) {
          onConfirm(code); // Pass entered code to function
          Get.back(); // Close the dialog
        } else {
          SnackbarWidget.showError("Please enter a valid code");
        }
      },
      onCancel: () => Get.back(),
    );
  }

  static void showAddLessonDialog({
    required Function() onSuccess, // Callback for UI update
  }) {
    TextEditingController titleController = TextEditingController();
    TextEditingController linkController = TextEditingController();

    Get.defaultDialog(
      title: "Add New Lesson",
      content: Column(
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: "Lesson Title",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: linkController,
            decoration: const InputDecoration(
              labelText: "Lesson Link",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
          ),
        ],
      ),
      textConfirm: "Add",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      onConfirm: () async {
        String title = titleController.text.trim();
        String link = linkController.text.trim();

        if (title.isEmpty || link.isEmpty) {
          SnackbarWidget.showError("Please enter both title and link.");
          return;
        }

        try {
          await FirebaseFirestore.instance.collection('lessons').add({
            "title": title,
            "link": link,
            "createdAt": FieldValue.serverTimestamp(),
          });

          onSuccess(); // Trigger UI update
          Get.back(); // Close the dialog
          SnackbarWidget.showSuccess("Lesson added to library!");
        } catch (e) {
          SnackbarWidget.showError("Error adding lesson: ${e.toString()}");
        }
      },
      onCancel: () => Get.back(),
    );
  }

  static void showAddAnnouncementDialog({required VoidCallback onSuccess}) {
    TextEditingController creatorController = TextEditingController();
    TextEditingController subjectController = TextEditingController();
    TextEditingController messageController = TextEditingController();

    String selectedReceiver = "All"; // Default selection

    Get.defaultDialog(
      title: "Add Announcement",
      content: Column(
        children: [
          TextField(
            controller: creatorController,
            decoration: const InputDecoration(labelText: "Creator"),
          ),
          TextField(
            controller: subjectController,
            decoration: const InputDecoration(labelText: "Subject"),
          ),
          TextField(
            controller: messageController,
            decoration: const InputDecoration(labelText: "Message"),
            maxLines: 3,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: selectedReceiver,
            items: ["Students", "Teachers", "All"].map((String category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) selectedReceiver = value;
            },
            decoration: const InputDecoration(labelText: "Receiver"),
          ),
        ],
      ),
      textConfirm: "Add",
      confirmTextColor: Colors.white,
      textCancel: "Cancel",
      onConfirm: () async {
        String creator = creatorController.text;
        String subject = subjectController.text;
        String message = messageController.text;
        final announcementRef =
            FirebaseFirestore.instance.collection('announcements');

        if (creator.isNotEmpty && subject.isNotEmpty && message.isNotEmpty) {
          try {
            // Add to the global "announcements" collection
            await announcementRef.add({
              'creator': creator,
              'subject': subject,
              'message': message,
              'created_at': FieldValue.serverTimestamp(),
              'recipient': selectedReceiver
            });

            // Handle "All" recipient
            if (selectedReceiver == 'All') {
              // Send announcement to all teachers
              QuerySnapshot teachersSnapshot =
                  await FirebaseFirestore.instance.collection('teachers').get();
              for (var teacherDoc in teachersSnapshot.docs) {
                await teacherDoc.reference.collection('notifications').add({
                  'creator': creator,
                  'subject': subject,
                  'message': message,
                  'created_at': FieldValue.serverTimestamp(),
                  'status': 'unread'
                });
              }

              // Send announcement to all students
              QuerySnapshot studentsSnapshot =
                  await FirebaseFirestore.instance.collection('students').get();
              for (var studentDoc in studentsSnapshot.docs) {
                await studentDoc.reference.collection('notifications').add({
                  'creator': creator,
                  'subject': subject,
                  'message': message,
                  'created_at': FieldValue.serverTimestamp(),
                  'status': 'unread'
                });
              }
            }
            // Handle "Teachers" recipient
            else if (selectedReceiver == 'Teachers') {
              QuerySnapshot teachersSnapshot =
                  await FirebaseFirestore.instance.collection('teachers').get();
              for (var teacherDoc in teachersSnapshot.docs) {
                await teacherDoc.reference.collection('notifications').add({
                  'creator': creator,
                  'subject': subject,
                  'message': message,
                  'created_at': FieldValue.serverTimestamp(),
                  'status': 'unread'
                });
              }
            }
            // Handle "Students" recipient
            else if (selectedReceiver == 'Students') {
              QuerySnapshot studentsSnapshot =
                  await FirebaseFirestore.instance.collection('students').get();
              for (var studentDoc in studentsSnapshot.docs) {
                await studentDoc.reference.collection('notifications').add({
                  'creator': creator,
                  'subject': subject,
                  'message': message,
                  'created_at': FieldValue.serverTimestamp(),
                  'status': 'unread'
                });
              }
            }

            // Show success message
            SnackbarWidget.showSuccess('Announcement created successfully');
          } catch (e) {
            // Handle error during Firestore operation
            SnackbarWidget.showError('Error: $e');
          }
        } else {
          // Show a message if any of the fields are empty
          SnackbarWidget.showError('Please fill in all fields');
        }
        Get.back(); // Close dialog
        onSuccess(); // Refresh UI
      },
    );
  }

  static void showStudentsDialog(BuildContext context, String teacherId) async {
    try {
      QuerySnapshot studentsSnapshot = await FirebaseFirestore.instance
          .collection('teachers')
          .doc(teacherId)
          .collection("students")
          .get(); // Fetch all student documents

      if (studentsSnapshot.docs.isEmpty) {
        SnackbarWidget.showError("No students assigned yet.");
        return;
      }

      List<Map<String, dynamic>> students = studentsSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Your Students"),
            content: students.isEmpty
                ? const Text("No students assigned yet.")
                : SizedBox(
                    width: double.maxFinite,
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.6,
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: students.length,
                          itemBuilder: (context, index) {
                            var student = students[index];
                            return ListTile(
                              leading: const Icon(Icons.person),
                              title: Text(student['name'] ?? 'Unknown'),
                              subtitle: Text("ID: ${student['uid']}"),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          );
        },
      );
    } catch (e) {
      SnackbarWidget.showError("Failed to load students: $e");
    }
  }

  static void showCreditUpdateDialog(String studentId, int currentCredits) {
    final TeacherController teacherController = Get.put(TeacherController());

    TextEditingController creditController =
        TextEditingController(text: currentCredits.toString());

    Get.defaultDialog(
      title: "Update Credits",
      content: TextField(
        controller: creditController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: "Enter new credits"),
      ),
      confirm: ElevatedButton(
        onPressed: () {
          int newCredits =
              int.tryParse(creditController.text) ?? currentCredits;
          teacherController.updateStudentCredits(studentId, newCredits);
          Get.back(); // Close dialog
        },
        child: const Text("Update"),
      ),
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text("Cancel"),
      ),
    );
  }
}
