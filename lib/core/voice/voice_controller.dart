import 'package:flutter/foundation.dart';
import 'voice_services.dart';
import 'speech_to_text_impl.dart';
import 'text_to_speech_impl.dart';

/// Combined voice controller that manages both STT and TTS
class VoiceController {
  late final SpeechToTextService _speechToText;
  late final TextToSpeechService _textToSpeech;
  bool _isInitialized = false;

  VoiceController() {
    _speechToText = SpeechToTextServiceImpl();
    _textToSpeech = TextToSpeechServiceImpl();
  }

  /// Initialize both speech services
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final sttResult = await _speechToText.initialize();
      await _textToSpeech.initialize();
      
      _isInitialized = sttResult;
      return _isInitialized;
    } catch (e) {
      debugPrint('Voice controller initialization error: $e');
      return false;
    }
  }

  /// Start voice input (listening)
  Future<void> startListening({
    required Function(String) onResult,
    required Function(String) onError,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    await _speechToText.startListening(
      onResult: onResult,
      onError: onError,
    );
  }

  /// Stop voice input
  Future<void> stopListening() async {
    await _speechToText.stopListening();
  }

  /// Speak text aloud
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }
    await _textToSpeech.speak(text);
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    await _textToSpeech.stop();
  }

  /// Check if currently listening
  bool get isListening => _speechToText.isListening;

  /// Check if currently speaking
  bool get isSpeaking => _textToSpeech.isSpeaking;

  /// Check if voice services are available
  Future<bool> isAvailable() async {
    return await _speechToText.isAvailable();
  }

  /// Configure TTS settings
  Future<void> setSpeechRate(double rate) async {
    await _textToSpeech.setSpeechRate(rate);
  }

  Future<void> setPitch(double pitch) async {
    await _textToSpeech.setPitch(pitch);
  }

  Future<void> setVolume(double volume) async {
    await _textToSpeech.setVolume(volume);
  }

  /// Dispose all resources
  Future<void> dispose() async {
    await _speechToText.dispose();
    await _textToSpeech.dispose();
  }
}
