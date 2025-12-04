import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CallScreen extends StatelessWidget {
  final String callId;
  final String userId;
  final String userName;

  const CallScreen({
    super.key,
    required this.callId,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final appId = int.tryParse(dotenv.env["ZEGO_APP_ID"] ?? "") ?? 0;
    final appSign = dotenv.env["ZEGO_APP_SIGN"] ?? "";

    return ZegoUIKitPrebuiltCall(
      appID: appId,
      appSign: appSign,
      userID: userId,
      userName: userName,
      callID: callId,
      config: ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall(),
    );
  }
}
