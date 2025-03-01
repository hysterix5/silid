import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:silid/core/resources/controllers/auth_controller.dart';
import 'package:silid/core/utility/widgets/dialogs.dart';

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
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(name!, style: const TextStyle(fontSize: 18)),
            accountEmail: Text(email!),
            currentAccountPicture: CircleAvatar(
              backgroundColor:
                  Colors.grey[300], // Optional background color for the icon
              backgroundImage: profileImageUrl != null
                  ? NetworkImage(profileImageUrl!)
                  : null,
              child: profileImageUrl == null
                  ? const Icon(Icons.person, size: 40, color: Colors.black54)
                  : null,
            ),
            decoration: const BoxDecoration(color: Colors.blue),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              // Navigate to home
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              // Navigate to settings
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
                  Get.find<AuthController>()
                      .logOut(); // Execute logout if confirmed
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
