// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:silid/core/resources/controllers/daily_controller.dart';
import 'package:silid/core/resources/controllers/teacher_controller.dart';
import 'package:silid/core/utility/widgets/snackbar.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:get/get.dart';

class InitiateClass extends StatefulWidget {
  const InitiateClass({super.key});

  @override
  State<InitiateClass> createState() => _InitiateClassState();
}

class _InitiateClassState extends State<InitiateClass> {
  final TeacherController teacherController = Get.find<TeacherController>();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  List<Map<String, String>> _selectedStudents = [];

  // Fetch students from Firestore
  Future<List<Map<String, dynamic>>> _fetchStudents() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('teachers')
        .doc(teacherController.teacher.value?.uid)
        .collection('students')
        .get();
    return querySnapshot.docs
        .map((doc) => {'uid': doc.id, 'name': doc['name']}) // Adjust fields
        .toList();
  }

  // Show student selection dialog
  Future<void> _showStudentSelectionDialog() async {
    List<Map<String, dynamic>> students = await _fetchStudents();
    List<Map<String, String>> tempSelectedStudents =
        List.from(_selectedStudents);

    if (students.isEmpty) {
      SnackbarWidget.showError("No students found in the database.");

      return;
    }

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Select Students"),
              content: SingleChildScrollView(
                child: Column(
                  children: students.map((student) {
                    bool isSelected = tempSelectedStudents
                        .any((s) => s['uid'] == student['uid']);

                    return CheckboxListTile(
                      title: Text(student['name'] ?? 'Unknown'),
                      value: isSelected,
                      onChanged: (bool? selected) {
                        setDialogState(() {
                          if (selected == true) {
                            tempSelectedStudents.add({
                              'uid': student['uid'],
                              'name': student['name'],
                            });
                          } else {
                            tempSelectedStudents
                                .removeWhere((s) => s['uid'] == student['uid']);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedStudents = tempSelectedStudents;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("Confirm"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Function to pick time
  Future<void> _pickTime(BuildContext context) async {
    TimeOfDay? picked =
        await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  // Function to save class to Firestore
  Future<void> _saveClass() async {
    if (_selectedStudents.isEmpty) {
      SnackbarWidget.showError("Please select at least one student.");

      return;
    }

    DateTime finalDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final String? roomUrl = await Get.find<DailyController>().createDailyRoom();

    DocumentReference classRef =
        await FirebaseFirestore.instance.collection('classes').add({
      'teacher':
          '${teacherController.teacher.value?.firstName} ${teacherController.teacher.value?.lastName}',
      'dateTime': finalDateTime,
      'students': _selectedStudents, // Save selected students
      'meeting_link': roomUrl, // Add meeting link if needed
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'Ongoing'
    });

// Now update the document to include the document ID as 'class_id'
    await classRef.update({'class_id': classRef.id});
    SnackbarWidget.showSuccess("Class scheduled successfully!");

    setState(() {
      _selectedStudents = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Initiate Class"),
        actions: [
          IconButton(
            onPressed: () => _saveClass(),
            icon: Icon(Icons.save),
            tooltip: 'Save Class',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar
            TableCalendar(
              focusedDay: _selectedDate,
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDate = selectedDay;
                });
              },
            ),

            const SizedBox(height: 16),

            // Time Picker
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Selected Time: ${_selectedTime.format(context)}"),
                ElevatedButton(
                  onPressed: () => _pickTime(context),
                  child: const Text("Pick Time"),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Student Selection
            ElevatedButton(
              onPressed: _showStudentSelectionDialog,
              child: Text(
                _selectedStudents.isEmpty
                    ? "Select Students"
                    : "Selected: ${_selectedStudents.length}",
              ),
            ),

            const SizedBox(height: 16),

            // Submit Button
          ],
        ),
      ),
    );
  }
}
