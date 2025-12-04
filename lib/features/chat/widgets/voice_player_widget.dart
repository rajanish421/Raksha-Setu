import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../constants/app_colors.dart';

class VoicePlayerWidget extends StatefulWidget {
  final String url;

  const VoicePlayerWidget({super.key, required this.url});

  @override
  State<VoicePlayerWidget> createState() => _VoicePlayerWidgetState();
}

class _VoicePlayerWidgetState extends State<VoicePlayerWidget> {
  late AudioPlayer _player;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();

    _setupAudio();

    // Listen for position updates
    _player.positionStream.listen((pos) {
      setState(() => _position = pos);
    });

    // Listen for play/pause/end
    _player.playerStateStream.listen((state) {
      final playing = state.playing;
      final completed = state.processingState == ProcessingState.completed;

      setState(() {
        _isPlaying = playing;
        if (completed) {
          _player.seek(Duration.zero);
          _position = Duration.zero;
        }
      });
    });
  }

  Future<void> _setupAudio() async {
    try {
      await _player.setUrl(widget.url);

      // Listen for duration update (instead of durationFuture)
      _player.durationStream.listen((d) {
        if (d != null) {
          setState(() => _duration = d);
        }
      });
    } catch (e) {
      print("Error loading audio: $e");
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _format(Duration d) {
    return "${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_duration.inMilliseconds == 0)
        ? 0.0
        : _position.inMilliseconds / _duration.inMilliseconds;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _isPlaying ? _player.pause() : _player.play(),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.accent.withOpacity(0.9),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Progress bar
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2.5,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              ),
              child: Slider(
                min: 0,
                max: 1,
                value: progress.clamp(0, 1),
                onChanged: (value) {
                  final newPosition = Duration(
                      milliseconds:
                      (value * _duration.inMilliseconds).toInt());
                  _player.seek(newPosition);
                },
              ),
            ),
          ),

          // Duration label
          Text(
            _format(_position),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
