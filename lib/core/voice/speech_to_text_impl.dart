import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'voice_services.dart';

/// Implementation of SpeechToTextService using speech_to_text package
class SpeechToTextServiceImpl implements SpeechToTextService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  // Callbacks
  Function(String)? _onResultCallback;
  Function(String)? _onErrorCallback;

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      _isInitialized = await _speechToText.initialize(
        onError: (error) {
          _onErrorCallback?.call(error.errorMsg);
          _isListening = false;
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('Speech to text initialization error: $e');
      return false;
    }
  }

  @override
  Future<void> startListening({
    required Function(String) onResult,
    required Function(String) onError,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        onError('Speech recognition not initialized');
        return;
      }
    }

    if (_isListening) {
      await stopListening();
    }

    _onResultCallback = onResult;
    _onErrorCallback = onError;
    _isListening = true;

    await _speechToText.listen(
      onResult: (SpeechRecognitionResult result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
          _isListening = false;
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: 'en_US',
      cancelOnError: true,
      listenMode: ListenMode.confirmation,
    );
  }

  @override
  Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
    }
  }

  @override
  Future<bool> isAvailable() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _isInitialized;
  }

  @override
  bool get isListening => _isListening;

  @override
  Future<void> dispose() async {
    await stopListening();
    _speechToText.cancel();
  }
}
