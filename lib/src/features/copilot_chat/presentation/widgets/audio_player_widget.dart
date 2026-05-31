import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final int durationInSeconds;

  const AudioPlayerWidget({
    super.key,
    required this.audioUrl,
    required this.durationInSeconds,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _duration = Duration(seconds: widget.durationInSeconds);
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          _duration = newDuration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          _position = newPosition;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource(widget.audioUrl));
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  /// BUG FIX (2026-05-30): Fixed layout constraint contradiction. The outer
  /// `Row` contained both `MainAxisSize.min` (from bubble) AND `Expanded`
  /// (for the slider), which is mutually exclusive. Removed the outer Row's
  /// `MainAxisSize.min` constraint so the slider's `Expanded` can size
  /// correctly. Also replaced static `Colors.grey[200]` with a theme-aware
  /// surface color.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: _playPause,
          ),
          Expanded(
            child: Slider(
              value: _position.inSeconds.toDouble(),
              max: _duration.inSeconds.toDouble(),
              onChanged: (value) async {
                final position = Duration(seconds: value.toInt());
                await _audioPlayer.seek(position);
              },
            ),
          ),
          Text(_formatDuration(_position)),
          const SizedBox(width: 8),
          Text(_formatDuration(_duration)),
        ],
      ),
    );
  }
}

