import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:raksha_setu/features/call/screens/voice_call_screen.dart';

import '../../../main.dart';

class CallNotificationService {
  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'call_channel',
          channelName: 'Incoming Calls',
          channelDescription: 'Call notifications',
          defaultColor: Colors.green,
          importance: NotificationImportance.Max,
          ledColor: Colors.white,
          locked: true,
          channelShowBadge: true,
          defaultRingtoneType: DefaultRingtoneType.Ringtone,
        )
      ],
    );

    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceived,
    );
  }

  static Future<void> showIncomingCall({
    required String callerName,
    required String callId,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 99,
        channelKey: 'call_channel',
        title: "📞 Incoming Secure Call",
        body: callerName,
        category: NotificationCategory.Call,
        wakeUpScreen: true,
        autoDismissible: false,
        fullScreenIntent: true,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'ACCEPT',
          label: 'Accept',
          color: Colors.green,
        ),
        NotificationActionButton(
          key: 'DECLINE',
          label: 'Decline',
          color: Colors.red,
          isDangerousOption: true,
        )
      ],
    );
  }

  static Future<void> onActionReceived(ReceivedAction action) async {
    if (action.buttonKeyPressed == 'ACCEPT') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => VoiceCallScreen(
            callId: "placeholder", // TODO: connect from firestore
            isGroup: true,
          ),
        ),
      );
    } else {
      AwesomeNotifications().dismiss(99);
    }
  }
}
