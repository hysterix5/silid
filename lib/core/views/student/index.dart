import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:silid/core/resources/controllers/booking_controller.dart';
import 'package:silid/core/resources/controllers/student_controller.dart';
import 'package:silid/core/resources/service/daily.dart';
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
      body: Column(
        children: [
          GetBuilder<BookingController>(
            builder: (controller) {
              return TableCalendar(
                firstDay: DateTime.utc(2010, 10, 16),
                lastDay: DateTime.utc(2030, 3, 14),
                focusedDay: focusedDay,
                selectedDayPredicate: (day) => isSameDay(selectedDay, day),
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
                    return DateFormat('yyyy-MM-dd').format(booking.date) ==
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
                    margin:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: ListTile(
                      title: Text(DateFormat('hh:mm a').format(booking.date),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Teacher: ${booking.teacher}",
                          ),
                          Text(
                              "Status: ${booking.status['message'] ?? 'Pending'}"),
                        ],
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MeetingScreen(
                            roomUrl: booking.meetingLink,
                            userName: booking.student,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
