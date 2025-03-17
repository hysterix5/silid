import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class ChatController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  var messages = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  late String chatId;

  void initializeChat(String otherUserId) async {
    isLoading.value = true;
    chatId = await getOrCreateChat(otherUserId);
    fetchMessages();

    // Mark messages as read
    markMessagesAsRead();

    isLoading.value = false;
  }

  Future<String> getOrCreateChat(String otherUserId) async {
    String currentUserId = auth.currentUser?.uid ?? "";

    if (currentUserId.isEmpty) throw Exception("User not authenticated");

    List<String> participants = [currentUserId, otherUserId]..sort();
    String chatId = participants.join("_");

    DocumentSnapshot chatDoc =
        await _firestore.collection("chats").doc(chatId).get();

    if (!chatDoc.exists) {
      await _firestore.collection("chats").doc(chatId).set({
        "participants": participants,
        "createdAt": FieldValue.serverTimestamp(),
      });
    }
    return chatId;
  }

  void fetchMessages() {
    _firestore
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .orderBy("timestamp", descending: true)
        .snapshots()
        .listen((snapshot) {
      messages.value = snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<void> sendMessage(String message) async {
    String senderId = auth.currentUser?.uid ?? "";
    if (message.trim().isEmpty) return;

    await _firestore
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .add({
      "senderId": senderId,
      "message": message.trim(),
      "isRead": false,
      "timestamp": FieldValue.serverTimestamp(),
    });
  }

  void markMessagesAsRead() async {
    String currentUserId = auth.currentUser?.uid ?? "";

    QuerySnapshot unreadMessages = await _firestore
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .where("senderId",
            isNotEqualTo: currentUserId) // Only messages from the other user
        .where("isRead", isEqualTo: false) // Only unread messages
        .get();

    for (var doc in unreadMessages.docs) {
      await doc.reference.update({"isRead": true}); // Mark each message as read
    }
  }
}
