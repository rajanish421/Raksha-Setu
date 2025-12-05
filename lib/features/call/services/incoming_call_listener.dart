import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/voice_call_screen.dart';
import '../screens/VideoCallScreen.dart';
import 'call_alert_controller.dart';

class IncomingCallListener {
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  static final Set<String> _shownCallIds = {};

  static void start(GlobalKey<NavigatorState> navKey) {
    _sub?.cancel(); // avoid multiple listeners

    final uid = FirebaseAuth.instance.currentUser!.uid;

    _sub = FirebaseFirestore.instance
        .collection("active_calls")
        .where("participants", arrayContains: uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isEmpty) return;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final callId = data["callId"] as String;
        final active = data["active"] == true;
        final startedBy = data["startedBy"] as String;
        final type = data["type"] as String;

        if (!active) continue;
        if (startedBy == uid) continue;              // don't popup on caller
        if (_shownCallIds.contains(callId)) continue;

        final context = navKey.currentContext;
        if (context == null) return;

        _shownCallIds.add(callId);
        CallAlertController.startAlert();
        _showDialog(context, callId, type);
      }
    });
  }

  static void _showDialog(
      BuildContext context, String callId, String callType) {
    final isVideo = callType.contains("video");
    final isGroup = callType.startsWith("group_");

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          isVideo ? "🎥 Secure Video Call" : "🔊 Secure Voice Call",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          isVideo
              ? "A secure video call is incoming.\nJoin now?"
              : "A secure voice call is incoming.\nJoin now?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              CallAlertController.stopAlert();
              Navigator.pop(context);
            },
            child: const Text(
              "Decline",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              CallAlertController.stopAlert();
              Navigator.pop(context);

              if (isVideo) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        VideoCallScreen(callId: callId, isGroup: isGroup),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        VoiceCallScreen(callId: callId, isGroup: isGroup),
                  ),
                );
              }
            },
            child: const Text("Join"),
          ),
        ],
      ),
    );
  }
}
