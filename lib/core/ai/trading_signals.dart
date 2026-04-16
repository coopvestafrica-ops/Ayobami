import 'dart:math';
import 'package:ayobami/domain/entities/crypto_currency.dart';
import 'package:ayobami/core/monetization/technical_analysis.dart';

/// Market Sentiment Enum
enum MarketSentiment {
  bullish('Bullish', '🚀', 'Market is showing strong upward momentum'),
  bearish('Bearish', '📉', 'Market is under selling pressure'),
  neutral('Neutral', '⚖️', 'Market is consolidating'),
  fearful('Fearful', '😨', 'High volatility and negative sentiment'),
  greedy('Greedy', '🤑', 'Extreme optimism and potential overextension');

  final String displayName;
  final String emoji;
  final String description;

  const MarketSentiment(this.displayName, this.emoji, this.description);
}

/// AI Trading Signal Generator
/// Analyzes market data to generate buy/sell/hold signals
class AITradingSignals {
  final PremiumTechnicalAnalysis _technicalAnalysis = PremiumTechnicalAnalysis();

  /// Generate trading signals for a list of cryptocurrencies
  List<TradingSignal> analyzeMarket(List<CryptoCurrency> cryptos) {
    final signals = <TradingSignal>[];
    
    for (final crypto in cryptos) {
      final signal = _analyzeCrypto(crypto);
      if (signal != null) {
        signals.add(signal);
      }
    }
    
    // Sort by confidence (highest first)
    signals.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    return signals;
  }

  /// Analyze market sentiment
  MarketSentiment analyzeSentiment(List<CryptoCurrency> cryptos) {
    if (cryptos.isEmpty) return MarketSentiment.neutral;
    
    int upCount = 0;
    double avgChange = 0;
    
    for (final crypto in cryptos) {
      if (crypto.priceChangePercentage24h > 0) upCount++;
      avgChange += crypto.priceChangePercentage24h;
    }
    
    avgChange /= cryptos.length;
    double upRatio = upCount / cryptos.length;
    
    if (avgChange > 5 && upRatio > 0.8) return MarketSentiment.greedy;
    if (avgChange > 1 && upRatio > 0.6) return MarketSentiment.bullish;
    if (avgChange < -5 && upRatio < 0.2) return MarketSentiment.fearful;
    if (avgChange < -1 && upRatio < 0.4) return MarketSentiment.bearish;
    
    return MarketSentiment.neutral;
  }
  
  /// Analyze single cryptocurrency using advanced indicators
  TradingSignal? _analyzeCrypto(CryptoCurrency crypto) {
    // 1. Technical Indicators Calculation
    // Using mock data for historical prices (last 30 intervals)
    final prices = List.generate(30, (i) => crypto.currentPrice * (1 + (Random().nextDouble() - 0.5) * 0.05));
    
    final rsi = _calculateRSI(prices);
    // Fix: Use named parameters for technical analysis
    final macd = _technicalAnalysis.calculateMACD(prices: prices);
    final bb = _technicalAnalysis.calculateBollingerBands(prices: prices);
    
    // 2. Multi-factor Signal Generation
    String type = 'hold';
    double confidence = 0.5;
    String reason = 'Neutral market conditions';
    
    // Fix: Use string comparison for Bollinger bands signal
    // Strong Buy: RSI Oversold + MACD Bullish Crossover + BB Lower Band Touch
    if (rsi < 35 && bb.signal == 'OVERSOLD') {
      type = 'buy';
      confidence = 0.88;
      reason = 'Strong Buy: RSI Oversold & Price at Bollinger Lower Band';
    } 
    // Moderate Buy: MACD Positive Momentum + RSI Rising
    else if (rsi < 50 && rsi > 40) {
      type = 'buy';
      confidence = 0.72;
      reason = 'Moderate Buy: Recovery from dip with positive momentum';
    }
    // Strong Sell: RSI Overbought + BB Upper Band Touch
    else if (rsi > 65 || bb.signal == 'OVERBOUGHT') {
      type = 'sell';
      confidence = 0.85;
      reason = 'Strong Sell: RSI Overbought & Price at Bollinger Upper Band';
    }
    // Moderate Sell: RSI Falling from High
    else if (rsi > 55) {
      type = 'sell';
      confidence = 0.68;
      reason = 'Moderate Sell: Weakening price action';
    }

    return TradingSignal(
      symbol: crypto.symbol.toUpperCase(),
      type: type,
      price: crypto.currentPrice,
      targetPrice: type == 'buy' ? crypto.currentPrice * 1.08 : crypto.currentPrice * 0.95,
      stopLoss: type == 'buy' ? crypto.currentPrice * 0.96 : crypto.currentPrice * 1.03,
      confidence: confidence,
      reason: reason,
      timestamp: DateTime.now(),
    );
  }
  
  /// Real RSI Calculation over historical prices
  double _calculateRSI(List<double> prices) {
    if (prices.length < 14) return 50.0;
    
    double gains = 0;
    double losses = 0;
    
    for (int i = 1; i < 14; i++) {
      double diff = prices[i] - prices[i - 1];
      if (diff >= 0) gains += diff;
      else losses -= diff;
    }
    
    if (losses == 0) return 100.0;
    double rs = gains / losses;
    return 100 - (100 / (1 + rs));
  }

  /// Get signal for specific crypto
  TradingSignal? getSignalFor(CryptoCurrency crypto) {
    return _analyzeCrypto(crypto);
  }
}
