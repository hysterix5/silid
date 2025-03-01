import 'package:cloud_firestore/cloud_firestore.dart';

class Bookings {
  final String uid;
  final String student;
  final String teacher;
  final DateTime date;
  final Map status;
  final String lesson;
  final String meetingLink;

  Bookings({
    required this.uid,
    required this.student,
    required this.teacher,
    required this.date,
    required this.status,
    required this.lesson,
    required this.meetingLink,
  });

  factory Bookings.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Bookings(
      uid: data['uid'],
      student: data['student'],
      teacher: data['teacher'],
      date: (data['date'] as Timestamp).toDate(),
      status: data['status'],
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
      'status': status,
      'lesson': lesson,
      'meetingLink': meetingLink,
    };
  }
}
