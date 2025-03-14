import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:silid/core/views/student/notifications.dart';

class StudentNotifIcon extends StatefulWidget {
  const StudentNotifIcon({super.key});

  @override
  State<StudentNotifIcon> createState() => _StudentNotifIconState();
}

class _StudentNotifIconState extends State<StudentNotifIcon> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

  Stream<QuerySnapshot> _fetchUnreadNotificationsStream() {
    return FirebaseFirestore.instance
        .collection("students")
        .doc(currentUserId)
        .collection("notifications")
        .where('status', isEqualTo: 'unread')
        .snapshots(); // Real-time updates
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _fetchUnreadNotificationsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          debugPrint("Firestore Error: ${snapshot.error}");
          return const Icon(Icons.error, color: Colors.red);
        }
        final notificationsCount = snapshot.data?.docs.length ?? 0;

        return Stack(
          children: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StudentNotif()),
                );
              },
              icon: const Icon(Icons.notifications),
              iconSize: 32,
              tooltip: "Notifications",
            ),
            if (notificationsCount >
                0) // 🔥 Show badge only if there are unread announcements
              Positioned(
                right: 5,
                top: 5,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    "$notificationsCount", // 🔥 Only unread count
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
