import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../chat/services/message_service.dart';
import '../../chat/services/encryption_service.dart'; // just to show dependency; optional
import '../screens/calling_screen.dart';
import '../screens/voice_call_screen.dart';
import '../screens/VideoCallScreen.dart';

class CallService {
  CallService._internal();
  static final CallService instance = CallService._internal();

  final _auth = FirebaseAuth.instance;

  // Build a deterministic ID for group call
  String buildGroupCallId(String groupId) => "group_$groupId";

  // Build deterministic ID for 1-1 call inside a group
  String buildP2PCallId(String groupId, String uid1, String uid2) {
    final list = [uid1, uid2]..sort();
    return "g_${groupId}_${list[0]}_${list[1]}";
  }

  // ---------- START GROUP VOICE CALL ----------
  Future<void> startGroupVoiceCall({
    required BuildContext context,
    required String groupId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final callId = buildGroupCallId(groupId);

    // 👇 CREATE DATABASE FLAG SO OTHERS KNOW A CALL EXISTS
    await FirebaseFirestore.instance.collection("active_calls").doc(callId).set({
      "callId": callId,
      "groupId": groupId,
      "type": "group",
      "startedBy": _auth.currentUser!.uid,
      "active": true,
      "timestamp": DateTime.now(),
    });

    // NEW: show Calling UI before opening Zego screen -- new for ringtone/vibration
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (_) => CallingScreen(callId: callId, isVideo: false)),
    // );

    print("===================================---------------------------------======================================");

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


  // listen
  Stream<QueryDocumentSnapshot<Map<String, dynamic>>?> listenGroupCall(String groupId) {
    return FirebaseFirestore.instance
        .collection("active_calls")
        .where("groupId", isEqualTo: groupId)
        .where("active", isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.isNotEmpty ? snap.docs.first : null)
        .where((doc) => doc != null);
  }


  // for video call

  Future<void> startGroupVideoCall({
    required BuildContext context,
    required String groupId,
  }) async {
    final callId = buildGroupCallId(groupId);

    await FirebaseFirestore.instance.collection("active_calls").doc(callId).set({
      "callId": callId,
      "groupId": groupId,
      "type": "group_video",
      "startedBy": _auth.currentUser!.uid,
      "active": true,
      "timestamp": DateTime.now(),
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoCallScreen(callId: callId, isGroup: true),
      ),
    );
  }

  Future<void> startP2PVideoCall({
    required BuildContext context,
    required String groupId,
    required String peerId,
  }) async {
    final callId = buildP2PCallId(groupId, _auth.currentUser!.uid, peerId);

    await FirebaseFirestore.instance.collection("active_calls").doc(callId).set({
      "callId": callId,
      "groupId": groupId,
      "type": "p2p_video",
      "startedBy": _auth.currentUser!.uid,
      "active": true,
      "timestamp": DateTime.now(),
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoCallScreen(callId: callId, isGroup: false),
      ),
    );
  }



  // ---------- START 1-1 VOICE CALL (inside same group) ----------
  Future<void> startP2PVoiceCall({
    required BuildContext context,
    required String groupId,
    required String peerId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final callId = buildP2PCallId(groupId, user.uid, peerId);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VoiceCallScreen(
          callId: callId,
          isGroup: false,
        ),
      ),
    );
  }
}
