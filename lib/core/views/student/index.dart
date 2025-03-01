// ignore_for_file: deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:silid/core/resources/controllers/booking_controller.dart';
import 'package:silid/core/resources/controllers/student_controller.dart';
import 'package:silid/core/resources/service/daily.dart';
import 'package:silid/core/utility/theme/colors.dart';
import 'package:silid/core/utility/widgets/dialogs.dart';
import 'package:silid/core/utility/widgets/navbar.dart';
import 'package:silid/core/views/student/teacher_list.dart';
import 'package:table_calendar/table_calendar.dart';

class StudentIndex extends StatefulWidget {
  const StudentIndex({super.key});

  @override
  State<StudentIndex> createState() => _StudentIndexState();
}

class _StudentIndexState extends State<StudentIndex> {
  final StudentController studentController = Get.find<StudentController>();
  final BookingController bookingController = Get.find<BookingController>();

  DateTime? selectedDay;
  DateTime focusedDay = DateTime.now();
  CalendarFormat calendarFormat = CalendarFormat.month;
  User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    final student = studentController.student.value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (user != null) {
        bookingController.fetchBookings(studentName: student!.name);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Book a Teacher',
            icon: const Icon(Icons.person_add),
            onPressed: () => Get.to(() => TeachersList()),
          ),
        ],
      ),
      drawer: Obx(() {
        final student = studentController.student.value;
        return Navbar(
          name: student?.name,
          email: student?.email,
          profileImageUrl: user?.photoURL,
        );
      }),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: AppColors
                        .tertiary, // Background color for the container
                    borderRadius:
                        BorderRadius.circular(12.0), // Rounded corners
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withOpacity(0.1), // Shadow color with opacity
                        blurRadius: 10, // Shadow blur radius
                        offset: const Offset(
                            0, 4), // Shadow offset (horizontal, vertical)
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Today is",
                        style: TextStyle(
                          fontSize: 18, // Make the "Today is" text larger
                          color: Colors.black, // Set color as per your theme
                        ),
                      ),

                      // Current Date Text with Weekday (e.g., Monday, January 24, 2025)
                      Text(
                        DateFormat('EEEE, MMMM dd, yyyy').format(
                            DateTime.now()), // Include the day of the week
                        style: const TextStyle(
                          fontSize: 32, // Make the date text larger
                          fontWeight: FontWeight.bold,
                          color: Colors.black, // Set color as per your theme
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
                            calendarStyle: const CalendarStyle(
                              defaultTextStyle: TextStyle(color: Colors.black),
                              todayTextStyle: TextStyle(color: Colors.white),
                              todayDecoration: BoxDecoration(
                                color: Colors.blue, // Highlight today's date
                                shape: BoxShape.circle,
                              ),
                              markerDecoration: BoxDecoration(
                                color: Colors.blue, // Events markers
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Obx(() {
                if (bookingController.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
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

                return ListView.builder(
                  itemCount: filteredBookings.length,
                  itemBuilder: (context, index) {
                    final booking = filteredBookings[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: ListTile(
                        title: Text(DateFormat('hh:mm a').format(booking.date),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Teacher: ${booking.teacher}",
                            ),
                            Text(
                              "Status: ${booking.status['message']}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    _getStatusColor(booking.status['message']),
                              ),
                            ),
                            if (booking.status['message'] != "Cancelled" &&
                                booking.status['message'] != "Finished")
                              Padding(
                                padding: const EdgeInsets.only(top: 10.0),
                                child: Row(
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        ShowDialogUtil.showCancellationDialog(
                                          title: "Cancel Booking",
                                          message:
                                              "Please provide a reason for cancellation.",
                                          onConfirm: (remarks) async {
                                            bookingController.cancelBooking(
                                              remarks,
                                              booking.uid,
                                            );
                                          },
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.red, // Button color
                                        foregroundColor:
                                            Colors.white, // Text color
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0, vertical: 8.0),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                      ),
                                      child: const Text("Cancel"),
                                    ),
                                    const SizedBox(width: 5),
                                    ElevatedButton(
                                      onPressed: () => Get.to(
                                        () => MeetingScreen(
                                          roomUrl: booking.meetingLink,
                                          userName: booking.student,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.blue, // Button color
                                        foregroundColor:
                                            Colors.white, // Text color
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0, vertical: 8.0),
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
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
