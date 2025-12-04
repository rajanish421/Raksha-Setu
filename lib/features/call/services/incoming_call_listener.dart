import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/VideoCallScreen.dart';
import '../screens/voice_call_screen.dart';
import 'call_alert_controller.dart';

class IncomingCallListener {
  static bool _isDialogShown = false; // prevent repeat popup
  static String? _lastCallId; // prevent reopening same call

  /// Start global listener
  static void start(GlobalKey<NavigatorState> navKey) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    FirebaseFirestore.instance
        .collection("groups")
        .where("members", arrayContains: uid)
        .snapshots()
        .listen((groupsSnapshot) {
      if (groupsSnapshot.docs.isEmpty) return;

      final groupIds = groupsSnapshot.docs.map((e) => e.id).toList();

      FirebaseFirestore.instance
          .collection("active_calls")
          .where("active", isEqualTo: true)
          .snapshots()
          .listen((callSnap) {
        if (callSnap.docs.isEmpty) return;

        final callData = callSnap.docs.first.data();

        final callId = callData["callId"];
        final groupId = callData["groupId"];
        final startedBy = callData["startedBy"];
        final callType = callData["type"]; // 👈 NEW

        // only users from the same group should get popup
        if (!groupIds.contains(groupId)) return;

        // don't popup on caller device
        if (startedBy == uid) return;

        // avoid repeat dialogs for same call
        if (_lastCallId == callId && _isDialogShown) return;

        final context = navKey.currentContext;
        if (context == null) return;

        _lastCallId = callId;
        _isDialogShown = true;

        CallAlertController.startAlert();  // 🔔 start ringtone


        _showIncomingCallUI(context, callId, groupId, callType);
      });
    });
  }

  /// Popup UI → Detects Voice or Video
  static void _showIncomingCallUI(
      BuildContext context, String callId, String groupId, String callType) {

    final isVideo = callType == "group_video" || callType == "p2p_video";

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          isVideo ? "🎥 Secure Video Call" : "🔊 Secure Voice Call",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          isVideo
              ? "A secure video call is active.\nJoin now?"
              : "A secure voice call is active.\nJoin now?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _isDialogShown = false;

              CallAlertController.stopAlert();


              Navigator.pop(context);
            },
            child: const Text("Decline", style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
            ),
            onPressed: () {

              CallAlertController.stopAlert();


              Navigator.pop(context);
              _isDialogShown = false;

              // 👉 Route based on call type
              if (isVideo) {
                _openVideo(context, callId);
              } else {
                _openVoice(context, callId);
              }
            },
            child: const Text("Join"),
          ),
        ],
      ),
    );
  }

  /// Route to screens
  static void _openVoice(BuildContext context, String callId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VoiceCallScreen(
          callId: callId,
          isGroup: true,
        ),
      ),
    );
  }

  static void _openVideo(BuildContext context, String callId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoCallScreen(
          callId: callId,
          isGroup: true,
        ),
      ),
    );
  }
}
