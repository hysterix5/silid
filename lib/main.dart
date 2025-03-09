import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:silid/core/resources/auth/login.dart';
import 'package:silid/core/resources/controllers/auth_controller.dart';
import 'package:silid/core/resources/controllers/booking_controller.dart';
import 'package:silid/core/resources/controllers/daily_controller.dart';
import 'package:silid/core/resources/controllers/data_controller.dart';
import 'package:silid/core/resources/controllers/payment_controller.dart';
import 'package:silid/core/resources/controllers/student_controller.dart';
import 'package:silid/core/resources/controllers/teacher_controller.dart';
import 'package:silid/core/utility/routes/routes.dart';
import 'package:silid/core/utility/theme/colors.dart';
import 'package:silid/core/utility/theme/controllers/theme_controller.dart';
import 'package:silid/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Fix: Ensures proper initialization

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register controllers
  Get.put(AuthController(), permanent: true);
  Get.put(DataController(), permanent: true);
  Get.put(TeacherController(), permanent: true);
  Get.put(StudentController(), permanent: true);
  Get.put(BookingController(), permanent: true);
  Get.put(DailyController(), permanent: true);
  Get.put(ThemeController(), permanent: true);
  Get.put(PaymentController(), permanent: true);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Silid',
      theme: AppColors.lightTheme,
      darkTheme: AppColors.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      initialRoute:
          AppRoutes.authWrapper, // Use a named route instead of `home`
      getPages: AppRoutes.pages,
      // builder: (context, child) {
      //   return Scaffold(
      //     body: child, // Renders the current page
      //     floatingActionButton: FloatingActionButton(
      //       onPressed: () {
      //         Get.toNamed('/bug-report');
      //       },
      //       child: Icon(Icons.bug_report),
      //     ),
      //   );
      // },
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

      // ✅ Ensure navigation happens only once
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.find<DataController>().checkUserAndNavigate(user.uid);
      });

      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    });
  }
}
