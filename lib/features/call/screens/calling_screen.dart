import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../screens/voice_call_screen.dart';
import '../services/call_alert_controller.dart';
import 'VideoCallScreen.dart';

class CallingScreen extends StatefulWidget {
  final String callId;
  final bool isVideo;

  const CallingScreen({
    super.key,
    required this.callId,
    required this.isVideo,
  });

  @override
  State<CallingScreen> createState() => _CallingScreenState();
}

class _CallingScreenState extends State<CallingScreen> {
  late StreamSubscription subscription;

  @override
  void initState() {
    super.initState();
    CallAlertController.startAlert();


    subscription = FirebaseFirestore.instance
        .collection("active_calls")
        .doc(widget.callId)
        .snapshots()
        .listen((snap) {
      final data = snap.data();
      if (data == null) return;

      final active = data["active"] ?? true;
      final joinedCount = data["joinedCount"] ?? 1;

      if (!active) {
        CallAlertController.stopAlert();
        if (mounted) Navigator.pop(context);
      } else if (joinedCount >= 2) {
        _joinCall();
      }
    });


    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) Navigator.pop(context);
      CallAlertController.stopAlert();
    });
  }

  @override
  void dispose() {
    CallAlertController.stopAlert();
    subscription.cancel(); // 👈 FIXED
    super.dispose();
  }

  void _joinCall() {
    CallAlertController.stopAlert();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => widget.isVideo
            ? VideoCallScreen(callId: widget.callId, isGroup: true)
            : VoiceCallScreen(callId: widget.callId, isGroup: true),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.isVideo ? Icons.videocam : Icons.phone, size: 90, color: Colors.white),
            const SizedBox(height: 20),
            const Text("Calling...", style: TextStyle(color: Colors.white, fontSize: 24)),
            const SizedBox(height: 50),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                CallAlertController.stopAlert();
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            )
          ],
        ),
      ),
    );
  }
}
