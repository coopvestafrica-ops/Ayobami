import 'dart:convert';
import 'package:ayobami/core/ai/openai_service.dart';
import 'package:dart_openai/dart_openai.dart';

/// Machine Learning Price Predictor
/// Uses historical price patterns and OpenAI's GPT models for forecasting
class PricePredictor {
  final OpenAIService _openAIService;

  PricePredictor(this._openAIService);

  /// Predict next price movement based on historical OHLCV data
  Future<PredictionResult> predictMovement({
    required String symbol,
    required List<double> prices,
    required List<double> volumes,
  }) async {
    if (!_openAIService.isConfigured) {
      return PredictionResult(prediction: 'NEUTRAL', confidence: 0.5, reason: 'AI Service not configured');
    }

    try {
      // 1. Prepare historical data context
      final priceContext = prices.take(20).toList();
      final volumeContext = volumes.take(20).toList();

      // 2. Ask OpenAI to perform pattern recognition (acting as a sequence model)
      final prompt = 'Analyze this price and volume sequence for $symbol and predict the next movement. '
          'Price: ${priceContext.join(', ')} '
          'Volume: ${volumeContext.join(', ')} '
          'Return JSON: {"prediction": "UP/DOWN/SIDEWAYS", "confidence": 0.0 to 1.0, "reason": "Short explanation"}';

      final chatCompletion = await OpenAI.instance.chat.create(
        model: 'gpt-4o-mini',
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt)],
            role: OpenAIChatMessageRole.user,
          ),
        ],
        responseFormat: const OpenAIChatCompletionResponseFormatModel(type: 'json_object'),
      );

      final content = chatCompletion.choices.first.message.content?.first.text ?? '{}';
      final analysis = jsonDecode(content);

      return PredictionResult(
        prediction: analysis['prediction'] as String,
        confidence: (analysis['confidence'] as num).toDouble(),
        reason: analysis['reason'] as String,
      );
    } catch (e) {
      print('Prediction Error: $e');
      return PredictionResult(prediction: 'NEUTRAL', confidence: 0.5, reason: 'Error in prediction engine');
    }
  }
}

class PredictionResult {
  final String prediction; // UP, DOWN, SIDEWAYS
  final double confidence;
  final String reason;

  PredictionResult({
    required this.prediction,
    required this.confidence,
    required this.reason,
  });

  bool get isBullish => prediction == 'UP' && confidence > 0.65;
  bool get isBearish => prediction == 'DOWN' && confidence > 0.65;
}
