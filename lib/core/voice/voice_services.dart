import 'package:flutter/foundation.dart';

/// Abstract interface for speech-to-text functionality
abstract class SpeechToTextService {
  /// Initialize the speech recognition service
  Future<bool> initialize();

  /// Start listening for speech input
  Future<void> startListening({
    required Function(String) onResult,
    required Function(String) onError,
  });

  /// Stop listening
  Future<void> stopListening();

  /// Check if speech recognition is available
  Future<bool> isAvailable();

  /// Check if currently listening
  bool get isListening;

  /// Dispose resources
  Future<void> dispose();
}

/// Abstract interface for text-to-speech functionality
abstract class TextToSpeechService {
  /// Initialize TTS engine
  Future<void> initialize();

  /// Speak the given text
  Future<void> speak(String text);

  /// Stop speaking
  Future<void> stop();

  /// Set speech rate (0.0 to 1.0)
  Future<void> setSpeechRate(double rate);

  /// Set pitch (0.0 to 1.0)
  Future<void> setPitch(double pitch);

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume);

  /// Check if TTS is speaking
  bool get isSpeaking;

  /// Dispose resources
  Future<void> dispose();
}
