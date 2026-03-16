import 'package:ayobami/domain/entities/chat_message.dart';
import 'package:ayobami/domain/repositories/chat_repository.dart';

class GetChatHistory {
  final ChatRepository repository;

  GetChatHistory(this.repository);

  Future<List<ChatMessage>> call() async {
    return await repository.getChatHistory();
  }
}
