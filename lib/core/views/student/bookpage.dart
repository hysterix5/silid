import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:silid/core/resources/controllers/booking_controller.dart';
import 'package:silid/core/resources/controllers/daily_controller.dart';
import 'package:silid/core/resources/controllers/student_controller.dart';
import 'package:silid/core/utility/widgets/dialogs.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:silid/core/resources/controllers/data_controller.dart';

class TeacherSchedulePage extends StatefulWidget {
  final String teacherId;
  final String teacherName;

  const TeacherSchedulePage(
      {super.key, required this.teacherId, required this.teacherName});

  @override
  State<TeacherSchedulePage> createState() => _TeacherSchedulePageState();
}

class _TeacherSchedulePageState extends State<TeacherSchedulePage> {
  final DataController dataController = Get.find<DataController>();
  final BookingController bookingController = Get.find<BookingController>();
  final StudentController studentController = Get.find<StudentController>();
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      dataController.fetchSchedules(widget.teacherId);
    });
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    DateTime normalizedDay = DateTime(day.year, day.month, day.day);

    return dataController.schedules.where((schedule) {
      var rawDate = schedule['date'];

      // ✅ Ensure `date` is converted correctly
      DateTime scheduleDate;
      if (rawDate is Timestamp) {
        scheduleDate = rawDate.toDate();
      } else if (rawDate is DateTime) {
        scheduleDate = rawDate;
      } else {
        return false; // Skip invalid entries
      }

      scheduleDate =
          DateTime(scheduleDate.year, scheduleDate.month, scheduleDate.day);
      return scheduleDate == normalizedDay;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final student = studentController.student.value;

    return Scaffold(
      appBar: AppBar(title: const Text("Teacher Schedule")),
      body: Obx(() {
        if (dataController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (dataController.schedules.isEmpty) {
          return const Center(child: Text("No schedules found"));
        }

        final selectedSchedules = _getEventsForDay(selectedDay ?? focusedDay);

        return Column(
          children: [
            TableCalendar(
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              focusedDay: focusedDay,
              selectedDayPredicate: (day) => isSameDay(selectedDay, day),
              onDaySelected: (selected, focused) {
                setState(() {
                  selectedDay = selected;
                  focusedDay = focused;
                });
              },
              eventLoader: _getEventsForDay,
              calendarFormat: CalendarFormat.month,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: selectedSchedules.isEmpty
                  ? const Center(child: Text("No schedules for selected day"))
                  : ListView.builder(
                      itemCount: selectedSchedules.length,
                      itemBuilder: (context, scheduleIndex) {
                        final schedule = selectedSchedules[scheduleIndex];

                        return Card(
                          margin: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              ListTile(
                                title: Text(
                                  DateFormat('EEEE, MMM d, yyyy').format(
                                      (schedule['date'] is Timestamp)
                                          ? schedule['date'].toDate()
                                          : schedule['date']),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                trailing: const Icon(Icons.calendar_today),
                              ),
                              const Divider(),
                              Obx(() {
                                final scheduleIndex = dataController.schedules
                                    .indexWhere(
                                        (s) => s['uid'] == schedule['uid']);
                                if (scheduleIndex == -1) {
                                  return const SizedBox();
                                }

                                final timeslots =
                                    dataController.schedules[scheduleIndex]
                                        ['timeslots'] as List<dynamic>;

                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: timeslots.length,
                                  itemBuilder: (context, index) {
                                    final slot = timeslots[index];

                                    return ListTile(
                                      title: Text(slot['time']),
                                      subtitle:
                                          Text("Status: ${slot['status']}"),
                                      trailing: slot['status'] == 'open'
                                          ? ElevatedButton(
                                              onPressed: () {
                                                ShowDialogUtil
                                                    .showConfirmDialog(
                                                        title:
                                                            "Confirm Booking",
                                                        message:
                                                            "Are you sure you want to book this schedule?",
                                                        onConfirm: () async {
                                                          dataController
                                                              .isLoading
                                                              .value = true;

                                                          try {
                                                            // ✅ Convert Firestore Timestamp to DateTime
                                                            DateTime
                                                                scheduleDate =
                                                                (schedule['date']
                                                                        as Timestamp)
                                                                    .toDate();

                                                            // ✅ Parse time from timeslot (Handles "10:30 AM" format)
                                                            String timeString =
                                                                slot[
                                                                    'time']; // Example: "10:30 AM"

                                                            DateTime
                                                                parsedTime =
                                                                DateFormat(
                                                                        "h:mm a")
                                                                    .parse(
                                                                        timeString); // ✅ Converts "10:30 AM" properly

                                                            // ✅ Merge date and time
                                                            DateTime
                                                                mergedDateTime =
                                                                DateTime(
                                                              scheduleDate.year,
                                                              scheduleDate
                                                                  .month,
                                                              scheduleDate.day,
                                                              parsedTime.hour,
                                                              parsedTime.minute,
                                                            );

                                                            await dataController
                                                                .updateTimeslotStatus(
                                                              schedule['uid'],
                                                              widget.teacherId,
                                                              index,
                                                            );

                                                            final String?
                                                                roomUrl =
                                                                await Get.find<
                                                                        DailyController>()
                                                                    .createDailyRoom();

                                                            if (roomUrl !=
                                                                null) {
                                                              await bookingController
                                                                  .createBooking(
                                                                student:
                                                                    student!
                                                                        .name,
                                                                teacher: widget
                                                                    .teacherName,
                                                                date:
                                                                    mergedDateTime, // ✅ Correctly formatted DateTime
                                                                lesson:
                                                                    '', // Add lesson if needed
                                                                meetingLink:
                                                                    roomUrl, // ✅ Pass generated meeting link
                                                              );
                                                            } else {
                                                              Get.snackbar(
                                                                  "Error",
                                                                  "Failed to create a meeting link.");
                                                            }

                                                            dataController
                                                                .isLoading
                                                                .value = false;
                                                          } catch (e) {
                                                            dataController
                                                                .isLoading
                                                                .value = false;
                                                            Get.snackbar(
                                                                "Error",
                                                                "Failed to book: $e");
                                                          }
                                                        });
                                              },
                                              child: const Text("Book"),
                                            )
                                          : const Icon(Icons.lock,
                                              color: Colors.red),
                                    );
                                  },
                                );
                              })
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }
}
