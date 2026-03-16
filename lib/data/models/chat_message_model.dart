import 'package:ayobami/domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.content,
    required super.isUser,
    required super.timestamp,
    super.type,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      content: json['content'] as String,
      isUser: json['is_user'] == 1,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: MessageType.values[json['type'] as int? ?? 0],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'is_user': isUser ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
      'type': type.index,
    };
  }

  factory ChatMessageModel.fromEntity(ChatMessage message) {
    return ChatMessageModel(
      id: message.id,
      content: message.content,
      isUser: message.isUser,
      timestamp: message.timestamp,
      type: message.type,
    );
  }
}
