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
  void dispose() {
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
