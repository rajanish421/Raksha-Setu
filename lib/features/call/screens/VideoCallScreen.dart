import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import '../../../constants/zego_config.dart';

class VideoCallScreen extends StatelessWidget {
  final String callId;
  final bool isGroup;

  const VideoCallScreen({
    super.key,
    required this.callId,
    required this.isGroup,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final config = isGroup
        ? ZegoUIKitPrebuiltCallConfig.groupVideoCall()
        : ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall();

    return SafeArea(
      child: ZegoUIKitPrebuiltCall(
        appID: ZegoConfig.appId,
        appSign: ZegoConfig.appSign,
        userID: user.uid,
        userName: user.displayName ?? "User",
        callID: callId,
        config: config,
      ),
    );
  }
}
