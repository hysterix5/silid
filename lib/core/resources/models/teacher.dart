// ignore_for_file: file_names

import 'package:cloud_firestore/cloud_firestore.dart';

class Teacher {
  final String uid;
  final String name;
  final String email;
  final String uniqueCode;
  final String? profileImage;
  final DateTime subscribedUntil;

  Teacher(
      {required this.uid,
      required this.name,
      required this.email,
      required this.uniqueCode,
      required this.profileImage,
      required this.subscribedUntil});
  //fetch data from firestore and store to local model
  factory Teacher.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Teacher(
      uid: data['uid'],
      name: data['name'],
      email: data['email'],
      uniqueCode: data['uniqueCode'],
      profileImage: data['profileImage'],
      subscribedUntil: (data['subscribed_until'] as Timestamp)
          .toDate(), // ✅ Convert Timestamp to DateTime
    );
  }
  //fetch data from local and store to firestore
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'uniqueCode': uniqueCode,
      'profileImage': profileImage,
      'subscribed_until': Timestamp.fromDate(
          subscribedUntil), // ✅ Ensure it's stored as a Timestamp
    };
  }

  @override
  String toString() {
    return 'Teacher(uid: $uid, name: $name, email: $email)';
  }
}
