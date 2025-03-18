// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:silid/core/resources/controllers/booking_controller.dart';
import 'package:silid/core/resources/controllers/daily_controller.dart';
import 'package:silid/core/resources/controllers/event_controller.dart';
import 'package:silid/core/resources/controllers/payment_controller.dart';
import 'package:silid/core/resources/controllers/teacher_controller.dart';
import 'package:silid/core/resources/models/teacher.dart';
import 'package:silid/core/resources/service/daily.dart';
import 'package:silid/core/utility/widgets/dialogs.dart';
import 'package:silid/core/utility/widgets/message_icon_teachers.dart';
import 'package:silid/core/utility/widgets/navbar.dart';
import 'package:silid/core/utility/widgets/notification_teacher.dart';
import 'package:silid/core/utility/widgets/snackbar.dart';
import 'package:silid/core/views/teacher/students_list.dart';
import 'package:table_calendar/table_calendar.dart';

class TeacherIndex extends StatefulWidget {
  const TeacherIndex({super.key});

  @override
  State<TeacherIndex> createState() => _TeacherIndexState();
}

class _TeacherIndexState extends State<TeacherIndex> {
  final TeacherController teacherController = Get.find<TeacherController>();
  final BookingController bookingController = Get.find<BookingController>();
  final EventController eventController = Get.find<EventController>();

  final DailyController dailyController = Get.find<DailyController>();
  final paymentController = Get.find<PaymentController>();

