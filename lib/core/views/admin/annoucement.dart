import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:silid/core/utility/widgets/dialogs.dart';

class Announcements extends StatefulWidget {
  const Announcements({super.key});

  @override
  State<Announcements> createState() => _AnnouncementsState();
}

class _AnnouncementsState extends State<Announcements> {
  void _deleteAnnouncement(String docId) {
    FirebaseFirestore.instance.collection('announcements').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Announcements"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              ShowDialogUtil.showAddAnnouncementDialog(
                onSuccess: () {
                  setState(() {}); // Refresh UI
                },
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('announcements')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No announcements available."));
          }

          var announcements = snapshot.data!.docs;

          return ListView.builder(
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              var announcement = announcements[index];
              String docId = announcement.id;
              String creator = announcement['creator'] ?? 'Unknown';
              String subject = announcement['subject'] ?? 'No Subject';
              String message = announcement['message'] ?? 'No Message';
              String receiver =
                  announcement['recipient'] ?? 'All'; // Default to "All"
              Timestamp? timestamp = announcement['created_at'];
              String formattedDate = timestamp != null
                  ? DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toDate())
                  : 'Unknown Date';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(subject,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("By: $creator",
                          style: TextStyle(color: Colors.grey[700])),
                      Text("For: $receiver",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.blue)),
                      Text(message),
                      Text(formattedDate,
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteAnnouncement(docId),
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
