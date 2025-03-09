// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TeacherAnnouncements extends StatefulWidget {
  const TeacherAnnouncements({super.key});

  @override
  State<TeacherAnnouncements> createState() => _TeacherAnnouncementsState();
}

class _TeacherAnnouncementsState extends State<TeacherAnnouncements> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

  // Function to check if the announcement is read
  bool isRead(DocumentSnapshot announcement) {
    List<dynamic> readBy = announcement['readBy'] ?? [];
    return readBy.contains(currentUserId);
  }

  // Function to mark an announcement as read
  Future<void> markAsRead(String docId) async {
    await FirebaseFirestore.instance
        .collection('announcements')
        .doc(docId)
        .update({
      "readBy": FieldValue.arrayUnion([currentUserId])
    });
  }

  // Function to show announcement details in a dialog
  void showAnnouncementDialog(
      BuildContext context, DocumentSnapshot announcement) {
    String subject = announcement['subject'] ?? 'No Subject';
    String message = announcement['message'] ?? 'No Message';
    String creator = announcement['creator'] ?? 'Unknown';
    Timestamp? timestamp = announcement['created_at'];
    String formattedDate = timestamp != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toDate())
        : 'Unknown Date';

    bool readStatus = isRead(announcement);
    String docId = announcement.id;

    if (!readStatus) {
      markAsRead(docId);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text(subject,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("By: $creator",
                  style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.7))),
              const SizedBox(height: 8),
              Text(message,
                  style: TextStyle(color: theme.colorScheme.onSurface)),
              const SizedBox(height: 10),
              Text("Date: $formattedDate",
                  style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.6))),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close",
                  style: TextStyle(color: theme.colorScheme.primary)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('announcements')
            .where('receiver', whereIn: ['Teachers', 'All', currentUserId])
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            debugPrint("Firestore Error: ${snapshot.error}");
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No announcements available."));
          }

          var announcements = snapshot.data!.docs;

          return ListView.builder(
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              var announcement = announcements[index];
              String subject = announcement['subject'] ?? 'No Subject';
              String creator = announcement['creator'] ?? 'Unknown';
              String message = announcement['message'] ?? 'No Message';
              Timestamp? timestamp = announcement['created_at'];
              String formattedDate = timestamp != null
                  ? DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toDate())
                  : 'Unknown Date';

              bool readStatus = isRead(announcement);

              return GestureDetector(
                onTap: () => showAnnouncementDialog(context, announcement),
                child: Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  color: readStatus
                      ? colorScheme.surface
                      : Colors.grey.shade400, // Darker for unread
                  elevation: 1, // More shadow for unread
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: colorScheme.onSurface.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    title: Row(
                      children: [
                        if (!readStatus)
                          Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: Icon(
                              Icons.warning_amber_rounded,
                              color: Colors
                                  .amberAccent, // Use theme tertiary color
                              size: 20,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            subject,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "By: $creator",
                          style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.7)),
                        ),
                        Text(
                          message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: readStatus
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                              color: colorScheme.onSurface),
                        ),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
