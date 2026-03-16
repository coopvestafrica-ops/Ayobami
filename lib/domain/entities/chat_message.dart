import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final MessageType type;
  
  const ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.type = MessageType.text,
  });
  
  @override
  List<Object?> get props => [id, content, isUser, timestamp, type];
}

enum MessageType {
  text,
  tradingSignal,
  marketData,
  reminder,
  calculator,
  error,
}
