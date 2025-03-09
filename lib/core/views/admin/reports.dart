import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:silid/core/utility/widgets/snackbar.dart';
import 'package:url_launcher/url_launcher.dart';

class BugReports extends StatefulWidget {
  const BugReports({super.key});

  @override
  State<BugReports> createState() => _BugReportsState();
}

class _BugReportsState extends State<BugReports> {
  final RxList<Map<String, dynamic>> bugReports = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void initState() {
    super.initState();
    fetchBugReports();
  }

  Future<void> fetchBugReports() async {
    try {
      isLoading.value = true;

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('bug_reports')
          .orderBy('timestamp', descending: true)
          .get();

      bugReports.value = querySnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'description': data['description'] ?? 'No description',
          'category': data['category'] ?? 'Unknown',
          'imageUrl': data['imageUrl'], // Nullable field
          'timestamp':
              (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch bug reports: $e",
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bug Reports")),
      body: Obx(() {
        if (isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (bugReports.isEmpty) {
          return const Center(child: Text("No bug reports found."));
        }

        return RefreshIndicator(
          onRefresh: fetchBugReports,
          child: ListView.builder(
            itemCount: bugReports.length,
            itemBuilder: (context, index) {
              var report = bugReports[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                elevation: 2,
                child: ListTile(
                  leading: report['imageUrl'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(report['imageUrl'],
                              width: 50, height: 50, fit: BoxFit.cover))
                      : const Icon(Icons.bug_report,
                          size: 40, color: Colors.red),
                  title: Text(report['category'],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(report['description'],
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Text(
                    DateFormat.yMMMd().add_jm().format(report['timestamp']),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  onTap: () => showBugDetails(report),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  void showBugDetails(Map<String, dynamic> report) {
    Get.defaultDialog(
      title: report['category'],
      content: Column(
        children: [
          if (report['imageUrl'] != null)
            Column(
              children: [
                Image.network(report['imageUrl'],
                    height: 200, fit: BoxFit.cover),
                const SizedBox(height: 10),
                IconButton(
                  onPressed: () => openImageInBrowser(report['imageUrl']),
                  icon: const Icon(Icons.download),
                )
              ],
            ),
          const SizedBox(height: 10),
          Text(report['description'], textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(
            "Reported on: ${DateFormat.yMMMd().add_jm().format(report['timestamp'])}",
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
      textConfirm: "Close",
      confirmTextColor: Colors.white,
      buttonColor: Colors.blue,
      onConfirm: () => Get.back(),
    );
  }

  void openImageInBrowser(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      SnackbarWidget.showError("Could not open image");
    }
  }
}
