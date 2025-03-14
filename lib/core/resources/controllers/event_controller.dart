import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EventController extends GetxController {
  Future<void> bookCancelledbyStudent(
      String teacherId, String studentName) async {
    try {
      // Add notification to teacher's notifications subcollection
      await FirebaseFirestore.instance
          .collection('teachers')
          .doc(teacherId)
          .collection('notifications')
          .add({
        'creator': 'System',
        'subject': 'Booking Cancelled',
        'message': '$studentName has cancelled their booking.',
        'created_at': FieldValue.serverTimestamp(),
        'status': false,
      });
    } catch (e) {
      debugPrint("Error cancelling booking: $e");
    }
  }

  Future<void> bookCancelledbyTeacher(
      String studentId, String teacherName) async {
    try {
      // Add notification to teacher's notifications subcollection
      await FirebaseFirestore.instance
          .collection('students')
          .doc(studentId)
          .collection('notifications')
          .add({
        'title': 'Booking Cancelled',
        'message': '$teacherName has cancelled their booking.',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      debugPrint("Error cancelling booking: $e");
    }
  }
}
