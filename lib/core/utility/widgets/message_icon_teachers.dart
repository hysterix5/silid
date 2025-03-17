import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MessageIconTeacher extends StatefulWidget {
  const MessageIconTeacher({super.key});

  @override
  State<MessageIconTeacher> createState() => _MessageIconTeacherState();
}

class _MessageIconTeacherState extends State<MessageIconTeacher> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

  /// 🔹 Stream that fetches unread messages count in real-time
  Stream<int> _fetchUnreadMessagesCount() {
    return FirebaseFirestore.instance
        .collectionGroup("messages") // Look into all message subcollections
        .where("isRead", isEqualTo: false) // Only unread messages
        .where("senderId", isNotEqualTo: currentUserId) // Exclude own messages
        .snapshots()
        .map((snapshot) => snapshot.docs.length); // Get count
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _fetchUnreadMessagesCount(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint("Firestore Error: ${snapshot.error}");
          return const Icon(Icons.error, color: Colors.red);
        }
        int unreadCount = snapshot.data ?? 0;

        return Stack(
          children: [
            IconButton(
              onPressed: () => Get.toNamed("/teacher-chats"),
              icon: const Icon(Icons.message),
              iconSize: 32,
              tooltip: "Messages",
            ),
            if (unreadCount > 0)
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
                    "$unreadCount",
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
