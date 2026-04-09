class ExitStrategyManager {
  Future<ExitSignal?> shouldExit({
    required String symbol,
    required double entryPrice,
    required double stopLoss,
    required double takeProfit,
    required double currentPrice,
    required double profitTarget,
    required int timeInTrade,
    required List<double> priceHistory,
  }) async {
    if (currentPrice <= stopLoss) {
      return ExitSignal(
        action: 'STOP_LOSS',
        exitPrice: currentPrice,
        reason: 'Hit stop loss',
        profitLoss: ((currentPrice - entryPrice) / entryPrice) * 100,
        recommendedAction: 'EXIT_NOW',
      );
    }
    
    if (currentPrice >= takeProfit) {
      return ExitSignal(
        action: 'TAKE_PROFIT',
        exitPrice: currentPrice,
        reason: 'Target profit reached',
        profitLoss: ((currentPrice - entryPrice) / entryPrice) * 100,
        recommendedAction: 'EXIT_NOW',
      );
    }
    
    final highestPrice = priceHistory.reduce((a, b) => a > b ? a : b);
    final trailingStopDistance = (highestPrice - entryPrice) * 0.4;
    final trailingStop = highestPrice - trailingStopDistance;
    
    if (currentPrice <= trailingStop && currentPrice > stopLoss) {
      return ExitSignal(
        action: 'TRAILING_STOP',
        exitPrice: currentPrice,
        reason: 'Trailing stop activated',
        profitLoss: ((currentPrice - entryPrice) / entryPrice) * 100,
        recommendedAction: 'EXIT_NOW',
      );
    }
    
    return null;
  }
}

class ExitSignal {
  final String action;
  final double exitPrice;
  final String reason;
  final double profitLoss;
  final String recommendedAction;
  
  ExitSignal({
    required this.action,
    required this.exitPrice,
    required this.reason,
    required this.profitLoss,
    required this.recommendedAction,
  });
}
