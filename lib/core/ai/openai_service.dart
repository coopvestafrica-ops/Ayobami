import 'dart:convert';
import 'package:openai/openai.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// OpenAI Service with function calling for real crypto data
class OpenAIService {
  String? _apiKey;
  String? get apiKey => _apiKey ??= _loadApiKey();
  bool get isConfigured => apiKey != null && apiKey!.isNotEmpty;

  static const String _model = 'gpt-4o-mini';

  String? _loadApiKey() {
    // This will be called lazily - SharedPreferences should already be initialized
    // For now, return empty - user needs to enter in settings
    return '';
  }

  static const String _keyName = 'openai_api_key';

  // System prompt that defines the AI's personality
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
      final openai = OpenAI(apiKey: apiKey!);

      // Build messages with history
      final messages = <OpenAIChatMessage>[
        OpenAIChatMessage(
          role: OpenAIChatMessageRole.system,
          content: _systemPrompt,
        ),
        ...chatHistory.map((m) => OpenAIChatMessage(
          role: m.isUser
              ? OpenAIChatMessageRole.user
              : OpenAIChatMessageRole.assistant,
          content: m.content,
        )),
        OpenAIChatMessage(
          role: OpenAIChatMessageRole.user,
          content: message,
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
        return await _handleToolCall(openai, choice.message.toolCalls!, messages);
      }

      return AIResponse(
        content: choice.message.content ?? 'I could not generate a response.',
        type: MessageType.text,
      );
    } catch (e) {
      return AIResponse(
        content: 'Error: ${e.toString()}',
        type: MessageType.error,
      );
    }
  }

  /// Handle tool calls from AI
  Future<AIResponse> _handleToolCall(
    OpenAI openai,
    List<OpenAIChatToolCall> toolCalls,
    List<OpenAIChatMessage> messages,
  ) async {
    String? toolResult;

    for (final toolCall in toolCalls) {
      final fn = toolCall.function;
      final name = fn.name;
      final args = fn.arguments;

      if (name == 'get_crypto_price') {
        toolResult = await _getCryptoPrice(args);
      } else if (name == 'calculate') {
        toolResult = _calculate(args);
      }
    }

    if (toolResult == null) {
      return AIResponse(
        content: 'Could not execute the tool.',
        type: MessageType.error,
      );
    }

    // Add tool result to messages and get final response
    messages.add(OpenAIChatMessage(
      role: OpenAIChatMessageRole.tool,
      content: toolResult,
      toolCallId: toolCalls.first.id,
    ));

    final response = await openai.chat.create(
      model: _model,
      messages: messages,
      temperature: 0.7,
    );

    final content = response.choices.first.message.content ?? 'No response';

    // Determine message type based on content
    MessageType type = MessageType.text;
    if (content.toLowerCase().contains('price') ||
        content.toLowerCase().contains('btc') ||
        content.toLowerCase().contains('ethereum')) {
      type = MessageType.marketData;
    }

    return AIResponse(content: content, type: type);
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

  /// Simple calculator
  String _calculate(Map<String, dynamic> args) {
    try {
      final expression = args['expression'] as String? ?? '';
      // Very basic eval - in production use a proper parser
      final result = _evalExpression(expression);
      return '{"result": $result}';
    } catch (e) {
      return '{"error": "Could not calculate"}';
    }
  }

  double _evalExpression(String expr) {
    expr = expr.replaceAll(' ', '');
    // Handle basic operations
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
  static final List<OpenAIChatTool> _tools = [
    OpenAIChatTool(
      functionName: 'get_crypto_price',
      description: 'Get the current price of a cryptocurrency from Binance',
      parameters: OpenAIChatFunctionParameters(
        name: 'get_crypto_price',
        description: 'Get live crypto price from Binance',
        parameters: {
          'type': 'object',
          'properties': {
            'symbol': {
              'type': 'string',
              'description': 'Crypto symbol like BTCUSDT, ETHUSDT',
              'default': 'BTCUSDT',
            },
          },
        },
        required: [],
      ),
    ),
    OpenAIChatTool(
      functionName: 'calculate',
      description: 'Perform a calculation',
      parameters: OpenAIChatFunctionParameters(
        name: 'calculate',
        description: 'Evaluate a mathematical expression',
        parameters: {
          'type': 'object',
          'properties': {
            'expression': {
              'type': 'string',
              'description': 'Math expression like 100 + 50',
            },
          },
        },
        required: ['expression'],
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