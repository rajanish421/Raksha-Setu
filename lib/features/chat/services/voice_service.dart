import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';




class VoiceService {
  VoiceService._internal();
  static final VoiceService instance = VoiceService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  String? _filePath;

  /// Request mic permission
  Future<bool> _requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Start recording
  Future<bool> startRecording() async {
    if (!await _requestPermission()) return false;

    if (await _recorder.isRecording()) return true;

    final dir = await getTemporaryDirectory();
    _filePath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: _filePath!,
    );

    return true;
  }

  /// Stop recording
  Future<File?> stopRecording() async {
    final path = await _recorder.stop();
    if (path == null) return null;
    return File(path);
  }

  /// Cancel recording
  Future<void> cancelRecording() async {
    await _recorder.stop();
    _filePath = null;
  }

  Future<bool> isRecording() => _recorder.isRecording();
}
