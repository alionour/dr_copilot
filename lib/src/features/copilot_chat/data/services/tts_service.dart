import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:dr_copilot/src/core/helper/api_key_helper.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dartz/dartz.dart';

/// Service to handle Text-to-Speech using Deepgram Aura API.
class TtsService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final String _baseUrl = 'https://api.deepgram.com/v1/speak';

  // Default model - can be made configurable
  // models: aura-asteria-en (female), aura-orion-en (male), etc.
  final String _model = 'aura-asteria-en';

  // Flag to prevent playback if stopped immediately after checking
  bool _isStopped = false;

  TtsService();

  /// Synthesizes text to speech and plays it immediately.
  /// Returns a stream of player state to track when speaking finishes.
  Future<Either<Failure, void>> speak(String text) async {
    _isStopped = false; // Reset stop flag on new speak request
    try {
      final apiKey = ApiKeyHelper.deepgramKey;
      if (apiKey.isEmpty) {
        return Left(ApiKeyFailure('Deepgram API key is missing.'));
      }

      final uri = Uri.parse('$_baseUrl?model=$_model');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Token $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode == 200) {
        // Check if stopped while waiting for network
        if (_isStopped) {
          return const Right(null); // Return silently if stopped
        }

        final bytes = response.bodyBytes;
        // Play the audio bytes
        await _audioPlayer.play(BytesSource(bytes));
        return const Right(null);
      } else {
        return Left(ServerFailure(
            'Deepgram TTS failed: ${response.statusCode} - ${response.body}',
            response.statusCode));
      }
    } catch (e) {
      return Left(ServerFailure('TTS Error: $e', 500));
    }
  }

  /// Stops any currently playing audio.
  Future<void> stop() async {
    _isStopped = true; // Set flag to prevent pending playbacks
    await _audioPlayer.stop();
  }

  /// Helper to check if currently playing
  Stream<PlayerState> get playerStateStream =>
      _audioPlayer.onPlayerStateChanged;

  void dispose() {
    _isStopped = true;
    _audioPlayer.dispose();
  }
}
