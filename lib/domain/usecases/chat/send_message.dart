import 'package:ayobami/domain/entities/chat_message.dart';
import 'package:ayobami/domain/repositories/chat_repository.dart';
import 'package:ayobami/core/ai/ai_response_generator.dart';

class SendMessage {
  final ChatRepository repository;

  SendMessage(this.repository);

  Future<ChatMessage> call(String message) async {
    // Save user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: message,
      isUser: true,
      timestamp: DateTime.now(),
    );
    await repository.saveMessage(userMessage);

    // Generate AI response
    final aiResponse = await AIResponseGenerator.generateResponse(message);
    
    // Save AI response
    final responseMessage = ChatMessage(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      content: aiResponse.content,
      isUser: false,
      timestamp: DateTime.now(),
      type: aiResponse.type,
    );
    await repository.saveMessage(responseMessage);
    
    return responseMessage;
  }
}
