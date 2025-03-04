import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:silid/core/resources/controllers/booking_controller.dart';
import 'package:silid/core/resources/controllers/daily_controller.dart';
import 'package:silid/core/resources/controllers/student_controller.dart';
import 'package:silid/core/resources/controllers/teacher_controller.dart';
import 'package:silid/core/resources/service/daily.dart';
import 'package:silid/core/utility/widgets/dialogs.dart';
import 'package:silid/core/utility/widgets/navbar.dart';
import 'package:silid/core/views/student/bookpage.dart';
import 'package:table_calendar/table_calendar.dart';

class StudentIndex extends StatefulWidget {
  const StudentIndex({super.key});

  @override
  State<StudentIndex> createState() => _StudentIndexState();
}

class _StudentIndexState extends State<StudentIndex> {
  final StudentController studentController = Get.find<StudentController>();
  final TeacherController teacherController = Get.find<TeacherController>();
  final BookingController bookingController = Get.find<BookingController>();
  final DailyController dailyController = Get.find<DailyController>();

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
        bookingController.fetchBookings(
          studentName:
              "${student?.firstName ?? ''} ${student?.lastName ?? ''}".trim(),
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
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
      ),
      drawer: Obx(() {
        final student = studentController.student.value;

        return Navbar(
          name: "${student?.firstName ?? ''} ${student?.lastName ?? ''}".trim(),
          email: student?.email ?? "No email provided",
          profileImageUrl: student?.profileImage ?? "",
        );
      }),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Section
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

                          // Display Teacher's Name
                          Obx(() {
                            final assignedTeacher =
                                studentController.assignedTeacher;
                            return Text(
                              assignedTeacher['name']?.isNotEmpty == true
                                  ? "Assigned Teacher: ${assignedTeacher['name']}"
                                  : "No Teacher Assigned Yet",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          }),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () async {
                              final student = studentController.student.value;

                              if (student == null ||
                                  student.assignedTeacher['name'] == '') {
                                debugPrint("No teacher assigned");

                                // Show dialog to enter teacher code
                                ShowDialogUtil.showTeacherCodeDialog(
                                  title: "Assign Teacher",
                                  onConfirm: (teacherCode) async {
                                    await teacherController.fetchTeacherByCode(
                                        teacherCode, student!.uid);
                                    await studentController
                                        .fetchStudentData(student.uid);
                                  },
                                );
                              } else {
                                Get.to(() => TeacherSchedulePage(
                                      teacherId: student.assignedTeacher['uid'],
                                      teacherName:
                                          student.assignedTeacher['name'],
                                    ));
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              textStyle: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.calendar_month, size: 24),
                                SizedBox(width: 8),
                                Text("Book Schedule"),
                              ],
                            ),
                          ),
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
              const SizedBox(height: 10),

              // Booking List
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

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredBookings.length,
                  itemBuilder: (context, index) {
                    final booking = filteredBookings[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: ListTile(
                        title: Text(
                          DateFormat('hh:mm a').format(booking.date),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Teacher: ${booking.teacher}"),
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
                                child: Wrap(
                                  alignment: WrapAlignment.start,
                                  spacing: 5.0, // Space between buttons
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        ShowDialogUtil.showCancellationDialog(
                                          title: "Cancel Booking",
                                          message:
                                              "Please provide a reason for cancellation.",
                                          onConfirm: (remarks) async {
                                            await dailyController
                                                .deleteDailyRoom(
                                                    booking.meetingLink);
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
                                    const SizedBox(width: 5),
                                    ElevatedButton(
                                      onPressed: () => Get.to(
                                        () => MeetingScreen(
                                          roomUrl: booking.meetingLink,
                                          userName: booking.student,
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
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
