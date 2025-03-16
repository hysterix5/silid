import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class GroupBookings {
  final String uid;
  final List<String> students; // Explicitly define as List<String>
  final String teacher;
  final DateTime date;
  final RxMap<String, dynamic> status; // Make status reactive
  final String lesson;
  final String meetingLink;

  GroupBookings({
    required this.uid,
    required this.students,
    required this.teacher,
    required this.date,
    required Map<String, dynamic> status,
    required this.lesson,
    required this.meetingLink,
  }) : status = status.obs; // Convert status to an observable RxMap

  factory GroupBookings.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return GroupBookings(
      uid: data['uid'],
      students:
          List<String>.from(data['students']), // Ensure it's a List<String>
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
      'students': students, // Ensure key is correctly named 'students'
      'teacher': teacher,
      'date': date,
      'status': status, // RxMap auto-converts to Map
      'lesson': lesson,
      'meetingLink': meetingLink,
    };
  }
}