  CalendarFormat calendarFormat = CalendarFormat.month;
  DateTime? selectedDay;
  DateTime focusedDay = DateTime.now();
  User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    final teacher = teacherController.teacher.value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (user != null) {
        bookingController.fetchBookings(
          teacherName:
              "${teacher?.firstName ?? ''} ${teacher?.lastName ?? ''}".trim(),
        );
        teacherController.fetchTeacherClasses(
          "${teacher?.firstName ?? ''} ${teacher?.lastName ?? ''}".trim(),
        );
      }
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Cancelled":
        return Colors.red;
      case "Booked":
        return Colors.green;
      case "Finished":
        return Colors.blue;
      default:
        return Colors.black; // Default color
    }
  }

  void initiatePayment(Teacher? teacher) {
    paymentController.setTeacher(teacher); // Set teacher data first
    // Then start payment
  }

  void _showDeleteConfirmation(String classId, String teacherName) {
    Get.defaultDialog(
      title: "Delete Class",
      middleText: "Are you sure you want to delete this class?",
      textConfirm: "Yes, Delete",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      onConfirm: () {
        teacherController.deleteClass(classId, teacherName);
        Get.back(); // Close the dialog
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (teacherController.teacher.value == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        actions: [
          IconButton(
            onPressed: () {
              initiatePayment(teacherController.teacher.value);
            },
            icon: const Icon(Icons.add_circle),
            tooltip: "Extend Subscription",
          ),
          TeacherNotifIcon(),
          MessageIconTeacher()
        ],
      ),
      drawer: Navbar(
        name:
            "${teacherController.teacher.value?.firstName ?? ''} ${teacherController.teacher.value?.lastName ?? ''}"
                .trim(),
        email: teacherController.teacher.value?.email,
        profileImageUrl: teacherController.teacher.value?.profileImage,
        subscribedUntil: teacherController.teacher.value?.subscribedUntil,
      ),
      body: Obx(() {
        if (teacherController.isLoading.value) {
          return const Center(
              child:
                  CircularProgressIndicator()); // Show loading while fetching teacher data
        }

        final teacher = teacherController.teacher.value;

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Today is",
                              style: TextStyle(fontSize: 18),
                            ),
                            Text(
                              DateFormat('EEEE, MMMM dd, yyyy')
                                  .format(DateTime.now()),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Text(
                                  "Referral Code: ${teacher?.uniqueCode}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(
                                        text: teacher!.uniqueCode));
                                    SnackbarWidget.showSuccess(
                                        "Referral Code Copied");
                                  },
                                  icon: const Icon(Icons.copy,
                                      color: Colors.blue),
                                  tooltip: "Copy Referral Code",
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 5.0,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    if (teacher!.subscribedUntil
                                        .isBefore(DateTime.now())) {
                                      SnackbarWidget.showError(
                                          "Cannot perform this action. Your subscription has expired.");
                                      return;
                                    } else {
                                      ShowDialogUtil.showClassTypeDialog(
                                          Get.context!);
                                      // Get.to(() => AddSchedulePage());
                                    }
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.edit_calendar_outlined,
                                          size: 24),
                                      const SizedBox(width: 8),
                                      const Text("Open Schedule"),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Get.to(() => TeacherStudentList());
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.groups, size: 24),
                                      const SizedBox(width: 8),
                                      const Text("Your Students"),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 15.0,
                            ),
                            Text("You have an upcoming Group Class:"),
                            Obx(() {
                              if (teacherController.teacherClasses.isEmpty) {
                                return const Text("No classes yet");
                              }

                              return Column(
                                children: teacherController.teacherClasses
                                    .map((classData) {
                                  return Card(
                                    elevation: 4,
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text.rich(
                                            TextSpan(
                                              text:
                                                  "Date & Time: ", // Regular text
                                              children: [
                                                TextSpan(
                                                  text: classData['dateTime'] !=
                                                          null
                                                      ? DateFormat(
                                                              'EEEE, MMM d, yyyy • hh:mm a')
                                                          .format((classData[
                                                                      'dateTime']
                                                                  as Timestamp)
                                                              .toDate())
                                                      : 'N/A',
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight
                                                          .bold), // Bold date
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                              "Students: ${classData['students']?.length ?? 0} enrolled"),
                                          Text(
                                              "Status: ${classData['status']}"),
                                          SizedBox(
                                            height: 5.0,
                                          ),
                                          if (classData['status'] !=
                                              "Cancelled")
                                            Wrap(
                                              spacing: 5.0,
                                              children: [
                                                ElevatedButton(
                                                  onPressed: () => Get.to(
                                                    () => MeetingScreen(
                                                      roomUrl: classData[
                                                          'meeting_link'],
                                                      userName:
                                                          classData['teacher'],
                                                    ),
                                                  ),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.green,
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 16.0,
                                                        vertical: 8.0),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8.0),
                                                    ),
                                                  ),
                                                  child:
                                                      const Text("Enter Class"),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    _showDeleteConfirmation(
                                                        classData['class_id'],
                                                        classData['teacher']);
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.blue,
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 16.0,
                                                        vertical: 8.0),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8.0),
                                                    ),
                                                  ),
                                                  child:
                                                      const Text("End Class"),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    ShowDialogUtil.showConfirmDialog(
                                                        title:
                                                            "Confirm Class Cancellation",
                                                        message:
                                                            "Are you sure to cancel this class?",
                                                        onConfirm: () =>
                                                            teacherController
                                                                .cancelClass(
                                                                    classData[
                                                                        'class_id']));
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 16.0,
                                                        vertical: 8.0),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8.0),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                      "Cancel Class"),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            })
                          ],
                        ),
                      ),
                      GetBuilder<BookingController>(
                        builder: (controller) {
                          return TableCalendar(
                            firstDay: DateTime.utc(2010, 10, 16),
                            lastDay: DateTime.utc(2030, 3, 14),
                            focusedDay: focusedDay,
                            selectedDayPredicate: (day) =>
                                isSameDay(selectedDay, day),
                            onDaySelected: (newSelectedDay, newFocusedDay) {
                              setState(() {
                                selectedDay = newSelectedDay;
                                focusedDay = newFocusedDay;
                              });
                            },
                            calendarFormat: calendarFormat,
                            onFormatChanged: (format) {
                              setState(() {
                                calendarFormat = format;
                              });
                            },
                            eventLoader: (day) {
                              return controller.bookings.where((booking) {
                                return DateFormat('yyyy-MM-dd')
                                        .format(booking.date) ==
                                    DateFormat('yyyy-MM-dd').format(day);
                              }).toList();
                            },
                            calendarStyle: CalendarStyle(
                              todayDecoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              todayTextStyle: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimary, // Ensures contrast
                              ),
                              markerDecoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              defaultTextStyle: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface, // Default text color
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Obx(() {
                  if (bookingController.isLoading.value) {
                    return const Center(
                        child:
                            CircularProgressIndicator()); // Show loading while fetching bookings
                  }

                  if (bookingController.bookings.isEmpty) {
                    return const Center(child: Text("No bookings found"));
                  }

                  final selectedDate = selectedDay ?? focusedDay;
                  final filteredBookings =
                      bookingController.bookings.where((booking) {
                    return DateFormat('yyyy-MM-dd').format(booking.date) ==
                        DateFormat('yyyy-MM-dd').format(selectedDate);
                  }).toList();

                  if (filteredBookings.isEmpty) {
                    return const Center(
                        child: Text("No bookings for selected day"));
                  }

                  return SizedBox(
                    height: 400,
                    child: ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: filteredBookings.length,
                      itemBuilder: (context, index) {
                        final booking = filteredBookings[index];
                        return Card(
                          child: ListTile(
                            title: Text(
                              DateFormat('hh:mm a').format(booking.date),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Student: ${booking.student}"),
                                Text(
                                  "Status: ${booking.status['message']}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getStatusColor(
                                        booking.status['message']),
                                  ),
                                ),
                                if (booking.status['message'] != "Cancelled" &&
                                    booking.status['message'] != "Finished")
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10.0),
                                    child: Wrap(
                                      alignment: WrapAlignment.start,
                                      spacing: 5.0,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () {
                                            ShowDialogUtil
                                                .showCancellationDialog(
                                              title: "Cancel Booking",
                                              message:
                                                  "Please provide a reason for cancellation.",
                                              onConfirm: (remarks) async {
                                                await dailyController
                                                    .deleteDailyRoom(
                                                        booking.meetingLink);
                                                bookingController.cancelBooking(
                                                    remarks, booking.uid);
                                                // eventController.bookCancelledbyTeacher(teacherId, studentName)
                                              },
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16.0,
                                                vertical: 8.0),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                          ),
                                          child: const Text("Cancel"),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            ShowDialogUtil.showConfirmDialog(
                                              title: "End Booking",
                                              message:
                                                  "Are you sure to end this booking?",
                                              onConfirm: () {
                                                dailyController.deleteDailyRoom(
                                                    booking.meetingLink);
                                                bookingController
                                                    .finishBooking(booking.uid);
                                              },
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16.0,
                                                vertical: 8.0),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                          ),
                                          child: const Text("Mark as Finished"),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Get.to(
                                            () => MeetingScreen(
                                              roomUrl: booking.meetingLink,
                                              userName: booking.teacher,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16.0,
                                                vertical: 8.0),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                          ),
                                          child: const Text("Go to Room"),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            trailing: const Icon(Icons.calendar_today),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      }),
    );
  }
}
