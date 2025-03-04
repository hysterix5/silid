// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DailyController extends GetxController {
  Future<String?> createDailyRoom() async {
    const String baseUrl = "https://api.daily.co/v1/rooms";
    const String apiKey =
        "6837625f7f0f2be853170370eef18b99aaa5889cbb4d4b10919d319a22f58a63";

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "name":
              'silid_${DateTime.now().millisecondsSinceEpoch}', // Unique room name
          "privacy":
              "public", // Can be "private" if you want users to be invited manually
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String roomUrl = data["url"]; // Print the URL for testing
        return roomUrl;
      } else {
        debugPrint("❌ Failed to create room: ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Error creating room: $e");
      return null;
    }
  }

  Future<void> deleteDailyRoom(String meetingLink) async {
    // Extract room name from the URL (assuming format: "https://yourdomain.daily.co/roomName")
    Uri uri = Uri.parse(meetingLink);
    String roomName = uri.pathSegments.last; // Gets the last part of the URL

    String apiKey =
        "6837625f7f0f2be853170370eef18b99aaa5889cbb4d4b10919d319a22f58a63"; // Replace with your Daily.co API Key
    String url = "https://api.daily.co/v1/rooms/$roomName";

    try {
      var response = await http.delete(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        debugPrint("Meeting room deleted successfully");
      } else {
        debugPrint("Failed to delete meeting room: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error deleting meeting room: $e");
    }
  }
}
