import 'dart:math';
import 'package:ayobami/domain/entities/crypto_currency.dart';

/// AI Trading Signal Generator
/// Analyzes market data to generate buy/sell/hold signals
class AITradingSignals {
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
  
  /// Analyze single cryptocurrency
  TradingSignal? _analyzeCrypto(CryptoCurrency crypto) {
    // Calculate indicators
    final priceChange = crypto.priceChangePercentage24h;
    final rsi = _calculateRSI(priceChange);
    final trend = _determineTrend(crypto);
    final momentum = _calculateMomentum(crypto);
    
    // Generate signal based on multiple factors
    String type;
    double confidence;
    String reason;
    double targetPrice;
    double stopLoss;
    
    // Strong buy conditions
    if (priceChange < -5 && rsi < 30 && momentum > 0) {
      type = 'buy';
      confidence = 0.85;
      reason = 'Oversold with strong momentum reversal';
      targetPrice = crypto.currentPrice * 1.10; // 10% target
      stopLoss = crypto.currentPrice * 0.95; // 5% stop loss
    }
    // Moderate buy conditions
    else if (priceChange < -3 && rsi < 40) {
      type = 'buy';
      confidence = 0.70;
      reason = 'Price recovering from dip';
      targetPrice = crypto.currentPrice * 1.07;
      stopLoss = crypto.currentPrice * 0.97;
    }
    // Strong sell conditions
    else if (priceChange > 5 && rsi > 70 && momentum < 0) {
      type = 'sell';
      confidence = 0.80;
      reason = 'Overbought with weakening momentum';
      targetPrice = crypto.currentPrice * 0.90;
      stopLoss = crypto.currentPrice * 1.05;
    }
    // Take profit (moderate gains)
    else if (priceChange > 4 && rsi > 60) {
      type = 'sell';
      confidence = 0.65;
      reason = 'Taking profits after gain';
      targetPrice = crypto.currentPrice * 0.95;
      stopLoss = crypto.currentPrice * 1.03;
    }
    // Continue hold
    else {
      type = 'hold';
      confidence = 0.60;
      reason = 'No clear signal - maintain position';
      targetPrice = crypto.currentPrice;
      stopLoss = crypto.currentPrice * 0.98;
    }
    
    return TradingSignal(
      symbol: crypto.symbol.toUpperCase(),
      type: type,
      price: crypto.currentPrice,
      targetPrice: targetPrice,
      stopLoss: stopLoss,
      confidence: confidence,
      reason: reason,
      timestamp: DateTime.now(),
    );
  }
  
  /// Calculate simplified RSI (Relative Strength Index)
  /// Returns 0-100, where <30 = oversold, >70 = overbought
  double _calculateRSI(double priceChange) {
    // Simplified RSI based on price change
    // Normalize -10% to +10% range to 0-100 scale
    final baseRSI = 50 + (priceChange * 5);
    return baseRSI.clamp(0, 100);
  }
  
  /// Determine price trend
  String _determineTrend(CryptoCurrency crypto) {
    if (crypto.priceChangePercentage24h > 2) {
      return 'uptrend';
    } else if (crypto.priceChangePercentage24h < -2) {
      return 'downtrend';
    }
    return 'sideways';
  }
  
  /// Calculate momentum score
  double _calculateMomentum(CryptoCurrency crypto) {
    // Simplified momentum: price change + volume indicator
    final changeMomentum = crypto.priceChangePercentage24h / 10;
    final volumeRatio = crypto.totalVolume > 0 ? 1.0 : 0.5;
    return changeMomentum * volumeRatio;
  }
  
  /// Get signal for specific crypto
  TradingSignal? getSignalFor(CryptoCurrency crypto) {
    return _analyzeCrypto(crypto);
  }
  
  /// Get overall market sentiment
  MarketSentiment analyzeSentiment(List<CryptoCurrency> cryptos) {
    if (cryptos.isEmpty) {
      return MarketSentiment.neutral;
    }
    
    final gainers = cryptos.where((c) => c.priceChangePercentage24h > 0).length;
    final losers = cryptos.where((c) => c.priceChangePercentage24h < 0).length;
    final total = cryptos.length;
    
    final gainerRatio = gainers / total;
    
    if (gainerRatio > 0.6) {
      return MarketSentiment.bullish;
    } else if (gainerRatio > 0.4) {
      return MarketSentiment.neutral;
    } else {
      return MarketSentiment.bearish;
    }
  }
}

