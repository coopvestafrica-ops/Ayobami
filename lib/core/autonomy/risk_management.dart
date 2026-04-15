import 'dart:math';

/// Advanced Risk Management System
/// Handles dynamic position sizing, trailing stops, and portfolio protection
class RiskManagementSystem {
  final double maxDailyLoss;
  final double maxDrawdown;
  final double basePositionSizePercent;
  final int maxConcurrentTrades;
  
  RiskManagementSystem({
    this.maxDailyLoss = 5.0,
    this.maxDrawdown = 15.0,
    this.basePositionSizePercent = 2.0, // Safer default
    this.maxConcurrentTrades = 5,
  });
  
  /// Assess if a trade is safe to execute
  RiskAssessment canTrade({
    required double portfolioValue,
    required double todaysLoss,
    required double maxPortfolioValue,
    required int activePositions,
  }) {
    final dailyLossPercent = (todaysLoss / portfolioValue) * 100;
    final drawdown = ((maxPortfolioValue - portfolioValue) / maxPortfolioValue) * 100;
    
    if (dailyLossPercent > maxDailyLoss) {
      return RiskAssessment(
        canTrade: false,
        dailyLossPercent: dailyLossPercent,
        drawdown: drawdown,
        activePositions: activePositions,
        reason: 'DAILY_LOSS_LIMIT_HIT',
        message: 'Daily loss limit reached. Trading suspended for today.',
      );
    }
    
    if (drawdown > maxDrawdown) {
      return RiskAssessment(
        canTrade: false,
        dailyLossPercent: dailyLossPercent,
        drawdown: drawdown,
        activePositions: activePositions,
        reason: 'MAX_DRAWDOWN_EXCEEDED',
        message: 'Maximum drawdown exceeded. Strategy review required.',
      );
    }

    if (activePositions >= maxConcurrentTrades) {
      return RiskAssessment(
        canTrade: false,
        dailyLossPercent: dailyLossPercent,
        drawdown: drawdown,
        activePositions: activePositions,
        reason: 'MAX_TRADES_REACHED',
        message: 'Maximum concurrent trades reached.',
      );
    }
    
    return RiskAssessment(
      canTrade: true,
      dailyLossPercent: dailyLossPercent,
      drawdown: drawdown,
      activePositions: activePositions,
      reason: 'OK',
      message: 'Safe to trade',
    );
  }

  /// Calculate dynamic position size based on volatility (ATR) and confidence
  double calculateDynamicPositionSize({
    required double portfolioValue,
    required double entryPrice,
    required double stopLossPrice,
    required double volatilityScore, // 0 to 1, higher means more volatile
    required double signalConfidence, // 0 to 1
  }) {
    // 1. Calculate Risk Amount (Amount to lose if stop loss is hit)
    // Adjust risk based on confidence: higher confidence = slightly more risk
    final confidenceMultiplier = 0.5 + (signalConfidence * 0.5); // 0.5x to 1.0x
    final riskAmount = portfolioValue * (basePositionSizePercent / 100) * confidenceMultiplier;
    
    // 2. Adjust for volatility
    // If market is extremely volatile, reduce position size
    final volatilityMultiplier = 1.0 - (volatilityScore * 0.3); // 0.7x to 1.0x
    final adjustedRiskAmount = riskAmount * volatilityMultiplier;
    
    // 3. Calculate Quantity
    final priceRisk = (entryPrice - stopLossPrice).abs();
    if (priceRisk == 0) return 0;
    
    return adjustedRiskAmount / priceRisk;
  }

  /// Calculate Trailing Stop Price
  /// Adjusts as price moves in favor of the trade
  double calculateTrailingStop({
    required double currentPrice,
    required double highestPriceSinceEntry,
    required double entryPrice,
    double trailPercent = 2.5,
  }) {
    // Only trail if we are in profit
    if (currentPrice <= entryPrice) return entryPrice * 0.95; // Initial SL

    final profitPercent = ((highestPriceSinceEntry - entryPrice) / entryPrice) * 100;
    
    // Tighten stop as profit increases
    double effectiveTrail = trailPercent;
    if (profitPercent > 5.0) effectiveTrail = trailPercent * 0.8; // Tighten
    if (profitPercent > 10.0) effectiveTrail = trailPercent * 0.5; // Lock in gains
    
    return highestPriceSinceEntry * (1 - (effectiveTrail / 100));
  }
}

class RiskAssessment {
  final bool canTrade;
  final double dailyLossPercent;
  final double drawdown;
  final int activePositions;
  final String reason;
  final String message;
  
  RiskAssessment({
    required this.canTrade,
    required this.dailyLossPercent,
    required this.drawdown,
    required this.activePositions,
    required this.reason,
    required this.message,
  });
}
