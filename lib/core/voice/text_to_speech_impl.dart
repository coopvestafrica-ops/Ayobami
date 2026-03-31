import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'voice_services.dart';

/// Implementation of TextToSpeechService using flutter_tts package
class TextToSpeechServiceImpl implements TextToSpeechService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  double _speechRate = 0.5;
  double _pitch = 1.0;
  double _volume = 1.0;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setPitch(_pitch);
      await _flutterTts.setVolume(_volume);

      // Handle completion
      _flutterTts.setCompletionHandler(() {
        debugPrint('TTS completed');
      });

      _flutterTts.setCancelHandler(() {
        debugPrint('TTS cancelled');
      });

      _flutterTts.setErrorHandler((error) {
        debugPrint('TTS error: $error');
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('TTS initialization error: $e');
    }
  }

  @override
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (text.isEmpty) return;

    // Stop any ongoing speech first
    await stop();

    await _flutterTts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _flutterTts.stop();
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.0, 1.0);
    await _flutterTts.setSpeechRate(_speechRate);
  }

  @override
  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    await _flutterTts.setPitch(_pitch);
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _flutterTts.setVolume(_volume);
  }

  @override
  bool get isSpeaking => false;

  @override
  Future<void> dispose() async {
    await stop();
  }
}
