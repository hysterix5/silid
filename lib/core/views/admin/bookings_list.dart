import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:silid/core/resources/controllers/booking_controller.dart';

class BookingsList extends StatelessWidget {
  final BookingController bookingController = Get.put(BookingController());
  BookingsList({super.key}) {
    bookingController.fetchAllBookings();
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
      appBar: AppBar(title: const Text("All Bookings")),
      body: Obx(() {
        if (bookingController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (bookingController.bookings.isEmpty) {
          return const Center(child: Text("No bookings available"));
        }

        return ListView.builder(
          itemCount: bookingController.bookings.length,
          itemBuilder: (context, index) {
            final booking = bookingController.bookings[index];

            DateTime bookingDate;
            try {
              // Try to parse the date
              bookingDate = DateTime.parse(booking.date.toString());
            } catch (e) {
              bookingDate = DateTime.now(); // Fallback date
            }

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                title: Text(
                  DateFormat('MMM dd, yyyy - hh:mm a').format(bookingDate),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Student: ${booking.student}"),
                    Text("Teacher: ${booking.teacher}"),
                    Text(
                      "Status: ${booking.status['message']}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(booking.status['message']),
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
    );
  }
}
