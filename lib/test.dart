import 'dart:io';
import 'package:flutter/material.dart';

import 'features/chat/services/voice_service.dart';

class VoiceTestScreen extends StatefulWidget {
  const VoiceTestScreen({super.key});

  @override
  State<VoiceTestScreen> createState() => _VoiceTestScreenState();
}

class _VoiceTestScreenState extends State<VoiceTestScreen> {
  String status = "Idle";
  String? recordedPath;

  Future<void> startRecording() async {
    final ok = await VoiceService.instance.startRecording();
    setState(() => status = ok ? "Recording..." : "Permission denied");
  }

  Future<void> stopRecording() async {
    final File? file = await VoiceService.instance.stopRecording();
    setState(() {
      if (file != null) {
        recordedPath = file.path;
        status = "Recorded Successfully ✔\nPath:\n${file.path}";
      } else {
        status = "Recording failed ❌";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🎙 Voice Recorder Test")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              status,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: startRecording,
              child: const Text("Start Recording 🎤"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: stopRecording,
              child: const Text("Stop Recording ⏹"),
            ),

            const SizedBox(height: 20),

            if (recordedPath != null)
              ElevatedButton(
                onPressed: () {
                  print("FILE PATH -> $recordedPath");
                },
                child: const Text("Print File Path 🔍"),
              ),
          ],
        ),
      ),
    );
  }
}
