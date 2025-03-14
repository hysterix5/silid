import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TeacherNotif extends StatefulWidget {
  const TeacherNotif({super.key});

  @override
  State<TeacherNotif> createState() => _TeacherNotifState();
}

class _TeacherNotifState extends State<TeacherNotif> {
  User? user = FirebaseAuth.instance.currentUser;

  // Stream to fetch notifications from Firestore
  Stream<QuerySnapshot> _fetchNotificationsStream() {
    return FirebaseFirestore.instance
        .collection("teachers")
        .doc(user?.uid) // Replace with actual user ID
        .collection("notifications")
        .orderBy('created_at',
            descending: true) // Order by created date, descending
        .snapshots(); // Real-time updates
  }

  // Update the status to 'read' when notification is tapped
  Future<void> _markAsRead(DocumentSnapshot notificationDoc) async {
    try {
      await FirebaseFirestore.instance
          .collection("teachers")
          .doc(user?.uid)
          .collection("notifications")
          .doc(notificationDoc.id) // Get the notification document ID
          .update({
        'status': 'read', // Update the status to 'read'
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _fetchNotificationsStream(), // Fetch notifications from Firestore
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No notifications available.'));
          }

          // Fetch the notifications data
          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              var notification =
                  notifications[index].data() as Map<String, dynamic>;
              String creator = notification['creator'] ?? 'Unknown';
              String subject = notification['subject'] ?? 'No Subject';
              String message = notification['message'] ?? 'No Message';
              Timestamp createdAt =
                  notification['created_at'] ?? Timestamp.now();
              String formattedDate =
                  DateFormat('MM/dd/yyyy').format(createdAt.toDate());
              String status = notification['status'] ?? 'unread';

              // Differentiating styles based on the 'status'
              bool isUnread = status == 'unread';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: isUnread
                    ? Colors.blue.shade50
                    : Colors.grey
                        .shade200, // Change background color based on status
                child: ListTile(
                  title: Text(
                    subject,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isUnread
                          ? Colors.black
                          : Colors.grey, // Change text color for unread vs read
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('From: $creator'),
                      Text('Created at: $formattedDate',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  isThreeLine: true,
                  onTap: () {
                    // Mark notification as read when it's tapped
                    _markAsRead(notifications[index]);

                    // Show more details about the notification here
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(subject),
                        content: Text(message),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
