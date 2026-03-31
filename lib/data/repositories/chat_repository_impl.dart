import 'package:ayobami/data/datasources/local/local_data_source.dart';
import 'package:ayobami/data/models/chat_message_model.dart';
import 'package:ayobami/domain/entities/chat_message.dart';
import 'package:ayobami/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final LocalDataSource localDataSource;

  ChatRepositoryImpl({required this.localDataSource});

  @override
  Future<List<ChatMessage>> getChatHistory() async {
    return await localDataSource.getChatHistory();
  }

  @override
  Future<void> saveMessage(ChatMessage message) async {
    final model = ChatMessageModel.fromEntity(message);
    await localDataSource.saveMessage(model);
  }

  @override
  Future<void> clearChatHistory() async {
    await localDataSource.clearChatHistory();
  }
}
