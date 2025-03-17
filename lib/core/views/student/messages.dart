// ignore_for_file: use_build_context_synchronously, unused_local_variable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:silid/core/utility/widgets/snackbar.dart';
import 'package:silid/core/views/misc/chat.dart';

class StudentChatListScreen extends StatelessWidget {
  const StudentChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chats"),
        actions: [
          IconButton(
            onPressed: () => _selectTeacherForChat(context, currentUserId),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("chats").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No active chats"));
          }

          var chatDocs = snapshot.data!.docs.where((doc) {
            var participants = List<String>.from(doc["participants"]);
            return participants.contains(currentUserId);
          }).toList();

          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              var chat = chatDocs[index];
              var participants = List<String>.from(chat["participants"]);
              String otherUserId =
                  participants.firstWhere((id) => id != currentUserId);

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection("teachers")
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return const SizedBox();
                  }

                  var userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("chats")
                        .doc(chat.id) // Chat document ID
                        .collection("messages")
                        .where("senderId",
                            isEqualTo:
                                otherUserId) // Messages from the other user
                        .where("isRead",
                            isEqualTo: false) // Only unread messages
                        .snapshots(),
                    builder: (context, messageSnapshot) {
                      int unreadCount = messageSnapshot.hasData
                          ? messageSnapshot.data!.docs.length
                          : 0;

                      return ListTile(
                        title: Text(
                            '${userData["firstName"]} ${userData["lastName"]}'),
                        subtitle: Text(unreadCount > 0
                            ? "Unread messages: $unreadCount"
                            : "Tap to chat"),
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              backgroundImage:
                                  NetworkImage(userData["profileImage"] ?? ""),
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    unreadCount.toString(),
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                otherUserId: otherUserId,
                                otherUserName:
                                    "${userData["firstName"]} ${userData["lastName"]}",
                              ),
                            ),
                          ).then((_) {
                            // Mark messages as read when user opens chat
                            FirebaseFirestore.instance
                                .collection("chats")
                                .doc(chat.id)
                                .collection("messages")
                                .where("senderId", isEqualTo: otherUserId)
                                .where("isRead", isEqualTo: false)
                                .get()
                                .then((unreadMessages) {
                              for (var doc in unreadMessages.docs) {
                                doc.reference.update({"isRead": true});
                              }
                            });
                          });
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _selectTeacherForChat(BuildContext context, String currentUserId) async {
    // Fetch the student's document to get the "assigned_teacher" field
    DocumentSnapshot studentDoc = await FirebaseFirestore.instance
        .collection("students")
        .doc(currentUserId)
        .get();

    if (!studentDoc.exists || studentDoc["assigned_teacher"] == null) {
      SnackbarWidget.showError("No teachers assigned yet.");
      return;
    }

    // Extract the assigned teacher map
    Map<String, dynamic> teacher = studentDoc["assigned_teacher"];

    // Show a dialog with teacher details
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Assigned Teacher"),
          content: ListTile(
            title: Text(teacher["name"] ?? "Unknown"),
            onTap: () {
              Navigator.pop(context); // Close dialog
              _startChat(
                  context, currentUserId, teacher["uid"], teacher["name"]);
            },
          ),
        );
      },
    );
  }

  void _startChat(BuildContext context, String currentUserId, String teacherId,
      String teacherName) async {
    CollectionReference chatsRef =
        FirebaseFirestore.instance.collection("chats");

    // Check if a chat already exists between student and teacher
    QuerySnapshot chatQuery = await chatsRef.where("participants",
        arrayContainsAny: [currentUserId, teacherId]).get();

    var existingChat = chatQuery.docs.isEmpty ? null : chatQuery.docs.first;

    String chatId;

    if (existingChat != null) {
      chatId = existingChat.id;
    } else {
      // Create a new chat if it doesn't exist
      DocumentReference newChat = await chatsRef.add({
        "participants": [currentUserId, teacherId],
        "created_at": FieldValue.serverTimestamp(),
      });
      chatId = newChat.id;
    }

    // Navigate to the chat screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          otherUserId: teacherId,
          otherUserName: teacherName,
        ),
      ),
    );
  }
}
