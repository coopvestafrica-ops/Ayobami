import 'dart:convert';
import 'package:http/http.dart' as http;

/// Simple Binance API service for public market data (no API key required)
class BinanceApiService {
  static const String _baseUrl = 'https://api.binance.com';

  /// Get current price for a symbol (public endpoint)
  Future<Map<String, String>?> getTicker(String symbol) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/v3/ticker/24hr?symbol=$symbol');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'symbol': data['symbol'] ?? symbol,
          'lastPrice': data['lastPrice'] ?? '0',
          'priceChange': data['priceChange'] ?? '0',
          'priceChangePercent': data['priceChangePercent'] ?? '0',
          'highPrice': data['highPrice'] ?? '0',
          'lowPrice': data['lowPrice'] ?? '0',
          'volume': data['volume'] ?? '0',
          'quoteVolume': data['quoteVolume'] ?? '0',
        };
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }

  /// Get price for multiple symbols
  Future<List<Map<String, String>>> getPrices(List<String> symbols) async {
    final results = <Map<String, String>>[];
    
    for (final symbol in symbols) {
      final ticker = await getTicker(symbol);
      if (ticker != null) {
        results.add(ticker);
      }
    }
    
    return results;
  }

  /// Get historical candlestick closes (public endpoint, no auth required).
  /// Returns an empty list on any network / parse error so callers can fall
  /// back to a neutral signal rather than crashing.
  ///
  /// [interval] examples: '1m', '5m', '15m', '1h', '4h', '1d'.
  Future<List<double>> getKlineCloses(
    String symbol, {
    String interval = '1h',
    int limit = 100,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/api/v3/klines?symbol=$symbol&interval=$interval&limit=$limit',
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) return const <double>[];

      final data = json.decode(response.body) as List<dynamic>;
      // Each kline: [openTime, open, high, low, close, volume, closeTime, ...]
      // Close is index 4, encoded as a string.
      return data
          .map((row) => double.tryParse((row as List)[4].toString()) ?? 0.0)
          .where((v) => v > 0)
          .toList(growable: false);
    } catch (_) {
      return const <double>[];
    }
  }
}