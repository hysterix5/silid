// ignore_for_file: file_names

import 'package:cloud_firestore/cloud_firestore.dart';

class Teacher {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String uniqueCode;
  final String? profileImage;
  final DateTime subscribedUntil;

  Teacher(
      {required this.uid,
      required this.firstName,
      required this.lastName,
      required this.email,
      required this.uniqueCode,
      required this.profileImage,
      required this.subscribedUntil});
  //fetch data from firestore and store to local model
  factory Teacher.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Teacher(
      uid: data['uid'] ?? '', // ✅ Default empty string to prevent null errors
      firstName: data['firstName'] ?? 'Unknown',
      lastName: data['lastName'] ?? 'Unknown',
      email: data['email'] ?? '',
      uniqueCode: data['uniqueCode'] ?? '',
      profileImage: data['profileImage'], // Nullable, no need for default
      subscribedUntil: (data['subscribed_until'] as Timestamp?)?.toDate() ??
          DateTime.now(), // ✅ Default to now if missing
    );
  }
  //fetch data from local and store to firestore
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'uniqueCode': uniqueCode,
      'profileImage': profileImage,
      'subscribed_until': Timestamp.fromDate(
          subscribedUntil), // ✅ Ensure it's stored as a Timestamp
    };
  }
}
