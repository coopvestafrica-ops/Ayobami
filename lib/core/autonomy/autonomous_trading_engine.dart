import 'package:ayobami/core/monetization/technical_analysis.dart';
import 'package:ayobami/core/monetization/ai_pattern_recognition.dart';

class AutonomousTradingEngine {
  final double maxPositionSize;
  final double maxRiskPerTrade;
  final double minWinRateRequired;
  
  AutonomousTradingEngine({
    this.maxPositionSize = 5.0,
    this.maxRiskPerTrade = 2.0,
    this.minWinRateRequired = 0.55,
  });
  
  Future<TradeDecision> makeTradeDecision({
    required String symbol,
    required List<double> prices,
    required List<double> volumes,
    required double currentPrice,
    required double portfolioValue,
    required List<double> entryPrices,
    required Map<String, double> holdings,
    required double marketSentiment,
    required List<String> whaleTransactions,
  }) async {
    final technicalAnalysis = PremiumTechnicalAnalysis();
    
    final macd = technicalAnalysis.calculateMACD(prices: prices);
    final macdScore = macd.macdLine > 0 ? 0.7 : 0.3;
    
    final bollingerBands = technicalAnalysis.calculateBollingerBands(prices: prices);
    double bollingerScore;
    if (bollingerBands.signal == 'OVERSOLD') {
      bollingerScore = 0.9;
    } else if (bollingerBands.signal == 'OVERBOUGHT') {
      bollingerScore = 0.1;
    } else {
      bollingerScore = 0.5;
    }
    
    final stochastic = technicalAnalysis.calculateStochastic(prices: prices);
    double stochasticScore;
    if (stochastic.oversold && stochastic.kLine < 30) {
      stochasticScore = 0.85;
    } else if (stochastic.overbought && stochastic.kLine > 70) {
      stochasticScore = 0.15;
    } else {
      stochasticScore = 0.5;
    }
    
    final avgVolume = volumes.reduce((a, b) => a + b) / volumes.length;
    final currentVolume = volumes.last;
    final volumeScore = (currentVolume / avgVolume) > 1.5 ? 0.8 : 0.5;
    
    final technicalScore = (macdScore * 0.25 + bollingerScore * 0.25 + 
                            stochasticScore * 0.25 + volumeScore * 0.25);
    
    final sentimentScore = (marketSentiment + 1) / 2;
    
    double whaleScore = 0.5;
    if (whaleTransactions.any((tx) => tx.contains('BUY'))) {
      whaleScore = 0.75;
    } else if (whaleTransactions.any((tx) => tx.contains('SELL'))) {
      whaleScore = 0.25;
    }
    
    final volatility = _calculateVolatility(prices);
    final riskScore = (technicalScore + 0.5 + sentimentScore + whaleScore) / 4;
    
    double positionSize = portfolioValue * (maxPositionSize / 100);
    positionSize *= riskScore;
    positionSize /= (1 + (volatility / 100));
    
    final atr = _calculateATR(prices);
    final stopLoss = currentPrice - (atr * 1.5);
    final takeProfit = currentPrice + (atr * 3.0);
    
    final confidence = riskScore;
    final shouldTrade = confidence > 0.65 && riskScore > minWinRateRequired;
    
    String signal = 'HOLD';
    if (shouldTrade) {
      signal = riskScore > 0.7 ? 'STRONG_BUY' : 'BUY';
    } else if (riskScore < 0.3) {
      signal = 'SELL';
    }
    
    return TradeDecision(
      symbol: symbol,
      signal: signal,
      confidence: confidence,
      entryPrice: currentPrice,
      stopLoss: stopLoss,
      takeProfit: takeProfit,
      positionSize: positionSize,
      riskRewardRatio: (takeProfit - currentPrice) / (currentPrice - stopLoss),
      technicalScore: technicalScore,
      patternScore: 0.6,
      sentimentScore: sentimentScore,
      whaleScore: whaleScore,
      volatility: volatility,
      reasoning: 'Automated decision',
    );
  }
  
  double _calculateVolatility(List<double> prices) {
    if (prices.length < 2) return 0;
    final mean = prices.reduce((a, b) => a + b) / prices.length;
    final variance = prices.map((p) => (p - mean) * (p - mean)).reduce((a, b) => a + b) / prices.length;
    return (variance.sqrt() / mean) * 100;
  }
  
  double _calculateATR(List<double> prices) {
    if (prices.length < 14) return prices.last * 0.02;
    double tr = 0;
    for (int i = 1; i < prices.length; i++) {
      final trueRange = (prices[i] - prices[i-1]).abs();
      tr += trueRange;
    }
    return tr / prices.length;
  }
}

class TradeDecision {
  final String symbol;
  final String signal;
  final double confidence;
  final double entryPrice;
  final double stopLoss;
  final double takeProfit;
  final double positionSize;
  final double riskRewardRatio;
  final double technicalScore;
  final double patternScore;
  final double sentimentScore;
  final double whaleScore;
  final double volatility;
  final String reasoning;
  
  TradeDecision({
    required this.symbol,
    required this.signal,
    required this.confidence,
    required this.entryPrice,
    required this.stopLoss,
    required this.takeProfit,
    required this.positionSize,
    required this.riskRewardRatio,
    required this.technicalScore,
    required this.patternScore,
    required this.sentimentScore,
    required this.whaleScore,
    required this.volatility,
    required this.reasoning,
  });
}
