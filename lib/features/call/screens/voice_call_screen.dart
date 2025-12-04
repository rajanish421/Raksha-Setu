import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import '../../../constants/zego_config.dart';

class VoiceCallScreen extends StatefulWidget {
  final String callId;      // unique per call
  final bool isGroup;       // true = group call, false = 1-1

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
  void dispose() {
    FirebaseFirestore.instance.collection("active_calls").doc(widget.callId).update({
      "active": false,
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final userId = user.uid;
    final userName = user.displayName ?? user.email ?? "User_${user.uid.substring(0, 6)}";

    // audio-only configs (we’ll switch to video later very easily)
    final config = widget.isGroup
        ? ZegoUIKitPrebuiltCallConfig.groupVoiceCall()
        : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();

    return Scaffold(
      body: SafeArea(
        child: ZegoUIKitPrebuiltCall(
          appID: ZegoConfig.appId,
          appSign: ZegoConfig.appSign,
          userID: userId,
          userName: userName,
          callID: widget.callId,
          config: config,
        ),
      ),
    );
  }
}
