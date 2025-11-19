import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'abstract_speech_recognition_service.dart';
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:flutter/foundation.dart';

class SpeechRecognitionService implements AbstractSpeechRecognitionService {
  AudioRecorder? _audioRecorder;
  WebSocketChannel? _channel;
  StreamSubscription? _webSocketSubscription;
  StreamSubscription? _deepgramSubscription;
  StreamController<String>? _recognitionController;
  
  // Track the last transcript to detect spurious isFinal events
  String _lastTranscript = '';
  DateTime? _lastTranscriptTime;
  
  // Completer to track when final transcript is received
  Completer<String>? _finalTranscriptCompleter;
  
  // Track initialization state
  bool _isInitialized = false;
  
  // Current language for speech recognition
  String _currentLanguage = 'en-US';

  final String _deepgramApiKey;

  SpeechRecognitionService({required String deepgramApiKey})
      : _deepgramApiKey = deepgramApiKey;
  
  // Method to update language
  void setLanguage(String languageCode) {
    // Map Flutter locale codes to Deepgram language codes
    // Based on https://developers.deepgram.com/docs/language
    switch (languageCode) {
      case 'ar':
        // Deepgram nova-2 does NOT support Arabic
        // Only base, enhanced, whisper models support limited languages
        _currentLanguage = 'ar'; 
        break;
      case 'en':
        _currentLanguage = 'en';
        break;
      case 'fr':
        _currentLanguage = 'fr';
        break;
      case 'es':
        _currentLanguage = 'es';
        break;
      case 'de':
        _currentLanguage = 'de';
        break;
      default:
        _currentLanguage = 'en';
    }
    
    debugPrint('[Speech] Language changed to: $_currentLanguage');
    
    // Reset initialization to force reconnection with new language
    if (_isInitialized) {
      debugPrint('[Speech] Resetting connection for language change');
      _isInitialized = false;
      _deepgramSubscription?.cancel();
      _deepgramSubscription = null;
      _channel?.sink.close();
      _channel = null;
    }
  }
  @override
  Future<Either<Failure, bool>> initialize() async {
    if (_deepgramApiKey.isEmpty) {
      debugPrint('[Speech] ERROR: Deepgram API key is empty!');
      return Left(ApiKeyFailure('Deepgram API key is not provided. Please set the DEEPGRAM_KEY environment variable.'));
    }
    
    // If already initialized and channel is still active, return success
    if (_isInitialized && _channel != null) {
      debugPrint('[Speech] Already initialized, reusing existing connection');
      return const Right(true);
    }
    
    // Clean up any existing connections before reinitializing
    if (_channel != null) {
      debugPrint('[Speech] Cleaning up existing connection before reinitializing');
      try {
        await _deepgramSubscription?.cancel();
        _deepgramSubscription = null;
        await _channel?.sink.close();
        _channel = null;
      } catch (e) {
        debugPrint('[Speech] Error cleaning up: $e');
      }
    }
    
    debugPrint('[Speech] Initializing with API key: ${_deepgramApiKey.substring(0, 8)}...');
    
    try {
      // Create a new AudioRecorder instance if needed
      _audioRecorder ??= AudioRecorder();
      
      final hasRecorderPermission = await _audioRecorder!.hasPermission();
      debugPrint('[Speech] Microphone permission: $hasRecorderPermission');

      if (hasRecorderPermission) {
        // Use basic nova-2 model with English
        // For Arabic/other languages, user needs to speak English or use another service
        final uri = Uri.parse(
            'wss://api.deepgram.com/v1/listen?'
            'encoding=linear16&'
            'sample_rate=16000&'
            'language=en&'
            'model=nova-2&'
            'interim_results=true&'
            'punctuate=true&'
            'endpointing=1000');
        debugPrint('[Speech] Connecting to Deepgram WebSocket with nova-2 model (English only)');
        _channel = IOWebSocketChannel.connect(
          uri,
          protocols: ['token', _deepgramApiKey],
        );
        await _channel!.ready;
        debugPrint('[Speech] WebSocket connected successfully');
        
        // Set up the Deepgram response listener once during initialization
        _setupDeepgramListener();
        
        _isInitialized = true;
        return const Right(true);
      } else {
        debugPrint('[Speech] Requesting microphone permission...');
        final permissionStatus = await Permission.microphone.request();
        if (permissionStatus.isGranted) {
          // Use basic nova-2 model with English
          // For Arabic/other languages, user needs to speak English or use another service
          final uri = Uri.parse(
              'wss://api.deepgram.com/v1/listen?'
              'encoding=linear16&'
              'sample_rate=16000&'
              'language=en&'
              'model=nova-2&'
              'interim_results=true&'
              'punctuate=true&'
              'endpointing=1000');
          debugPrint('[Speech] Connecting to Deepgram WebSocket with nova-2 model (English only)');
          _channel = IOWebSocketChannel.connect(
            uri,
            protocols: ['token', _deepgramApiKey],
          );
          await _channel!.ready;
          debugPrint('[Speech] WebSocket connected successfully');
          
          // Set up the Deepgram response listener once during initialization
          _setupDeepgramListener();
          
          _isInitialized = true;
          return const Right(true);
        } else {
          debugPrint('[Speech] Microphone permission denied');
          return Left(PermissionFailure('Microphone permission denied'));
        }
      }
    } catch (e) {
      debugPrint('[Speech] Initialization failed: $e');
      // Clean up on error
      _isInitialized = false;
      _deepgramSubscription?.cancel();
      _deepgramSubscription = null;
      _channel = null;
      return Left(ServerFailure(
          'Failed to initialize speech recognition: ${e.toString()}', 500));
    }
  }

