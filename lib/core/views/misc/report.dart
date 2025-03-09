import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:silid/core/utility/widgets/snackbar.dart';

class BugReportPage extends StatefulWidget {
  const BugReportPage({super.key});

  @override
  State<BugReportPage> createState() => _BugReportPageState();
}

class _BugReportPageState extends State<BugReportPage> {
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedCategory = "UI Issue";
  bool _isSubmitting = false;
  Uint8List? _selectedImage; // Use Uint8List for web compatibility
  final ImagePicker _picker = ImagePicker();

  final List<String> categories = [
    "UI Issue",
    "Performance Issue",
    "Crash / Error",
    "Feature Request",
    "Other"
  ];

  // Pick Image (Works on Web & Mobile)
  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes(); // Read as Uint8List
      setState(() => _selectedImage = bytes);
    }
  }

  // Upload Image to Firebase Storage
  Future<String?> uploadImage(Uint8List imageBytes) async {
    try {
      String fileName =
          "bug_reports/${DateTime.now().millisecondsSinceEpoch}.jpg";
      Reference ref = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = ref.putData(imageBytes);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      Get.snackbar("Error", "Failed to upload image.",
          backgroundColor: Colors.red, colorText: Colors.white);
      return null;
    }
  }

  // Submit Bug Report
  Future<void> submitBugReport() async {
    if (_descriptionController.text.trim().isEmpty) {
      Get.snackbar("Error", "Please enter a bug description.",
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    setState(() => _isSubmitting = true);

    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await uploadImage(_selectedImage!);
    }

    try {
      await FirebaseFirestore.instance.collection('bug_reports').add({
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      SnackbarWidget.showSuccess("Bug report submitted successfully!");
      _descriptionController.clear();
      setState(() => _selectedImage = null);
    } catch (e) {
      SnackbarWidget.showError("Failed to submit bug report.");
    }

    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Report a Bug")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Bug Description", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Describe the bug in detail...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text("Category", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: categories
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedCategory = value!),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Image Picker Section
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text("Attach Image"),
                ),
                const SizedBox(width: 12),
                if (_selectedImage != null)
                  const Text("Image Selected",
                      style: TextStyle(color: Colors.green)),
              ],
            ),
            const SizedBox(height: 12),

            // Image Preview (Works on Web & Mobile)
            if (_selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  _selectedImage!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.fitHeight,
                ),
              ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : submitBugReport,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Report"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
