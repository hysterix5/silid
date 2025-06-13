// ignore_for_file: non_constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final List<Map<String, dynamic>> assignedTeacher;
  final String? profileImage;

  Student({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.assignedTeacher = const [], // default empty list
    this.profileImage,
  });

  factory Student.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Student(
      uid: data['uid'],
      firstName: data['firstName'],
      lastName: data['lastName'],
      email: data['email'],
      assignedTeacher: List<Map<String, dynamic>>.from(
        data['assigned_teacher'] ?? [],
      ),
      profileImage: data['profileImage'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'assigned_teacher': assignedTeacher,
      'profileImage': profileImage,
    };
  }

  Student copyWith({
    String? uid,
    String? firstName,
    String? lastName,
    String? email,
    List<Map<String, dynamic>>? assignedTeacher,
    String? profileImage,
  }) {
    return Student(
      uid: uid ?? this.uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      assignedTeacher: assignedTeacher ?? this.assignedTeacher,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}
