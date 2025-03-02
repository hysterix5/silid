import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:silid/core/resources/auth/login.dart';
import 'package:silid/core/resources/controllers/auth_controller.dart';
import 'package:silid/core/resources/controllers/booking_controller.dart';
import 'package:silid/core/resources/controllers/daily_controller.dart';
import 'package:silid/core/resources/controllers/data_controller.dart';
import 'package:silid/core/resources/controllers/student_controller.dart';
import 'package:silid/core/resources/controllers/teacher_controller.dart';
import 'package:silid/core/utility/theme/colors.dart';
import 'package:silid/core/utility/theme/controllers/theme_controller.dart';
import 'package:silid/firebase_options.dart';

Future<void> main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  Get.put(AuthController());
  Get.put(DataController());
  Get.put(TeacherController());
  Get.put(StudentController());
  Get.put(BookingController());
  Get.put(DailyController());
  Get.put(ThemeController());
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: AppColors.lightTheme, // Light Mode Theme
      darkTheme: AppColors.darkTheme, // Dark Mode Theme
      themeMode: ThemeMode.system, // Follows system settings

      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = Get.find<AuthController>().currentUser.value;
      if (user == null) {
        return LoginPage();
      }

      // Ensure navigation happens only once after user logs in
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.find<DataController>().checkUserAndNavigate(user.uid);
      });

      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    });
  }
}
