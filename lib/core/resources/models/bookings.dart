import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class Bookings {
  final String uid;
  final String student;
  final String teacher;
  final DateTime date;
  final RxMap<String, dynamic> status; // Make status reactive
  final String lesson;
  final String meetingLink;

  Bookings({
    required this.uid,
    required this.student,
    required this.teacher,
    required this.date,
    required Map<String, dynamic> status,
    required this.lesson,
    required this.meetingLink,
  }) : status = status.obs; // Convert status to an observable RxMap

  factory Bookings.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Bookings(
      uid: data['uid'],
      student: data['student'],
      teacher: data['teacher'],
      date: (data['date'] as Timestamp).toDate(),
      status: Map<String, dynamic>.from(data['status']), // Ensure it's a Map
      lesson: data['lesson'],
      meetingLink: data['meetingLink'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'student': student,
      'teacher': teacher,
      'date': date,
      'status': status, // RxMap auto-converts to Map
      'lesson': lesson,
      'meetingLink': meetingLink,
    };
  }
}
