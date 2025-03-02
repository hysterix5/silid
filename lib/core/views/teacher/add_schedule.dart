// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:silid/core/utility/widgets/snackbar.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class AddSchedulePage extends StatefulWidget {
  const AddSchedulePage({super.key});

  @override
  State<AddSchedulePage> createState() => _AddSchedulePageState();
}

class _AddSchedulePageState extends State<AddSchedulePage> {
  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();
  final Map<DateTime, List<Map<String, dynamic>>> markedDatesWithTimes = {};
  User? user = FirebaseAuth.instance.currentUser;
  final userId = FirebaseAuth.instance.currentUser?.uid;
  @override
  void initState() {
    super.initState();
    _fetchScheduledDates();
  }

  Future<void> _fetchScheduledDates() async {
    try {
      if (userId == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('teachers')
          .doc(userId)
          .collection('schedules')
          .get();

      final Map<DateTime, List<Map<String, dynamic>>> fetchedData = {};

      for (var doc in snapshot.docs) {
        final date = (doc['date'] as Timestamp).toDate();
        // Set the time to 8 AM
        final dateWithTime = DateTime(date.year, date.month, date.day, 8, 0);
        final timeslots = List<Map<String, dynamic>>.from(doc['timeslots']);
        fetchedData[DateTime(
                dateWithTime.year, dateWithTime.month, dateWithTime.day)] =
            timeslots;
      }

      setState(() {
        markedDatesWithTimes.addAll(fetchedData);
      });
    } catch (e) {
      //
    }
  }

  bool _isLoading = false;

  Future<void> openDateFunction(String? userId,
      Map<DateTime, List<Map<String, dynamic>>> markedDatesWithTimes) async {
    if (userId == null) return;

    final teachersRef =
        FirebaseFirestore.instance.collection('teachers').doc(userId);

    for (var entry in markedDatesWithTimes.entries) {
      DateTime date = entry.key;

      // Set the time to 8 AM
      DateTime dateWithTimeLocal =
          DateTime(date.year, date.month, date.day, 8, 0, 0, 0, 0);
      DateTime dateWithTimeUTC = dateWithTimeLocal.toUtc();
      final timestamp = Timestamp.fromDate(dateWithTimeUTC);

      final existingQuery = await teachersRef
          .collection('schedules')
          .where('date', isEqualTo: timestamp)
          .get();

      if (existingQuery.docs.isEmpty) {
        // No existing schedule, create a new one
        final newDocRef = await teachersRef.collection('schedules').add({
          "date": timestamp,
          "timeslots": entry.value,
        });

        // Assign the Firestore-generated UID
        await newDocRef.update({"uid": newDocRef.id});
      } else {
        // Schedule exists, update timeslots
        final docSnapshot = existingQuery.docs.first;
        List<Map<String, dynamic>> existingTimeslots =
            List<Map<String, dynamic>>.from(docSnapshot['timeslots']);

        // Determine timeslots to add and remove
        List<Map<String, dynamic>> timeslotsToAdd = [];
        List<Map<String, dynamic>> timeslotsToRemove = [];

        for (var timeslot in entry.value) {
          if (!existingTimeslots.any(
              (existingSlot) => existingSlot['time'] == timeslot['time'])) {
            timeslotsToAdd.add(timeslot); // New timeslot
          }
        }

        for (var timeslot in existingTimeslots) {
          if (!entry.value
              .any((newSlot) => newSlot['time'] == timeslot['time'])) {
            timeslotsToRemove.add(timeslot); // Removed timeslot
          }
        }

        // Update Firestore document with the new timeslots
        existingTimeslots.addAll(timeslotsToAdd);
        existingTimeslots
            .removeWhere((slot) => timeslotsToRemove.contains(slot));

        await teachersRef.collection('schedules').doc(docSnapshot.id).update({
          "date": timestamp,
          "timeslots": existingTimeslots,
        });
      }
    }
  }

  void _editTimeSlot(DateTime date) {
    List<Map<String, dynamic>> availableTimeSlots =
        _generate30MinuteIntervals();
    List<Map<String, dynamic>> selectedTimeSlots =
        markedDatesWithTimes[date] ?? [];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Time Slots'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableTimeSlots.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> timeSlot = availableTimeSlots[index];
                    return CheckboxListTile(
                      title: Text(timeSlot['time']),
                      value: selectedTimeSlots.any((selectedSlot) =>
                          selectedSlot['time'] == timeSlot['time']),
                      onChanged: (bool? isSelected) {
                        setDialogState(() {
                          if (isSelected == true) {
                            selectedTimeSlots.add(timeSlot);
                          } else {
                            selectedTimeSlots.removeWhere((selectedSlot) =>
                                selectedSlot['time'] == timeSlot['time']);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_isLoading) return;

                    setState(() {
                      _isLoading = true;
                    });

                    setState(() {
                      markedDatesWithTimes[date] = selectedTimeSlots;
                    });

                    setState(() {
                      _isLoading = false;
                    });

                    Navigator.pop(context);
                  },
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save'),
                )
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmationDialogForDate(
      BuildContext context, DateTime date) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content:
              Text('Are you sure you want to delete the schedule for $date?'),
          actions: [
            TextButton(
              onPressed: () {
                _deleteSchedule(date);

                Navigator.pop(context);
              },
              child: const Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('No'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteSchedule(DateTime date) async {
    if (userId == null) return;

    // Set the time to 8 AM
    DateTime dateWithTime = DateTime(date.year, date.month, date.day, 8, 0);
    Timestamp timestamp = Timestamp.fromDate(dateWithTime);

    try {
      // Query for the exact timestamp, including the time (e.g., 8 AM)
      final snapshot = await FirebaseFirestore.instance
          .collection('teachers')
          .doc(userId)
          .collection('schedules')
          .where('date', isEqualTo: timestamp)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete(); // Delete the schedule document
      }

      setState(() {
        markedDatesWithTimes.remove(date); // Remove from UI
      });

      SnackbarWidget.showSuccess("Schedule Deleted Successfully");

      // Check if there are any schedules remaining in the subcollection
      final remainingSchedules = await FirebaseFirestore.instance
          .collection('teachers')
          .doc(userId)
          .collection('schedules')
          .get();

      if (remainingSchedules.docs.isEmpty) {
        // If there are no schedules left, show a message or handle accordingly
      }
    } catch (e) {
      SnackbarWidget.showError("$e");
    }
  }

  List<Map<String, dynamic>> _generate30MinuteIntervals() {
    List<Map<String, dynamic>> intervals = [];
    for (int hour = 0; hour < 24; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        final time = TimeOfDay(hour: hour, minute: minute);
        intervals.add({
          'time': time.format(context),
          'status': 'open',
        });
      }
    }
    return intervals;
  }

  @override
  Widget build(BuildContext context) {
    String? userId = user?.uid;
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Save Schedule',
            icon: const Icon(Icons.save),
            onPressed: () async {
              if (markedDatesWithTimes.isNotEmpty) {
                showDialog(
                  context: context,
                  barrierDismissible:
                      false, // Prevent closing by tapping outside
                  builder: (BuildContext context) {
                    return const Center(
                      child:
                          CircularProgressIndicator(), // Display loading indicator
                    );
                  },
                );

                await openDateFunction(
                  userId,
                  markedDatesWithTimes,
                );

                Navigator.pop(context);

                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Success"),
                      content: const Text(
                          "Your available schedule has been saved successfully."),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              }
            },
          ),
        ],
        title: const Text("Open Schedule"),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                width: double
                    .infinity, // You can set a specific width if necessary
                padding: const EdgeInsets.all(
                    20.0), // Padding inside the container for spacing

                child: TableCalendar(
                  firstDay: DateTime.utc(2010, 10, 16),
                  lastDay: DateTime.utc(2030, 3, 14),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    _editTimeSlot(
                        selectedDay); // Open the time slot editing dialog
                  },
                  calendarStyle: const CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, date, focusedDay) {
                      if (markedDatesWithTimes.containsKey(
                          DateTime(date.year, date.month, date.day))) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${date.day}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                  enabledDayPredicate: (day) {
                    // Disable past dates (any date before today)
                    return day.isAfter(DateTime.now()) ||
                        isSameDay(day, DateTime.now());
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: markedDatesWithTimes.keys.length,
                itemBuilder: (context, index) {
                  final date = markedDatesWithTimes.keys.elementAt(index);
                  final timeRanges = markedDatesWithTimes[date] ?? [];
                  final DateFormat formatter = DateFormat('MMM d, yyyy');
                  String formattedDate = formatter.format(date);

                  // Get only the times from the timeRanges
                  List<String> times = timeRanges
                      .map((timeslot) =>
                          timeslot['time'] as String? ??
                          '') // Ensure 'time' is a String
                      .toList();

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Date: $formattedDate",
                              style: const TextStyle(fontSize: 14),
                            ),
                            // Show only the times (in a comma-separated string)
                            Text(
                              "Time slots: ${times.join(', ')}",
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                              ),
                              onPressed: () {
                                _editTimeSlot(date);
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                              ),
                              onPressed: () {
                                _showDeleteConfirmationDialogForDate(
                                    context, date);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
