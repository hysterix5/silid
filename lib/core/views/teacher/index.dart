// ignore_for_file: deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:silid/core/resources/controllers/booking_controller.dart';
import 'package:silid/core/resources/controllers/teacher_controller.dart';
import 'package:silid/core/resources/service/daily.dart';
import 'package:silid/core/utility/widgets/dialogs.dart';
import 'package:silid/core/utility/widgets/navbar.dart';
import 'package:silid/core/utility/widgets/snackbar.dart';
import 'package:table_calendar/table_calendar.dart';

class TeacherIndex extends StatefulWidget {
  const TeacherIndex({super.key});

  @override
  State<TeacherIndex> createState() => _TeacherIndexState();
}

class _TeacherIndexState extends State<TeacherIndex> {
  final TeacherController teacherController = Get.find<TeacherController>();
  final BookingController bookingController = Get.find<BookingController>();
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
        bookingController.fetchBookings(teacherName: teacher!.name);
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
    final teacher = teacherController.teacher.value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
      ),
      drawer: Navbar(
        name: teacher?.name,
        email: teacher?.email,
        profileImageUrl: teacher?.profileImage,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          // Make the page scrollable
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(12.0), // Rounded corners
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
                                style: TextStyle(
                                  fontSize:
                                      18, // Make the "Today is" text larger
                                ),
                              ),
                              Text(
                                DateFormat('EEEE, MMMM dd, yyyy')
                                    .format(DateTime.now()),
                                style: const TextStyle(
                                  fontSize: 32, // Make the date text larger
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              Row(
                                children: [
                                  Text(
                                    "Referral Code: ${teacher!.uniqueCode}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(
                                      width: 8), // Space between text and icon
                                  IconButton(
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(
                                          text: teacher.uniqueCode));
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
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical:
                                          14), // Adjust padding for a square-like look
                                  textStyle: TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.bold), // Emphasize text
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        12), // Adjust border radius for a more square-like shape
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.edit_calendar_outlined,
                                        size:
                                            24), // Slightly larger icon for emphasis
                                    SizedBox(
                                        width:
                                            8), // Space between icon and text
                                    Text("Open Schedule"),
                                  ],
                                ),
                              )
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
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary, // Use theme primary color
                                  shape: BoxShape.circle,
                                ),
                                markerDecoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary, // Use theme secondary color
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
              Obx(() {
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

                return SizedBox(
                  height: 400, // Set a fixed height for the list
                  child: ListView.builder(
                    physics:
                        const NeverScrollableScrollPhysics(), // Prevent nested scrolling issues
                    shrinkWrap: true, // Ensure it takes only the needed space
                    itemCount: filteredBookings.length,
                    itemBuilder: (context, index) {
                      final booking = filteredBookings[index];
                      return Card(
                        child: ListTile(
                          title: Text(
                              DateFormat('hh:mm a').format(booking.date),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
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
                                    spacing: 5.0, // Space between buttons
                                    // Space between wrapped rows
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          ShowDialogUtil.showCancellationDialog(
                                            title: "Cancel Booking",
                                            message:
                                                "Please provide a reason for cancellation.",
                                            onConfirm: (remarks) async {
                                              bookingController.cancelBooking(
                                                  remarks, booking.uid);
                                            },
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16.0, vertical: 8.0),
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
                                              bookingController
                                                  .finishBooking(booking.uid);
                                            },
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16.0, vertical: 8.0),
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
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
