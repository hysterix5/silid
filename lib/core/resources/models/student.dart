// ignore_for_file: non_constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  final String uid;
  final String name;
  final String email;
  final Map<String, dynamic> assignedTeacher;
  final String? profileImage;

  Student({
    required this.uid,
    required this.name,
    required this.email,
    required this.assignedTeacher,
    required this.profileImage,
  });
  //fetch data from firestore and store to local model
  factory Student.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Student(
      uid: data['uid'],
      name: data['name'],
      email: data['email'],
      assignedTeacher: data['assigned_teacher'],
      profileImage: data['profileImage'],
    );
  }
  //fetch data from local and store to firestore
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'assigned_teacher': assignedTeacher,
      'profileImage': profileImage,
    };
  }

  @override
  String toString() {
    return 'Student(uid: $uid, name: $name, email: $email)';
  }
}
