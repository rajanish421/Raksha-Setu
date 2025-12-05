import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/voice_call_screen.dart';
import '../screens/VideoCallScreen.dart';

class CallService {
  CallService._internal();
  static final CallService instance = CallService._internal();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _newCallDoc() {
    return _firestore.collection("active_calls").doc();
  }




  /// Fetch all member UIDs of a group
  Future<List<String>> _getGroupMembers(String groupId) async {
    final snap =
    await _firestore.collection("groups").doc(groupId).get();
    final data = snap.data() ?? {};
    final List<dynamic> raw = data["members"] ?? [];
    return raw.map((e) => e.toString()).toList();
  }

  // ---------- GROUP VOICE ----------
  Future<void> startGroupVoiceCall({
    required BuildContext context,
    required String groupId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final members = await _getGroupMembers(groupId);
    if (!members.contains(user.uid)) members.add(user.uid);

    final docRef = _newCallDoc();

    await docRef.set({
      "callId": docRef.id,
      "groupId": groupId,
      "type": "group_voice",
      "startedBy": user.uid,
      "participants": members,
      "active": true,
      "createdAt": FieldValue.serverTimestamp(),
      "endedAt": null,
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VoiceCallScreen(
          callId: docRef.id,
          isGroup: true,
        ),
      ),
    );
  }

  // ---------- 1–1 VOICE ----------
  Future<void> startP2PVoiceCall({
    required BuildContext context,
    required String groupId,
    required String peerId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _newCallDoc();

    await docRef.set({
      "callId": docRef.id,
      "groupId": groupId,
      "type": "p2p_voice",
      "startedBy": user.uid,
      "participants": [user.uid, peerId],
      "active": true,
      "createdAt": FieldValue.serverTimestamp(),
      "endedAt": null,
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VoiceCallScreen(
          callId: docRef.id,
          isGroup: false,
        ),
      ),
    );
  }

  // ---------- GROUP VIDEO ----------
  Future<void> startGroupVideoCall({
    required BuildContext context,
    required String groupId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final members = await _getGroupMembers(groupId);
    if (!members.contains(user.uid)) members.add(user.uid);

    final docRef = _newCallDoc();

    await docRef.set({
      "callId": docRef.id,
      "groupId": groupId,
      "type": "group_video",
      "startedBy": user.uid,
      "participants": members,
      "active": true,
      "createdAt": FieldValue.serverTimestamp(),
      "endedAt": null,
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoCallScreen(
          callId: docRef.id,
          isGroup: true,
        ),
      ),
    );
  }

  // ---------- 1–1 VIDEO ----------
  Future<void> startP2PVideoCall({
    required BuildContext context,
    required String groupId,
    required String peerId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _newCallDoc();

    await docRef.set({
      "callId": docRef.id,
      "groupId": groupId,
      "type": "p2p_video",
      "startedBy": user.uid,
      "participants": [user.uid, peerId],
      "active": true,
      "createdAt": FieldValue.serverTimestamp(),
      "endedAt": null,
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoCallScreen(
          callId: docRef.id,
          isGroup: false,
        ),
      ),
    );
  }

  // ---------- END CALL (for logs & to stop future popups) ----------
  Future<void> endCall(String callId) async {
    final docRef = _firestore.collection('active_calls').doc(callId);
    final snap = await docRef.get();
    if (!snap.exists) return;

    final data = snap.data()!;
    final List participants = (data['participants'] ?? []) as List;
    final List joined = (data['joined'] ?? []) as List;

    // users who never joined = missed
    final List missed = participants
        .where((p) => !joined.contains(p))
        .toList();

    await docRef.update({
      "active": false,
      "endedAt": FieldValue.serverTimestamp(),
      "missed": missed,
    });
  }

}
