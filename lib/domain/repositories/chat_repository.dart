import 'package:ayobami/domain/entities/chat_message.dart';

abstract class ChatRepository {
  Future<List<ChatMessage>> getChatHistory();
  Future<void> saveMessage(ChatMessage message);
  Future<void> clearChatHistory();
}
