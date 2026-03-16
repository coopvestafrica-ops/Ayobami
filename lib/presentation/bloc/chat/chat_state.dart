import 'package:equatable/equatable.dart';
import 'package:ayobami/domain/entities/chat_message.dart';

enum ChatStatus { initial, loading, success, error }
enum VoiceStatus { idle, listening, speaking }

class ChatState extends Equatable {
  final ChatStatus status;
  final List<ChatMessage> messages;
  final String? errorMessage;
  final VoiceStatus voiceStatus;
  final String? recognizedText;
  final bool isSpeaking;

  const ChatState({
    this.status = ChatStatus.initial,
    this.messages = const [],
    this.errorMessage,
    this.voiceStatus = VoiceStatus.idle,
    this.recognizedText,
    this.isSpeaking = false,
  });

  ChatState copyWith({
    ChatStatus? status,
    List<ChatMessage>? messages,
    String? errorMessage,
    VoiceStatus? voiceStatus,
    String? recognizedText,
    bool? isSpeaking,
  }) {
    return ChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      errorMessage: errorMessage ?? this.errorMessage,
      voiceStatus: voiceStatus ?? this.voiceStatus,
      recognizedText: recognizedText,
      isSpeaking: isSpeaking ?? this.isSpeaking,
    );
  }

  @override
  List<Object?> get props => [
        status,
        messages,
        errorMessage,
        voiceStatus,
        recognizedText,
        isSpeaking,
      ];
}
