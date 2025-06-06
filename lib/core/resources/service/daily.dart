// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'package:flutter/material.dart';
import 'dart:js' as js;
import 'dart:html' as html;

import 'package:get/get.dart';
import 'package:silid/core/views/misc/post_call.dart';

class MeetingScreen extends StatefulWidget {
  final String roomUrl;
  final String userName;

  const MeetingScreen(
      {super.key, required this.roomUrl, required this.userName});

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  @override
  void initState() {
    super.initState();

    // Initialize Daily video call with a delay to ensure JS is loaded
    Future.delayed(const Duration(seconds: 2), () {
      try {
        js.context
            .callMethod('initializeDaily', [widget.roomUrl, widget.userName]);
      } catch (e) {
        debugPrint("Error calling initializeDaily: $e");
      }
    });

    // Listen for messages from JavaScript (Daily events)
    html.window.onMessage.listen((event) {
      if (event.data is String) {
        final String data = event.data;
        debugPrint("Received event from Daily: $data");

        if (data.contains('"type":"left-meeting"')) {
          _handleParticipantLeft();
        } else if (data.contains('"type":"meeting-ended"')) {
          _handleMeetingEnded();
        }
      }
    });
  }

  void _handleParticipantLeft() {
    debugPrint("A participant has left.");
    Get.to(() => PostCallScreen());
  }

  void _handleMeetingEnded() {
    debugPrint("The meeting has ended.");
    Get.to(() => PostCallScreen());
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}
