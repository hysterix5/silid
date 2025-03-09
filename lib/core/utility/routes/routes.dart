import 'package:get/get.dart';
import 'package:silid/core/resources/auth/login.dart';
import 'package:silid/core/views/admin/index.dart';
import 'package:silid/core/views/admin/library.dart';
import 'package:silid/core/views/admin/reports.dart';
import 'package:silid/core/views/newcomer/index.dart';
import 'package:silid/core/views/payment/cancelled.dart';
import 'package:silid/core/views/payment/failed.dart';
import 'package:silid/core/views/payment/success.dart';
import 'package:silid/core/views/misc/report.dart';
import 'package:silid/core/views/student/index.dart';
import 'package:silid/core/views/teacher/index.dart';
import 'package:silid/core/views/teacher/messages.dart';
import 'package:silid/main.dart';

class AppRoutes {
  static const String authWrapper = '/';
  static const String login = '/login';
  static const String teacherDashboard = '/teacher-dashboard';
  static const String studentDashboard = '/student-dashboard';
  static const String admin = '/admin';
  static const String paymentSuccess = '/payment-success';
  static const String paymentFailed = '/payment-failed';
  static const String paymentCancelled = '/payment-cancelled';
  static const String newcomer = '/newcomer';
  static const String library = '/library';
  static const String bugReport = '/bug-report';
  static const String reportPage = '/reports';
  static const String chatList = '/chats';
  static final List<GetPage> pages = [
    GetPage(name: authWrapper, page: () => const AuthWrapper()),
    GetPage(name: login, page: () => LoginPage()),
    GetPage(name: teacherDashboard, page: () => const TeacherIndex()),
    GetPage(name: studentDashboard, page: () => const StudentIndex()),
    GetPage(name: admin, page: () => const AdminPage()),
    GetPage(name: newcomer, page: () => const Newcomer()),
    GetPage(name: paymentSuccess, page: () => SuccessPage()),
    GetPage(name: paymentFailed, page: () => FailedPage()),
    GetPage(name: paymentCancelled, page: () => CancelledPage()),
    GetPage(name: library, page: () => LessonLibrary()),
    GetPage(name: bugReport, page: () => BugReportPage()),
    GetPage(name: reportPage, page: () => BugReports()),
    GetPage(name: chatList, page: () => ChatListScreen()),
  ];
}
