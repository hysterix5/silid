import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:silid/core/utility/widgets/dialogs.dart';
import 'package:silid/core/utility/widgets/snackbar.dart';
import 'package:url_launcher/url_launcher.dart';

class LessonLibrary extends StatefulWidget {
  const LessonLibrary({super.key});

  @override
  State<LessonLibrary> createState() => _LessonLibraryState();
}

class _LessonLibraryState extends State<LessonLibrary> {
  final CollectionReference lessonsRef =
      FirebaseFirestore.instance.collection('lessons');

  void _openLesson(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      SnackbarWidget.showError("Could not launch the link");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lesson Library"),
        actions: [
          IconButton(
            onPressed: () {
              ShowDialogUtil.showAddLessonDialog(
                onSuccess: () {
                  setState(() {}); // Refresh UI if needed
                },
              );
            },
            icon: const Icon(Icons.add_box),
            tooltip: "Add Lesson",
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: lessonsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No lessons available."));
          }

          var lessons = snapshot.data!.docs;

          return ListView.builder(
            itemCount: lessons.length,
            itemBuilder: (context, index) {
              var lesson = lessons[index];
              String title = lesson['title'] ?? 'Untitled';
              String link = lesson['link'] ?? '';
              String docId = lesson.id;

              return ListTile(
                title: Text(title),
                subtitle: Text(
                  link,
                  style: const TextStyle(color: Colors.blue),
                ),
                onTap: () => _openLesson(link),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        ShowDialogUtil.showConfirmDialog(
                            title: "Confirm Deletion",
                            message: "Are you sure to delete this lesson?",
                            onConfirm: () async {
                              try {
                                await lessonsRef.doc(docId).delete();
                                SnackbarWidget.showSuccess(
                                    "Lesson deleted successfully.");
                              } catch (e) {
                                SnackbarWidget.showError(
                                    "Error deleting lesson: $e");
                              }
                            });
                      },
                    ),
                    const Icon(Icons.open_in_new),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
