import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:vibration/vibration.dart';

class CallAlertController {
  static final AssetsAudioPlayer _player = AssetsAudioPlayer.newPlayer();
  static bool _isPlaying = false;

  /// Start ringtone + vibration loop
  static Future<void> startAlert() async {
    if (_isPlaying) return;

    _isPlaying = true;

    // ringtone
    _player.open(
      Audio('assets/ringtones/ringtone.mp3'),
      loopMode: LoopMode.single,
      autoStart: true,
      showNotification: false,
    );

    // vibration loop
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [500, 1000, 800, 1200], intensities: [100, 255, 180]);
    }
  }

  /// Stop vibration + ringtone
  static Future<void> stopAlert() async {
    if (!_isPlaying) return;

    _isPlaying = false;
    _player.stop();
    Vibration.cancel();
  }
}
