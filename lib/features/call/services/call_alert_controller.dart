



import 'package:just_audio/just_audio.dart';
import 'package:vibration/vibration.dart';
import 'dart:developer';

class CallAlertController {
  static final AudioPlayer _player = AudioPlayer();
  static bool _isPlaying = false;

  static Future<void> startAlert() async {
    if (_isPlaying) return;
    _isPlaying = true;

    try {
      log("🔔 Loading ringtone...");

      await _player.setAsset('assets/ringtones/ringtone1.mp3');

      log("🎶 RINGTONE LOADED → PLAYING");

      _player.setLoopMode(LoopMode.one);
      _player.play();
    } catch (e) {
      log("❌ Ringtone error: $e");
    }

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(
        pattern: [300, 900, 500, 1000],
        intensities: [120, 255, 180],
      );
    }
  }

  static Future<void> stopAlert() async {
    if (!_isPlaying) return;

    _isPlaying = false;

    await _player.stop();
    Vibration.cancel();

    log("🔕 Alert stopped.");
  }
}


//
//
// import 'package:just_audio/just_audio.dart';
// import 'package:vibration/vibration.dart';
//
// class CallAlertController {
//   static final AudioPlayer _player = AudioPlayer();
//   static bool _isPlaying = false;
//
//   /// 🔔 Start ringtone + vibration
//   static Future<void> startAlert() async {
//     if (_isPlaying) return;
//     _isPlaying = true;
//
//     try {
//       // Play ringtone in loop
//       await _player.setAsset('assets/ringtones/ringtone.mp3');
//       _player.setLoopMode(LoopMode.one);
//       _player.play();
//     } catch (e) {
//       print("Ringtone error =========================================================================>: $e");
//     }
//
//     // Vibrate pattern like WhatsApp
//     if (await Vibration.hasVibrator() ?? false) {
//       Vibration.vibrate(
//         pattern: [500, 1200, 500, 1200, 600],
//         intensities: [120, 255, 180, 255, 180],
//       );
//     }
//   }
//
//   /// 🔕 Stop ringtone + vibration
//   static Future<void> stopAlert() async {
//     if (!_isPlaying) return;
//     _isPlaying = false;
//
//     await _player.stop();
//     Vibration.cancel();
//   }
// }

//
// // import 'package:vibration/vibration.dart';
// //
// // class CallAlertController {
// //   static bool _isPlaying = false;
// //
// //   static Future<void> startAlert() async {
// //     if (_isPlaying) return;
// //     _isPlaying = true;
// //
// //     if (await Vibration.hasVibrator() ?? false) {
// //       Vibration.vibrate(
// //         pattern: [500, 1000, 800, 1200],
// //         intensities: [100, 255, 180],
// //       );
// //     }
// //   }
// //
// //   static Future<void> stopAlert() async {
// //     if (!_isPlaying) return;
// //
// //     _isPlaying = false;
// //     Vibration.cancel();
// //   }
// // }
