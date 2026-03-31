import 'package:ayobami/core/ai/ai_response_generator.dart';
import 'package:ayobami/core/services/binance_api_service.dart';
import 'package:ayobami/domain/entities/chat_message.dart';
import 'package:ayobami/domain/repositories/chat_repository.dart';

class SendMessage {
  final ChatRepository repository;
  final BinanceApiService binanceApi;

  SendMessage(this.repository, this.binanceApi);

  Future<ChatMessage> call(String message, {List<ChatMessage>? history}) async {
    // Save user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: message,
      isUser: true,
      timestamp: DateTime.now(),
    );
    await repository.saveMessage(userMessage);

    // Generate AI response using rule-based AI ( Synthetic Intelligence )
    final aiResponse = await AIResponseGenerator.generateResponse(message);

    // If it's a crypto query, try to fetch real-time data
    if (aiResponse.type == MessageType.marketData && _shouldFetchLiveData(message)) {
      final liveData = await _fetchLiveCryptoData(message);
      if (liveData != null) {
        // Merge live data into response
        final updatedContent = '${liveData}\n\n${aiResponse.content}';
        final responseMessage = ChatMessage(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          content: updatedContent,
          isUser: false,
          timestamp: DateTime.now(),
          type: aiResponse.type,
        );
        await repository.saveMessage(responseMessage);
        return responseMessage;
      }
    }

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

  bool _shouldFetchLiveData(String message) {
    final lower = message.toLowerCase();
    return lower.contains('price') ||
        lower.contains('btc') ||
        lower.contains('ethereum') ||
        lower.contains('eth') ||
        lower.contains('current');
  }

  Future<String?> _fetchLiveCryptoData(String message) async {
    try {
      final lower = message.toLowerCase();
      String symbol = 'BTCUSDT';

      if (lower.contains('eth')) {
        symbol = 'ETHUSDT';
      } else if (lower.contains('bnb')) {
        symbol = 'BNBUSDT';
      } else if (lower.contains('sol')) {
        symbol = 'SOLUSDT';
      } else if (lower.contains('xrp')) {
        symbol = 'XRPUSDT';
      } else if (lower.contains('ada')) {
        symbol = 'ADAUSDT';
      } else if (lower.contains('dot')) {
        symbol = 'DOTUSDT';
      } else if (lower.contains('doge')) {
        symbol = 'DOGEUSDT';
      } else if (lower.contains('avax')) {
        symbol = 'AVAXUSDT';
      } else if (lower.contains('matic')) {
        symbol = 'MATICUSDT';
      }

      final ticker = await binanceApi.getTicker(symbol);
      if (ticker != null) {
        final price = double.parse(ticker['lastPrice'] ?? '0');
        final change = double.parse(ticker['priceChangePercent'] ?? '0');
        final formattedPrice = price.toStringAsFixed(2);
        final sign = change >= 0 ? '+' : '';

        return '**$symbol Live Price:**\n'
            '\ud83d\udcb8 $formattedPrice USD\n'
            '${sign}${change.toStringAsFixed(2)}% (24h)';
      }
    } catch (e) {
      // Return null to use default AI response
    }
    return null;
  }

  MessageType _mapMessageType(MessageType type) {
    return type;
  }
}
