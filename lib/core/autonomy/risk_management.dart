class RiskManagementSystem {
  final double maxDailyLoss;
  final double maxDrawdown;
  final double positionSizePercent;
  final int maxConcurrentTrades;
  
  RiskManagementSystem({
    this.maxDailyLoss = 5.0,
    this.maxDrawdown = 15.0,
    this.positionSizePercent = 3.0,
    this.maxConcurrentTrades = 3,
  });
  
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
        message: 'Daily loss limit reached',
      );
    }
    
    if (drawdown > maxDrawdown) {
      return RiskAssessment(
        canTrade: false,
        dailyLossPercent: dailyLossPercent,
        drawdown: drawdown,
        activePositions: activePositions,
        reason: 'MAX_DRAWDOWN_EXCEEDED',
        message: 'Maximum drawdown exceeded',
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
