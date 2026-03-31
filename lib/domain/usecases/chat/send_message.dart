import 'package:ayobami/core/ai/openai_service.dart';
import 'package:ayobami/domain/entities/chat_message.dart';
import 'package:ayobami/domain/repositories/chat_repository.dart';

class SendMessage {
  final ChatRepository repository;
  final OpenAIService openAIService;

  SendMessage(this.repository, this.openAIService);

  Future<ChatMessage> call(String message, {List<ChatMessage>? history}) async {
    // Save user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: message,
      isUser: true,
      timestamp: DateTime.now(),
    );
    await repository.saveMessage(userMessage);

    // Convert history to ChatMessage format for OpenAI
    final chatHistory = history
        ?.map((m) => ChatMessage(content: m.content, isUser: m.isUser))
        .toList() ?? [];

    // Generate AI response using OpenAI
    final aiResponse = await openAIService.sendMessage(
      message,
      chatHistory: chatHistory,
    );
    
    // Save AI response
    final responseMessage = ChatMessage(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      content: aiResponse.content,
      isUser: false,
      timestamp: DateTime.now(),
      type: aiResponse.type == MessageType.marketData
          ? ChatMessageType.marketData
          : aiResponse.type == MessageType.tradingSignal
              ? ChatMessageType.tradingSignal
              : ChatMessageType.text,
    );
    await repository.saveMessage(responseMessage);
    
    return responseMessage;
  }
}
