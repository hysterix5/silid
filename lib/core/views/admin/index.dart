import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:silid/core/utility/widgets/navbar.dart';
import 'package:silid/core/views/admin/annoucement.dart';
import 'package:silid/core/views/admin/bookings_list.dart';
import 'package:silid/core/views/admin/student_list.dart';
import 'package:silid/core/views/admin/teacher_list.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int teacherCount = 0;
  int studentCount = 0;
  int bookingCount = 0;
  int announcementCount = 0;

  @override
  void initState() {
    super.initState();
    // Start streaming the counts from Firestore
    _streamCounts();
  }

  // Real-time streaming method to listen for collection changes
  void _streamCounts() {
    // Listen to teacher collection changes
    FirebaseFirestore.instance
        .collection('teachers')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        teacherCount =
            snapshot.docs.length; // Update teacher count in real-time
      });
    });

    // Listen to student collection changes
    FirebaseFirestore.instance
        .collection('students')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        studentCount =
            snapshot.docs.length; // Update student count in real-time
      });
    });

    // Listen to booking collection changes (if applicable)
    FirebaseFirestore.instance
        .collection('bookings')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        bookingCount =
            snapshot.docs.length; // Update booking count in real-time
      });
    });

    // FirebaseFirestore.instance
    //     .collection('announcements')
    //     .snapshots()
    //     .listen((snapshot) {
    //   setState(() {
    //     announcementCount =
    //         snapshot.docs.length; // Update booking count in real-time
    //   });
    // });
  }

  // Navigation method to navigate to a specific collection's page
  User? user = FirebaseAuth.instance.currentUser;
  String name = 'Test Admin';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
      ),
      drawer: Navbar(
          name: name, email: user!.email, profileImageUrl: user!.photoURL),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0), // Reduced padding
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dashboard title
                const Text(
                  'Administrator Dashboard',
                  style: TextStyle(
                    fontSize: 28.0, // Reduced font size
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 25.0),

                // ListView of counts for Teachers, Students, and Bookings
                ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildListTile(
                        'Teachers', teacherCount, Icons.person, TeacherList()),
                    _buildListTile(
                        'Students', studentCount, Icons.school, StudentList()),
                    _buildListTile(
                        'Bookings', bookingCount, Icons.book, BookingsList()),
                    _buildListTile('Announcements', announcementCount,
                        Icons.speaker, const Announcements()),
                    Card(
                      elevation: 3.0, // Slightly smaller elevation
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(8.0), // Smaller border radius
                      ),
                      margin: const EdgeInsets.only(
                          bottom: 12.0), // Spacing between tiles
                      child: InkWell(
                        onTap: () {
                          // Get.to(context, const PaymentLogs());
                        },
                        child: const ListTile(
                          contentPadding:
                              EdgeInsets.all(12.0), // Reduced padding
                          title: Text(
                            'Payment Transactions',
                            style: TextStyle(
                              fontSize: 18.0, // Reduced font size for the title
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          leading: Icon(Icons.receipt,
                              color: Colors.blueAccent), // Icon based on title
                        ),
                      ),
                    ),
                    Card(
                      elevation: 3.0, // Slightly smaller elevation
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(8.0), // Smaller border radius
                      ),
                      margin: const EdgeInsets.only(
                          bottom: 12.0), // Spacing between tiles
                      child: InkWell(
                        onTap: () {
                          // Get.to(context, const TransactionLogs());
                        }, // On tap, navigate to collection page
                        child: const ListTile(
                          contentPadding:
                              EdgeInsets.all(12.0), // Reduced padding
                          title: Text(
                            'Logs',
                            style: TextStyle(
                              fontSize: 18.0, // Reduced font size for the title
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          leading: Icon(Icons.history,
                              color: Colors.blueAccent), // Icon based on title
                        ),
                      ),
                    ),
                    Card(
                      elevation: 3.0, // Slightly smaller elevation
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(8.0), // Smaller border radius
                      ),
                      margin: const EdgeInsets.only(
                          bottom: 12.0), // Spacing between tiles
                      child: InkWell(
                        onTap: () {}, // On tap, navigate to collection page
                        child: const ListTile(
                          contentPadding:
                              EdgeInsets.all(12.0), // Reduced padding
                          title: Text(
                            'Create Announcement',
                            style: TextStyle(
                              fontSize: 18.0, // Reduced font size for the title
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          leading: Icon(Icons.add,
                              color: Colors.blueAccent), // Icon based on title
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to create ListTile widgets with icons
  Widget _buildListTile(String title, int count, IconData icon, navigation) {
    return Card(
      elevation: 3.0, // Slightly smaller elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0), // Smaller border radius
      ),
      margin: const EdgeInsets.only(bottom: 12.0), // Spacing between tiles
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => navigation),
          );
        },
        child: ListTile(
          contentPadding: const EdgeInsets.all(12.0), // Reduced padding
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 18.0, // Reduced font size for the title
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          subtitle: Text(
            '$count',
            style: const TextStyle(
              fontSize: 24.0, // Reduced font size for the count
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          leading: Icon(icon, color: Colors.blueAccent), // Icon based on title
        ),
      ),
    );
  }
}
