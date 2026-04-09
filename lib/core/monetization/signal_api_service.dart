import 'package:http/http.dart' as http;
import 'dart:convert';

/// Signal API Service - Monetize trading signals via REST API
class SignalAPIService {
  static const String baseUrl = 'https://your-api.ayobami.com/api/v1';
  
  final String apiKey;
  
  SignalAPIService({required this.apiKey});
  
  /// Publish trading signal and return subscriber count who received it
  Future<int> publishSignal({
    required String symbol,
    required String type, // 'BUY', 'SELL', 'HOLD'
    required double price,
    required double confidence,
    required String reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('\$baseUrl/signals/publish'),
        headers: {
          'Authorization': 'Bearer \$apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'symbol': symbol,
          'type': type,
          'price': price,
          'confidence': confidence,
          'reason': reason,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['subscribers_notified'] ?? 0;
      }
    } catch (e) {
      print('Signal API Error: \$e');
    }
    return 0;
  }
  
  /// Get subscription metrics (revenue dashboard)
  Future<Map<String, dynamic>?> getMetrics() async {
    try {
      final response = await http.get(
        Uri.parse('\$baseUrl/signals/metrics'),
        headers: {'Authorization': 'Bearer \$apiKey'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Metrics Error: \$e');
    }
    return null;
  }
}