  void _setupDeepgramListener() {
    _deepgramSubscription = _channel!.stream.listen(
      (message) {
        try {
          final Map<String, dynamic> deepgramResponse = json.decode(message);
          final String? transcript = deepgramResponse['channel']?['alternatives']?[0]?['transcript'];
          final bool isFinal = deepgramResponse['is_final'] ?? false;
          final bool speechFinal = deepgramResponse['speech_final'] ?? false;

          debugPrint('[Speech] Received - transcript: "$transcript", isFinal: $isFinal, speechFinal: $speechFinal');

          if (transcript != null && transcript.isNotEmpty) {
            // Always update to the latest transcript (including interim results)
            _lastTranscript = transcript;
            _lastTranscriptTime = DateTime.now();
            debugPrint('[Speech] Updated _lastTranscript to: "$_lastTranscript"');

            // Emit for real-time display
            _recognitionController?.add(transcript);

            // If we receive an isFinal transcript and completer is waiting, complete it
            if (isFinal && _finalTranscriptCompleter != null && !_finalTranscriptCompleter!.isCompleted) {
              debugPrint('[Speech] Completing with isFinal transcript: "$transcript"');
              _finalTranscriptCompleter!.complete(transcript);
            }

            // Mark as final if needed
            if (speechFinal && transcript.trim().isNotEmpty) {
              _recognitionController?.add('__FINAL__:$transcript');
            }
          } else if (isFinal && _lastTranscript.isNotEmpty) {
            // Empty transcript with isFinal - might be end of speech
            final timeSinceLastTranscript = _lastTranscriptTime != null
                ? DateTime.now().difference(_lastTranscriptTime!)
                : Duration.zero;
            if (timeSinceLastTranscript.inMilliseconds > 1500) {
              _recognitionController?.add('__FINAL__:$_lastTranscript');
            }
            
            // Complete with last transcript if waiting
            if (_finalTranscriptCompleter != null && !_finalTranscriptCompleter!.isCompleted) {
              debugPrint('[Speech] Completing with _lastTranscript: "$_lastTranscript"');
              _finalTranscriptCompleter!.complete(_lastTranscript);
            }
          }
        } catch (e) {
          // Intentionally ignoring problematic events (like VAD events or malformed JSON)
          debugPrint('[Speech] Error parsing message: $e');
        }
      },
      onError: (error) {
        debugPrint('[Speech] WebSocket error: $error');
        _recognitionController?.addError(error);
        if (_finalTranscriptCompleter != null && !_finalTranscriptCompleter!.isCompleted) {
          _finalTranscriptCompleter!.completeError(error);
        }
      },
      onDone: () {
        debugPrint('[Speech] WebSocket done');
        _recognitionController?.close();
        _channel = null;
        _deepgramSubscription = null;
        if (_finalTranscriptCompleter != null && !_finalTranscriptCompleter!.isCompleted) {
          _finalTranscriptCompleter!.complete(_lastTranscript);
        }
      },
    );
  }

