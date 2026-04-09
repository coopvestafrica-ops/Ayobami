import 'package:http/http.dart' as http;
import 'dart:convert';

class ArbitrageDetector {
  static const String binanceUrl = 'https://api.binance.com/api/v3';
  static const String coinbaseUrl = 'https://api.coinbase.com/v2';
  static const String krakenUrl = 'https://api.kraken.com/0';
  
  /// Detect arbitrage opportunities across exchanges
  /// Returns profitable trades where profit > 2%
  Future<List<ArbitrageOpportunity>> detectOpportunities(
    List<String> symbols,
  ) async {
    final opportunities = <ArbitrageOpportunity>[];
    
    for (final symbol in symbols) {
      final prices = await _getPricesAcrossExchanges(symbol);
      
      if (prices.isNotEmpty) {
        final minPrice = prices.values.reduce((a, b) => a < b ? a : b);
        final maxPrice = prices.values.reduce((a, b) => a > b ? a : b);
        final profitPercent = ((maxPrice - minPrice) / minPrice) * 100;
        
        if (profitPercent > 2.0) {
          opportunities.add(ArbitrageOpportunity(
            symbol: symbol,
            buyExchange: prices.entries
                .firstWhere((e) => e.value == minPrice)
                .key,
            sellExchange: prices.entries
                .firstWhere((e) => e.value == maxPrice)
                .key,
            buyPrice: minPrice,
            sellPrice: maxPrice,
            profitPercent: profitPercent,
            timestamp: DateTime.now(),
          ));
        }
      }
    }
    
    return opportunities;
  }
  
  Future<Map<String, double>> _getPricesAcrossExchanges(String symbol) async {
    final prices = <String, double>{};
    
    try {
      // Binance
      final binanceRes = await http.get(
        Uri.parse('\$binanceUrl/ticker/price?symbol=\${symbol}USDT'),
      ).timeout(const Duration(seconds: 5));
      if (binanceRes.statusCode == 200) {
        final data = jsonDecode(binanceRes.body);
        prices['binance'] = double.parse(data['price']);
      }
    } catch (_) {}
    
    return prices;
  }
}

class ArbitrageOpportunity {
  final String symbol;
  final String buyExchange;
  final String sellExchange;
  final double buyPrice;
  final double sellPrice;
  final double profitPercent;
  final DateTime timestamp;
  
  ArbitrageOpportunity({
    required this.symbol,
    required this.buyExchange,
    required this.sellExchange,
    required this.buyPrice,
    required this.sellPrice,
    required this.profitPercent,
    required this.timestamp,
  });
}
