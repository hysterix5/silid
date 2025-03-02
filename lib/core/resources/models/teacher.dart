// ignore_for_file: file_names

import 'package:cloud_firestore/cloud_firestore.dart';

class Teacher {
  final String uid;
  final String name;
  final String email;
  final String? profileImage;

  Teacher({
    required this.uid,
    required this.name,
    required this.email,
    required this.profileImage,
  });
  //fetch data from firestore and store to local model
  factory Teacher.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Teacher(
      uid: data['uid'],
      name: data['name'],
      email: data['email'],
      profileImage: data['profileImage'],
    );
  }
  //fetch data from local and store to firestore
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'profileImage': profileImage,
    };
  }

  @override
  String toString() {
    return 'Teacher(uid: $uid, name: $name, email: $email)';
  }
}