  @override
  Future<Either<Failure, bool>> startListening() async {
    try {
      if (_channel == null || !_isInitialized) {
        // Re-initialize if channel is null or not initialized
        final initResult = await initialize();
        if (initResult.isLeft()) {
          return Left(ServerFailure('Failed to re-initialize WebSocketChannel.', 500));
        }
      }

      // Ensure audio recorder exists
      _audioRecorder ??= AudioRecorder();

      if (await _audioRecorder!.isRecording()) {
        return const Right(true); // Already listening
      }

      // Reset tracking variables
      _lastTranscript = '';
      _lastTranscriptTime = null;
      _finalTranscriptCompleter = null;

      // Use broadcast stream controller so multiple listeners can subscribe
      _recognitionController = StreamController<String>.broadcast();

      // Start recording audio stream
      final audioStream = await _audioRecorder!.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      // Send audio data to Deepgram
      _webSocketSubscription = audioStream.listen(
        (audioChunk) {
          _channel?.sink.add(audioChunk);
          // Log occasionally to verify audio is being sent
          if (DateTime.now().millisecond % 500 == 0) {
            debugPrint('[Speech] Sending audio chunk (${audioChunk.length} bytes)');
          }
        },
        onError: (error) {
          debugPrint('[Speech] Audio stream error: $error');
          _recognitionController?.addError(error);
        },
        onDone: () {
          debugPrint('[Speech] Audio stream done');
          // Do not close the main channel here, only the audio subscription is done
        },
      );

      debugPrint('[Speech] Listening started successfully');
      return const Right(true);
    } catch (e) {
      debugPrint('[Speech] Failed to start listening: $e');
      return Left(
          ServerFailure('Failed to start listening: ${e.toString()}', 500));
    }
  }

  @override
  Future<Either<Failure, String>> stopListening() async {
    try {
      debugPrint('[Speech] Stopping listening...');
      
      // Check if audio recorder exists and is recording
      if (_audioRecorder == null || !await _audioRecorder!.isRecording()) {
        debugPrint('[Speech] Not recording, returning current transcript: "$_lastTranscript"');
        final result = _lastTranscript;
        _lastTranscript = '';
        _lastTranscriptTime = null;
        return Right(result);
      }

      // Create a completer to wait for the final transcript
      _finalTranscriptCompleter = Completer<String>();

      // Stop recording first to stop sending audio
      await _audioRecorder!.stop();
      debugPrint('[Speech] Audio recorder stopped');

      // Cancel the audio stream subscription
      await _webSocketSubscription?.cancel();
      _webSocketSubscription = null;

      // Send close message to Deepgram to finalize transcription
      try {
        _channel?.sink.add(json.encode({'type': 'CloseStream'}));
        debugPrint('[Speech] Sent CloseStream message');
      } catch (e) {
        debugPrint('[Speech] Error sending close message: $e');
      }

      // Wait for the final transcript or timeout after 2 seconds
      debugPrint('[Speech] Waiting for final transcript from Deepgram...');
      String finalTranscript;
      try {
        finalTranscript = await _finalTranscriptCompleter!.future.timeout(
          const Duration(milliseconds: 2000),
          onTimeout: () {
            debugPrint('[Speech] Timeout waiting for final transcript, using _lastTranscript');
            return _lastTranscript;
          },
        );
      } catch (e) {
        debugPrint('[Speech] Error waiting for final transcript: $e, using _lastTranscript');
        finalTranscript = _lastTranscript;
      }

      // Close the recognition controller
      await _recognitionController?.close();
      _recognitionController = null;

      debugPrint('[Speech] Stopped listening, final transcript: "$finalTranscript"');
      
      // Reset for next session
      _lastTranscript = '';
      _lastTranscriptTime = null;
      _finalTranscriptCompleter = null;
      
      return Right(finalTranscript);
    } catch (e) {
      debugPrint('[Speech] Error stopping listening: $e');
      _finalTranscriptCompleter = null;
      return Left(
          ServerFailure('Failed to stop listening: ${e.toString()}', 500));
    }
  }

