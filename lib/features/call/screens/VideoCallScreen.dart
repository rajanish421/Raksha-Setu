import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import '../../../constants/zego_config.dart';
import '../services/call_service.dart';

class VideoCallScreen extends StatefulWidget {
  final String callId;
  final bool isGroup;

  const VideoCallScreen({
    super.key,
    required this.callId,
    required this.isGroup,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {

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
        ? ZegoUIKitPrebuiltCallConfig.groupVideoCall()
        : ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall();

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
