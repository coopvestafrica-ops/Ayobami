import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class SendMessageEvent extends ChatEvent {
  final String message;

  const SendMessageEvent(this.message);

  @override
  List<Object?> get props => [message];
}

class LoadChatHistoryEvent extends ChatEvent {
  const LoadChatHistoryEvent();
}

class ClearChatEvent extends ChatEvent {
  const ClearChatEvent();
}

class StartVoiceListeningEvent extends ChatEvent {
  const StartVoiceListeningEvent();
}

class StopVoiceListeningEvent extends ChatEvent {
  const StopVoiceListeningEvent();
}

class VoiceResultEvent extends ChatEvent {
  final String text;

  const VoiceResultEvent(this.text);

  @override
  List<Object?> get props => [text];
}

class SpeakResponseEvent extends ChatEvent {
  final String text;

  const SpeakResponseEvent(this.text);

  @override
  List<Object?> get props => [text];
}

class StopSpeakingEvent extends ChatEvent {
  const StopSpeakingEvent();
}