  @override
  Future<Either<Failure, bool>> cancelListening() async {
    try {
      if (_audioRecorder != null && await _audioRecorder!.isRecording()) {
        await _audioRecorder!.stop();
      }
      await _webSocketSubscription?.cancel();
      _webSocketSubscription = null;
      await _deepgramSubscription?.cancel();
      _deepgramSubscription = null;
      await _channel?.sink.close();
      _channel = null;
      _isInitialized = false;
      await _recognitionController?.close();
      _recognitionController = null;
      return const Right(true);
    } catch (e) {
      return Left(
          ServerFailure('Failed to cancel listening: ${e.toString()}', 500));
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await _webSocketSubscription?.cancel();
      await _deepgramSubscription?.cancel();
      await _channel?.sink.close();
      await _recognitionController?.close();
      await _audioRecorder?.dispose();
      _audioRecorder = null;
      _isInitialized = false;
    } catch (e) {
      debugPrint('[Speech] Error during dispose: $e');
    }
  }

  @override
  Future<Either<Failure, bool>> isSpeechRecognitionAvailable() async {
    return isAvailable();
  }

  @override
  Future<Either<Failure, bool>> isAvailable() async {
    try {
      final permissionGrantedResult = await checkMicrophonePermission();
      final bool permissionGranted = permissionGrantedResult.fold(
        (l) => false,
        (r) => r,
      );

      final bool finalAvailability = permissionGranted && _channel != null;

      return permissionGrantedResult.fold(
        (l) => Left(l),
        (r) => Right(finalAvailability),
      );
    } catch (e) {
      return Left(ServerFailure(
          'Failed to check speech recognition availability: ${e.toString()}',
          500));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getAvailableLanguages() async {
    try {
      // Deepgram supports many languages. For simplicity, returning a few common ones.
      return const Right(['en-US', 'es-ES', 'fr-FR', 'de-DE']);
    } catch (e) {
      return Left(ServerFailure(
          'Failed to get available languages: ${e.toString()}', 500));
    }
  }

  @override
  Future<Either<Failure, bool>> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      return Right(status.isGranted);
    } catch (e) {
      return Left(PermissionFailure(
          'Failed to request microphone permission: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> checkMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      return Right(status.isGranted);
    } catch (e) {
      return Left(PermissionFailure(
          'Failed to check microphone permission: ${e.toString()}'));
    }
  }

  @override
  Stream<Either<Failure, String>> getRealtimeRecognitionStream() {
    if (_recognitionController == null) {
      return Stream.value(
          Left(ServerFailure('Recognition stream not available.', 500)));
    }
    
    return _recognitionController!.stream
            .map<Either<Failure, String>>((text) => Right(text))
            .handleError((error) {
          if (error is Failure) {
            return Left(error);
          }
          return Left(ServerFailure(
              'Realtime recognition stream error: ${error.toString()}', 500));
        });
  }
}