/// Market sentiment enum
enum MarketSentiment {
  bullish,
  bearish,
  neutral,
  fearful,
  greedy,
}

/// Extension for sentiment display
extension MarketSentimentExtension on MarketSentiment {
  String get displayName {
    switch (this) {
      case MarketSentiment.bullish:
        return 'Bullish';
      case MarketSentiment.bearish:
        return 'Bearish';
      case MarketSentiment.neutral:
        return 'Neutral';
      case MarketSentiment.fearful:
        return 'Fearful';
      case MarketSentiment.greedy:
        return 'Greedy';
    }
  }
  
  String get emoji {
    switch (this) {
      case MarketSentiment.bullish:
        return '🐂';
      case MarketSentiment.bearish:
        return '🐻';
      case MarketSentiment.neutral:
        return '➡️';
      case MarketSentiment.fearful:
        return '😨';
      case MarketSentiment.greedy:
        return '🤑';
    }
  }
  
  String get description {
    switch (this) {
      case MarketSentiment.bullish:
        return 'Market is optimistic - many cryptos gaining';
      case MarketSentiment.bearish:
        return 'Market is pessimistic - many cryptos falling';
      case MarketSentiment.neutral:
        return 'Market is balanced - mixed signals';
      case MarketSentiment.fearful:
        return 'Investors are fearful - avoid risk';
      case MarketSentiment.greedy:
        return 'Investors are greedy - risk elevated';
    }
  }
}

/// Position size calculator based on risk management
class PositionSizer {
  /// Calculate position size in units based on account balance and risk
  static double calculatePositionSize({
    required double accountBalance,
    required double entryPrice,
    required double stopLossPrice,
    double riskPercent = 2.0, // Risk 2% of account
  }) {
    // Risk amount in dollars
    final riskAmount = accountBalance * (riskPercent / 100);
    
    // Price difference for stop loss
    final priceDiff = (entryPrice - stopLossPrice).abs();
    
    if (priceDiff == 0) return 0;
    
    // Position size (number of units)
    return riskAmount / priceDiff;
  }
  
  /// Calculate recommended stop loss price
  static double calculateStopLoss({
    required double entryPrice,
    required double atr, // Average True Range (volatility)
    double riskMultiple = 2.0,
  }) {
    return entryPrice - (atr * riskMultiple);
  }
  
  /// Calculate take profit price (2:1 reward:risk)
  static double calculateTakeProfit({
    required double entryPrice,
    required double stopLossPrice,
    double rewardRiskRatio = 2.0,
  }) {
    final risk = (entryPrice - stopLossPrice).abs();
    return entryPrice + (risk * rewardRiskRatio);
  }
}

/// Risk reward analyzer
class RiskRewardAnalyzer {
  static AnalyzeRiskReward analyze({
    required double entryPrice,
    required double targetPrice,
    required double stopLossPrice,
  }) {
    final potentialReward = ((targetPrice - entryPrice) / entryPrice * 100);
    final potentialRisk = ((entryPrice - stopLossPrice).abs() / entryPrice * 100);
    
    final rewardRiskRatio = potentialRisk > 0 ? potentialReward / potentialRisk : 0.0;
    
    String recommendation;
    if (rewardRiskRatio >= 2.0) {
      recommendation = 'Favorable trade - good reward:risk ratio';
    } else if (rewardRiskRatio >= 1.5) {
      recommendation = 'Acceptable trade';
    } else if (rewardRiskRatio >= 1.0) {
      recommendation = 'Risky - equal reward:risk';
    } else {
      recommendation = 'Not recommended - poor reward:risk';
    }
    
    return AnalyzeRiskReward(
      potentialRewardPercent: potentialReward,
      potentialRiskPercent: potentialRisk,
      rewardRiskRatio: rewardRiskRatio,
      recommendation: recommendation,
    );
  }
}

/// Risk reward analysis result
class AnalyzeRiskReward {
  final double potentialRewardPercent;
  final double potentialRiskPercent;
  final double rewardRiskRatio;
  final String recommendation;
  
  AnalyzeRiskReward({
    required this.potentialRewardPercent,
    required this.potentialRiskPercent,
    required this.rewardRiskRatio,
    required this.recommendation,
  });
  
  bool get isFavorable => rewardRiskRatio >= 2.0;
}
