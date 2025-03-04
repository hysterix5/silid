import 'package:get/get.dart';
import 'package:silid/core/resources/auth/login.dart';
import 'package:silid/core/views/admin/index.dart';
import 'package:silid/core/views/payment/success.dart';
import 'package:silid/core/views/student/index.dart';
import 'package:silid/core/views/teacher/index.dart';
import 'package:silid/main.dart';

class AppRoutes {
  static const String authWrapper = '/';
  static const String login = '/login';
  static const String teacherDashboard = '/teacher-dashboard';
  static const String studentDashboard = '/student-dashboard';
  static const String admin = '/admin';
  static const String paymentSuccess = '/payment-success';

  static final List<GetPage> pages = [
    GetPage(name: authWrapper, page: () => const AuthWrapper()),
    GetPage(name: login, page: () => LoginPage()),
    GetPage(name: teacherDashboard, page: () => const TeacherIndex()),
    GetPage(name: studentDashboard, page: () => const StudentIndex()),
    GetPage(name: admin, page: () => const AdminPage()),
    GetPage(name: paymentSuccess, page: () => SuccessPage()),
  ];
}
