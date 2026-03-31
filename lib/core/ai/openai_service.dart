import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// OpenAI Service with function calling for real crypto data
/// Uses HTTP directly to call the OpenAI API
class OpenAIService {
  String? _apiKey;
  String? get apiKey => _apiKey;
  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  static const String _model = 'gpt-4o-mini';
  static const String _baseUrl = 'https://api.openai.com/v1';
  static const String _keyName = 'openai_api_key';

  static const String _systemPrompt = '''You are Ayobami, a friendly crypto trading assistant.

Your personality:
- Helpful, concise, and informative
- Always provide accurate information
- Use emojis appropriately
- Explain crypto concepts clearly

You have access to tools:
1. get_crypto_price - Get live crypto prices from Binance
2. calculate - Perform calculations

When users ask about prices, ALWAYS use the get_crypto_price tool to get real data.
When users ask about calculations, use the calculate tool.
Don't make up numbers - always fetch real data.''';

  OpenAIService();

  /// Load API key from SharedPreferences
  Future<void> loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_keyName) ?? '';
  }

  /// Send message and get AI response
  Future<OpenAIResponse> sendMessage(
    String message, {
    List<OpenAIChatHistoryMessage> chatHistory = const [],
  }) async {
    if (!isConfigured) {
      return OpenAIResponse(
        content: 'OpenAI API key not configured. Please add your API key in Settings.',
        type: OpenAIMessageType.error,
      );
    }

    try {
      final messages = <Map<String, dynamic>>[
        {'role': 'system', 'content': _systemPrompt},
        ...chatHistory.map((m) => {
          'role': m.isUser ? 'user' : 'assistant',
          'content': m.content,
        }),
        {'role': 'user', 'content': message},
      ];

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          'model': _model,
          'messages': messages,
          'tools': _tools,
          'tool_choice': 'auto',
          'temperature': 0.7,
        }),
      );

      if (response.statusCode != 200) {
        return OpenAIResponse(
          content: 'API Error: ${response.statusCode}',
          type: OpenAIMessageType.error,
        );
      }

      final data = json.decode(response.body);
      final choice = data['choices'][0];
      final messageData = choice['message'];

      if (messageData['tool_calls'] != null &&
          (messageData['tool_calls'] as List).isNotEmpty) {
        return await _handleToolCall(
          messageData['tool_calls'] as List,
          messages,
        );
      }

      return OpenAIResponse(
        content: messageData['content'] ?? 'I could not generate a response.',
        type: OpenAIMessageType.text,
      );
    } catch (e) {
      return OpenAIResponse(
        content: 'Error: ${e.toString()}',
        type: OpenAIMessageType.error,
      );
    }
  }

  Future<OpenAIResponse> _handleToolCall(
    List<dynamic> toolCalls,
    List<Map<String, dynamic>> messages,
  ) async {
    String? toolResult;

    for (final toolCall in toolCalls) {
      final fn = toolCall['function'];
      final name = fn['name'] as String;
      final args = json.decode(fn['arguments'] as String) as Map<String, dynamic>;

      if (name == 'get_crypto_price') {
        toolResult = await _getCryptoPrice(args);
      } else if (name == 'calculate') {
        toolResult = _calculate(args);
      }
    }

    if (toolResult == null) {
      return OpenAIResponse(
        content: 'Could not execute the tool.',
        type: OpenAIMessageType.error,
      );
    }

    messages.add({
      'role': 'tool',
      'content': toolResult,
      'tool_call_id': toolCalls.first['id'],
    });

    final response = await http.post(
      Uri.parse('$_baseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: json.encode({
        'model': _model,
        'messages': messages,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode != 200) {
      return OpenAIResponse(
        content: 'API Error: ${response.statusCode}',
        type: OpenAIMessageType.error,
      );
    }

    final data = json.decode(response.body);
    final content = data['choices'][0]['message']['content'] ?? 'No response';

    OpenAIMessageType type = OpenAIMessageType.text;
    if (content.toLowerCase().contains('price') ||
        content.toLowerCase().contains('btc') ||
        content.toLowerCase().contains('ethereum')) {
      type = OpenAIMessageType.marketData;
    }

    return OpenAIResponse(content: content, type: type);
  }

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

  static final List<Map<String, dynamic>> _tools = [
    {
      'type': 'function',
      'function': {
        'name': 'get_crypto_price',
        'description': 'Get the current price of a cryptocurrency from Binance',
        'parameters': {
          'type': 'object',
          'properties': {
            'symbol': {
              'type': 'string',
              'description': 'Crypto symbol like BTCUSDT, ETHUSDT',
              'default': 'BTCUSDT',
            },
          },
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'calculate',
        'description': 'Perform a calculation',
        'parameters': {
          'type': 'object',
          'properties': {
            'expression': {
              'type': 'string',
              'description': 'Math expression like 100 + 50',
            },
          },
          'required': ['expression'],
        },
      },
    },
  ];
}

/// Chat message for history (local to OpenAI service)
class OpenAIChatHistoryMessage {
  final String content;
  final bool isUser;

  OpenAIChatHistoryMessage({required this.content, required this.isUser});
}

/// AI response from OpenAI service
class OpenAIResponse {
  final String content;
  final OpenAIMessageType type;

  OpenAIResponse({required this.content, required this.type});
}

enum OpenAIMessageType {
  text,
  marketData,
  tradingSignal,
  calculator,
  reminder,
  error,
}
