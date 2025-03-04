import 'dart:typed_data';
import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:silid/core/resources/controllers/auth_controller.dart';
import 'package:silid/core/utility/theme/controllers/theme_controller.dart';
import 'package:silid/core/utility/widgets/dialogs.dart';
import 'package:silid/core/utility/widgets/snackbar.dart';

class Navbar extends StatelessWidget {
  final String? name;
  final String? email;
  final String? profileImageUrl;

  const Navbar({
    super.key,
    required this.name,
    required this.email,
    required this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(name!, style: const TextStyle(fontSize: 18)),
            accountEmail: Text(email!),
            currentAccountPicture:
                ProfilePictureWidget(profileImg: profileImageUrl),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              SnackbarWidget.showError('Test Snackbar');
            },
          ),

          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              ShowDialogUtil.showConfirmDialog(
                title: "Logout",
                message: "Are you sure you want to log out?",
                onConfirm: () {
                  Get.find<AuthController>().logOut();
                },
              );
            },
          ),
          const Divider(),
          // Dark Mode Toggle
          Obx(
            () => ListTile(
              leading: Icon(themeController.isDarkMode.value
                  ? Icons.dark_mode
                  : Icons.light_mode),
              title: const Text("Dark Mode"),
              trailing: Switch(
                value: themeController.isDarkMode.value,
                onChanged: (value) {
                  themeController.toggleTheme();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfilePictureWidget extends StatefulWidget {
  final String? profileImg;
  const ProfilePictureWidget({super.key, required this.profileImg});

  @override
  ProfilePictureWidgetState createState() => ProfilePictureWidgetState();
}

class ProfilePictureWidgetState extends State<ProfilePictureWidget> {
  bool _isHovered = false;
  html.File? _pickedFile;
  Uint8List? _imageData;
  bool _isValidImage(html.File file) {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    final fileName = file.name.toLowerCase();
    final fileExtension = fileName.split('.').last;
    return imageExtensions.contains(fileExtension);
  }

  Future<void> _pickImage() async {
    final imageFile = (await ImagePickerWeb.getMultiImagesAsFile())?.first;

    if (imageFile != null) {
      if (!_isValidImage(imageFile)) {
        Get.snackbar("Error", "Please select a valid image file");
        return;
      }
      setState(() {
        _pickedFile = imageFile;
      });

      final reader = html.FileReader();
      reader.readAsArrayBuffer(imageFile);

      // Wait for the file reader to finish loading the image
      await reader.onLoadEnd.first;

      setState(() {
        _imageData = reader.result as Uint8List;
      });

      // Once the image is loaded, trigger the upload function
      _uploadImage();
    } else {}
  }

  Future<void> _uploadImage() async {
    if (_pickedFile == null || _imageData == null) {
      return;
    }
    _showUploadDialog();

    String formattedDate =
        DateTime.now().toIso8601String().replaceAll(':', '-');
    String newFileName = 'profile_$formattedDate.jpg'; // Profile picture

    Reference storageRef =
        FirebaseStorage.instance.ref().child('profile_pictures/$newFileName');

    try {
      final uploadTask = storageRef.putData(_imageData!);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        // double progress =
        //     (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
      });

      await uploadTask.whenComplete(() async {
        String downloadURL = await storageRef.getDownloadURL();
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          try {
            String uid = user.uid;

            final teachersRef =
                FirebaseFirestore.instance.collection('teachers').doc(uid);
            final studentsRef =
                FirebaseFirestore.instance.collection('students').doc(uid);

            DocumentSnapshot teacherDoc = await teachersRef.get();
            if (teacherDoc.exists) {
              // User is a teacher, update only the profile_picture field
              await teachersRef.update({
                "profileImage": downloadURL,
              });
              Get.back(); // Close the upload dialog
              return;
            }

            // If not a teacher, check if they are a student
            DocumentSnapshot studentDoc = await studentsRef.get();
            if (studentDoc.exists) {
              // User is a student, update only the profile_picture field
              await studentsRef.update({
                "profileImage": downloadURL,
              });

              Get.back(); // Close the upload dialog
              return;
            }

            // If neither teacher nor student
            Get.snackbar("Error",
                "User not found in either teachers or students collection");
          } catch (error) {
            Get.snackbar("Error", "$error");
          }
        }
      });
    } catch (e) {
      Get.back();
      Get.snackbar("Error", "Error uploading file: $e");
    }
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: 75,
            backgroundImage:
                widget.profileImg != null && widget.profileImg!.isNotEmpty
                    ? NetworkImage(widget.profileImg!)
                    : null,
            child: widget.profileImg == null || widget.profileImg!.isEmpty
                ? const Icon(Icons.person, size: 50)
                : null,
          ),
          if (_isHovered) // Show the edit icon on hover
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5), // Low transparency
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  _pickImage();
                },
              ),
            ),
        ],
      ),
    );
  }
}
