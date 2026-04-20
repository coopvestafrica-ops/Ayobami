import 'package:ayobami/data/datasources/remote/exchange_service.dart';
import 'dart:async';

/// Detect arbitrage opportunities across exchanges
class ArbitrageDetector {
  final ExchangeService _exchangeService;
  
  ArbitrageDetector(this._exchangeService);

  /// Detect arbitrage opportunities across Binance and Coinbase
  /// Returns profitable trades where profit > threshold
  Future<List<ArbitrageOpportunity>> detectOpportunities({
    required List<String> symbols,
    double minProfitThreshold = 0.5, // Lowered to 0.5% for more realistic opportunities
  }) async {
    final opportunities = <ArbitrageOpportunity>[];
    
    for (final symbol in symbols) {
      try {
        final prices = await _getPricesAcrossExchanges(symbol);
        
        if (prices.length >= 2) {
          final sortedPrices = prices.entries.toList()
            ..sort((a, b) => a.value.compareTo(b.value));
          
          final minPriceEntry = sortedPrices.first;
          final maxPriceEntry = sortedPrices.last;
          
          final minPrice = minPriceEntry.value;
          final maxPrice = maxPriceEntry.value;
          
          // Calculate gross profit
          final profitPercent = ((maxPrice - minPrice) / minPrice) * 100;
          
          // Consider estimated fees (approx 0.1% per trade * 2 = 0.2%)
          const estimatedFees = 0.2;
          final netProfitPercent = profitPercent - estimatedFees;
          
          if (netProfitPercent > minProfitThreshold) {
            opportunities.add(ArbitrageOpportunity(
              symbol: symbol,
              buyExchange: minPriceEntry.key,
              sellExchange: maxPriceEntry.key,
              buyPrice: minPrice,
              sellPrice: maxPrice,
              profitPercent: netProfitPercent,
              timestamp: DateTime.now(),
            ));
          }
        }
      } catch (e) {
        print('Error detecting arbitrage for $symbol: $e');
      }
    }
    
    return opportunities;
  }
  
  Future<Map<String, double>> _getPricesAcrossExchanges(String symbol) async {
    final prices = <String, double>{};
    
    // Original exchange state to restore later
    final originalExchange = _exchangeService.activeExchange;
    
    try {
      // Get Binance Price
      if (_exchangeService.isBinanceConnected) {
        _exchangeService.setActiveExchange(ExchangeType.binance);
        prices['Binance'] = await _exchangeService.getPrice(symbol);
      }
      
      // Get Coinbase Price
      if (_exchangeService.isCoinbaseConnected) {
        _exchangeService.setActiveExchange(ExchangeType.coinbase);
        prices['Coinbase'] = await _exchangeService.getPrice(symbol);
      }
    } finally {
      // Restore original exchange
      if (originalExchange != null) {
        _exchangeService.setActiveExchange(originalExchange);
      }
    }
    
    return prices;
  }

  /// Execute an arbitrage trade
  Future<bool> executeArbitrage(ArbitrageOpportunity opportunity, double amount) async {
    try {
      // 1. Buy on cheaper exchange
      final buyExchangeType = opportunity.buyExchange == 'Binance' 
          ? ExchangeType.binance 
          : ExchangeType.coinbase;
      
      _exchangeService.setActiveExchange(buyExchangeType);
      final buyOrder = await _exchangeService.placeBuyOrder(
        symbol: opportunity.symbol,
        amount: amount / opportunity.buyPrice,
        price: opportunity.buyPrice,
      );

      if (!buyOrder.isFilled && !buyOrder.isPending) return false;

      // 2. Sell on more expensive exchange
      final sellExchangeType = opportunity.sellExchange == 'Binance' 
          ? ExchangeType.binance 
          : ExchangeType.coinbase;
          
      _exchangeService.setActiveExchange(sellExchangeType);
      final sellOrder = await _exchangeService.placeSellOrder(
        symbol: opportunity.symbol,
        quantity: amount / opportunity.buyPrice,
        price: opportunity.sellPrice,
      );

      return sellOrder.isFilled || sellOrder.isPending;
    } catch (e) {
      print('Arbitrage Execution Error: $e');
      return false;
    }
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
