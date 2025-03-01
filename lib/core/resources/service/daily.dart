import 'package:flutter/material.dart';
import 'dart:js' as js;
import 'dart:html' as html;

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
        print("Error calling initializeDaily: $e");
      }
    });

    // Listen for messages from JavaScript (Daily events)
    html.window.onMessage.listen((event) {
      if (event.data is String) {
        final String data = event.data;
        print("Received event from Daily: $data");

        if (data.contains('"type":"left-meeting"')) {
          _handleParticipantLeft();
        } else if (data.contains('"type":"meeting-ended"')) {
          _handleMeetingEnded();
        }
      }
    });
  }

  void _handleParticipantLeft() {
    print("A participant has left.");
    if (mounted) {
      Navigator.pop(context); // ✅ Pop the screen when user leaves
    }
  }

  void _handleMeetingEnded() {
    print("The meeting has ended.");
    if (mounted) {
      Navigator.pop(context); // ✅ Pop the screen when meeting ends
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
