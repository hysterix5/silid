// ignore_for_file: use_build_context_synchronously, unused_local_variable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:silid/core/utility/widgets/snackbar.dart';
import 'package:silid/core/views/misc/chat.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chats"),
        actions: [
          IconButton(
            onPressed: () => _selectStudentForChat(context, currentUserId),
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
                    .collection("students")
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return Center(child: const CircularProgressIndicator());
                  }

                  var userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text(
                        '${userData["firstName"]} ${userData["lastName"]}'),
                    subtitle: const Text("Tap to chat"),
                    leading: CircleAvatar(
                      backgroundImage:
                          NetworkImage(userData["profileImage"] ?? ""),
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

  void _selectStudentForChat(BuildContext context, String currentUserId) async {
    // Fetch the teacher's document to get the "students" field
    DocumentSnapshot teacherDoc = await FirebaseFirestore.instance
        .collection("teachers")
        .doc(currentUserId)
        .get();

    List students = teacherDoc["students"] ?? [];

    if (students.isEmpty) {
      SnackbarWidget.showError("No teachers assigned yet.");

      return;
    }

    // Show dialog with students list
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select a Student"),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: ListBody(
                children: students.map((student) {
                  return ListTile(
                    title: Text(student["name"] ?? "Unknown"),
                    onTap: () {
                      Navigator.pop(context); // Close dialog
                      _startChat(context, currentUserId, student["uid"],
                          student["name"]);
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  void _startChat(BuildContext context, String currentUserId, String studentId,
      String studentName) async {
    CollectionReference chatsRef =
        FirebaseFirestore.instance.collection("chats");

    // Check if a chat already exists between teacher and student
    QuerySnapshot chatQuery = await chatsRef.where("participants",
        arrayContainsAny: [currentUserId, studentId]).get();

    var existingChat = chatQuery.docs.isEmpty ? null : chatQuery.docs.first;

    String chatId;

    if (existingChat != null) {
      chatId = existingChat.id;
    } else {
      // Create a new chat if it doesn't exist
      DocumentReference newChat = await chatsRef.add({
        "participants": [currentUserId, studentId],
        "created_at": FieldValue.serverTimestamp(),
      });
      chatId = newChat.id;
    }

    // Navigate to the chat screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          otherUserId: studentId,
          otherUserName: studentName,
        ),
      ),
    );
  }
}
