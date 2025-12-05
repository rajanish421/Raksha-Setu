import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import '../../../constants/zego_config.dart';
import '../services/call_service.dart';

class VoiceCallScreen extends StatefulWidget {
  final String callId;
  final bool isGroup;

  const VoiceCallScreen({
    super.key,
    required this.callId,
    required this.isGroup,
  });

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {

  @override
  void initState() {
    super.initState();
    _markJoined();
  }

  Future<void> _markJoined() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection("active_calls")
        .doc(widget.callId)
        .update({
      "joined": FieldValue.arrayUnion([uid]),   // for missed-call logic
    });
  }

  @override
  void dispose() {
    // one of the participants will mark call as ended + compute missed users
    CallService.instance.endCall(widget.callId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final userName =
        user.displayName ?? user.email ?? "User_${user.uid.substring(0, 6)}";

    final config = widget.isGroup
        ? ZegoUIKitPrebuiltCallConfig.groupVoiceCall()
        : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();

    return Scaffold(
      body: SafeArea(
        child: ZegoUIKitPrebuiltCall(
          appID: ZegoConfig.appId,
          appSign: ZegoConfig.appSign,
          userID: user.uid,
          userName: userName,
          callID: widget.callId,
          config: config,
        ),
      ),
    );
  }
}
