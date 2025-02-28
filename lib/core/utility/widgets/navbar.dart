// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:ztalk/controllers/auth_controller.dart';
// import 'package:ztalk/core/common/widgets/utility/dialogs.dart';

// class Navbar extends StatelessWidget {
//   final String? name;
//   final String? email;
//   final String profileImageUrl;

//   const Navbar({
//     super.key,
//     required this.name,
//     required this.email,
//     required this.profileImageUrl,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Drawer(
//       child: ListView(
//         padding: EdgeInsets.zero,
//         children: [
//           UserAccountsDrawerHeader(
//             accountName: Text(name!, style: const TextStyle(fontSize: 18)),
//             accountEmail: Text(email!),
//             currentAccountPicture: CircleAvatar(
//               backgroundImage: NetworkImage(profileImageUrl),
//             ),
//             decoration: const BoxDecoration(color: Colors.blue),
//           ),
//           ListTile(
//             leading: const Icon(Icons.home),
//             title: const Text('Home'),
//             onTap: () {
//               // Navigate to home
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.settings),
//             title: const Text('Settings'),
//             onTap: () {
//               // Navigate to settings
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.logout),
//             title: const Text('Logout'),
//             onTap: () {
//               ShowDialogUtil.showConfirmDialog(
//                 title: "Logout",
//                 message: "Are you sure you want to log out?",
//                 onConfirm: () {
//                   Get.find<AuthController>()
//                       .logOut(); // Execute logout if confirmed
//                 },
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }
