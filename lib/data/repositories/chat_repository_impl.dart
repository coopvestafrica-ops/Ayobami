import 'package:ayobami/data/datasources/local/local_data_source.dart';
import 'package:ayobami/domain/entities/chat_message.dart';
import 'package:ayobami/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final LocalDataSource localDataSource;

  ChatRepositoryImpl({required this.localDataSource});

  @override
  Future<List<ChatMessage>> getChatHistory() async {
    return [];
  }

  @override
  Future<void> saveMessage(ChatMessage message) async {
    // Implementation for saving message
  }

  @override
  Future<void> clearChatHistory() async {
    // Implementation for clearing chat history
  }
}
