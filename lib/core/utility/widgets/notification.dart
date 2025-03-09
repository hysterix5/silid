import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:silid/core/views/teacher/announcement_page.dart';

class AnnouncementIcon extends StatefulWidget {
  const AnnouncementIcon({super.key});

  @override
  State<AnnouncementIcon> createState() => _AnnouncementIconState();
}

class _AnnouncementIconState extends State<AnnouncementIcon> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('announcements')
          .where('receiver', whereIn: ['Teachers', 'All']).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          debugPrint("Firestore Error: ${snapshot.error}");
          return const Icon(Icons.error, color: Colors.red);
        }

        int unreadCount = snapshot.data?.docs.where((doc) {
              List<dynamic> readBy = doc['readBy'] ?? [];
              return !readBy.contains(currentUserId); // ✅ Count only unread
            }).length ??
            0;

        return Stack(
          children: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const TeacherAnnouncements()),
                );
              },
              icon: const Icon(Icons.notifications),
              iconSize: 32,
              tooltip: "Notifications",
            ),
            if (unreadCount >
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
                    "$unreadCount", // 🔥 Only unread count
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
