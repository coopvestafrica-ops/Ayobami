import 'dart:convert';
import 'package:dart_openai/dart_openai.dart';
import 'package:http/http.dart' as http;

/// OpenAI Service with function calling for real crypto data
class OpenAIService {
  String? _apiKey;
  String? get apiKey => _apiKey ??= _loadApiKey();
  bool get isConfigured => apiKey != null && apiKey!.isNotEmpty;

  static const String _model = 'gpt-4o-mini';

  String? _loadApiKey() {
    return '';
  }

  static const String _systemPrompt = '''You are Ayobami, a friendly crypto trading assistant.

Your personality:
- Helpful, concise, and informative
- Always provide accurate information
- Use emojis appropriately
- Explain crypto concepts clearly

You have access to tools:
1. get_crypto_price - Get live crypto prices from Binance
2. get_market_data - Get market data for cryptocurrencies
3. calculate - Perform calculations

When users ask about prices, ALWAYS use the get_crypto_price tool to get real data.
When users ask about calculations, use the calculate tool.
Don't make up numbers - always fetch real data.''';

  OpenAIService();

  /// Send message and get AI response with tool calling
  Future<AIResponse> sendMessage(
    String message, {
    List<ChatMessage> chatHistory = const [],
  }) async {
    if (!isConfigured) {
      return AIResponse(
        content: 'OpenAI API key not configured. Please add your API key in Settings.',
        type: MessageType.error,
      );
    }

    try {
      OpenAI.apiKey = apiKey!;
      final openai = OpenAI.instance;

      // Build messages with history
      final messages = <OpenAIChatCompletionChoiceMessageModel>[
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.system,
          content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(_systemPrompt)],
        ),
        ...chatHistory.map((m) => OpenAIChatCompletionChoiceMessageModel(
          role: m.isUser
              ? OpenAIChatMessageRole.user
              : OpenAIChatMessageRole.assistant,
          content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(m.content)],
        )),
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.user,
          content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(message)],
        ),
      ];

      // Make request with tools
      final response = await openai.chat.create(
        model: _model,
        messages: messages,
        tools: _tools,
        toolChoice: 'auto',
        temperature: 0.7,
      );

      final choice = response.choices.first;

      // Check if AI used a tool
      if (choice.message.toolCalls != null && choice.message.toolCalls!.isNotEmpty) {
        final toolCalls = choice.message.toolCalls!;
        messages.add(choice.message);
        
        for (final toolCall in toolCalls) {
          final fn = toolCall.function;
          final name = fn.name;
          final argsString = fn.arguments ?? '{}';
          final Map<String, dynamic> args = json.decode(argsString);
          String? toolResult;

          if (name == 'get_news_sentiment') {
            toolResult = await _getNewsSentiment(args);
          } else if (name == 'get_crypto_price') {
            toolResult = await _getCryptoPrice(args);
          } else if (name == 'calculate') {
            toolResult = _calculate(args);
          }

          if (toolResult != null) {
            messages.add(OpenAIChatCompletionChoiceMessageModel(
              role: OpenAIChatMessageRole.tool,
              content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(toolResult)],
            ));
          }
        }

        final finalResponse = await openai.chat.create(
          model: _model,
          messages: messages,
          temperature: 0.7,
        );

        final content = finalResponse.choices.first.message.content?.first.text ?? 'No response';
        return AIResponse(content: content, type: _determineType(content));
      }

      final content = choice.message.content?.first.text ?? 'I could not generate a response.';
      return AIResponse(content: content, type: MessageType.text);
    } catch (e) {
      return AIResponse(
        content: 'Error: ${e.toString()}',
        type: MessageType.error,
      );
    }
  }

  MessageType _determineType(String content) {
    if (content.toLowerCase().contains('price') ||
        content.toLowerCase().contains('btc') ||
        content.toLowerCase().contains('ethereum')) {
      return MessageType.marketData;
    }
    return MessageType.text;
  }

  /// Get live crypto price from Binance
  Future<String> _getCryptoPrice(Map<String, dynamic> args) async {
    final symbol = (args['symbol'] as String?)?.toUpperCase() ?? 'BTCUSDT';

    try {
      final uri = Uri.parse(
        'https://api.binance.com/api/v3/ticker/24hr?symbol=$symbol',
      );
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        return 'Error fetching price';
      }

      final data = json.decode(response.body);
      return json.encode({
        'symbol': data['symbol'],
        'price': data['lastPrice'],
        'change': data['priceChangePercent'],
        'high': data['highPrice'],
        'low': data['lowPrice'],
        'volume': data['volume'],
      });
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  /// Fetch crypto news and analyze sentiment (mock for demonstration)
  Future<String> _getNewsSentiment(Map<String, dynamic> args) async {
    final symbol = (args['symbol'] as String?)?.toUpperCase() ?? 'BTC';
    return json.encode({
      'symbol': symbol,
      'sentiment': 'Bullish',
      'recent_headlines': [
        '$symbol price surges as institutional adoption grows',
        'New utility upgrade announced for $symbol ecosystem',
        'Market analysts predict positive momentum for $symbol'
      ],
      'score': 0.85
    });
  }

  String _calculate(Map<String, dynamic> args) {
    try {
      final expression = args['expression'] as String? ?? '';
      final result = _evalExpression(expression);
      return '{"result": $result}';
    } catch (e) {
      return '{"error": "Could not calculate"}';
    }
  }

  double _evalExpression(String expr) {
    expr = expr.replaceAll(' ', '');
    if (expr.contains('+')) {
      final parts = expr.split('+');
      return double.parse(parts[0]) + double.parse(parts[1]);
    }
    if (expr.contains('-')) {
      final parts = expr.split('-');
      return double.parse(parts[0]) - double.parse(parts[1]);
    }
    if (expr.contains('*')) {
      final parts = expr.split('*');
      return double.parse(parts[0]) * double.parse(parts[1]);
    }
    if (expr.contains('/')) {
      final parts = expr.split('/');
      return double.parse(parts[0]) / double.parse(parts[1]);
    }
    return double.tryParse(expr) ?? 0;
  }

  // Tool definitions for OpenAI function calling
  static final List<OpenAIToolModel> _tools = [
    OpenAIToolModel(
      type: 'function',
      function: OpenAIFunctionModel(
        name: 'get_news_sentiment',
        description: 'Get latest news and sentiment for a crypto coin',
        parametersSchema: {
          'type': 'object',
          'properties': {
            'symbol': {
              'type': 'string',
              'description': 'Crypto symbol like BTC, ETH',
            },
          },
          'required': ['symbol'],
        },
      ),
    ),
    OpenAIToolModel(
      type: 'function',
      function: OpenAIFunctionModel(
        name: 'get_crypto_price',
        description: 'Get live crypto price from Binance',
        parametersSchema: {
          'type': 'object',
          'properties': {
            'symbol': {
              'type': 'string',
              'description': 'Crypto symbol like BTCUSDT, ETHUSDT',
              'default': 'BTCUSDT',
            },
          },
        },
      ),
    ),
    OpenAIToolModel(
      type: 'function',
      function: OpenAIFunctionModel(
        name: 'calculate',
        description: 'Evaluate a mathematical expression',
        parametersSchema: {
          'type': 'object',
          'properties': {
            'expression': {
              'type': 'string',
              'description': 'Math expression like 100 + 50',
            },
          },
          'required': ['expression'],
        },
      ),
    ),
  ];
}

/// Chat message for history
class ChatMessage {
  final String content;
  final bool isUser;

  ChatMessage({required this.content, required this.isUser});
}

/// AI response
class AIResponse {
  final String content;
  final MessageType type;

  AIResponse({required this.content, required this.type});
}

enum MessageType {
  text,
  marketData,
  tradingSignal,
  calculator,
  reminder,
  error,
}
