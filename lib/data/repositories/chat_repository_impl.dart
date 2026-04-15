import 'package:ayobami/data/datasources/local/local_data_source.dart';
import 'package:ayobami/domain/entities/chat_message.dart';
import 'package:ayobami/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final LocalDataSource localDataSource;

  ChatRepositoryImpl({required this.localDataSource});

  @override
  Future<List<ChatMessage>> getChatHistory() async {
    final messages = await localDataSource.getChatHistory();
    return messages.map((model) => ChatMessage(
      id: model.id,
      content: model.content,
      isUser: model.isUser,
      timestamp: model.timestamp,
    )).toList();
  }

  @override
  Future<void> saveMessage(ChatMessage message) async {
    final model = ChatMessageModel(
      id: message.id,
      content: message.content,
      isUser: message.isUser,
      timestamp: message.timestamp,
    );
    await localDataSource.saveMessage(model);
  }

  @override
  Future<void> clearChatHistory() async {
    await localDataSource.clearChatHistory();
  }
}
