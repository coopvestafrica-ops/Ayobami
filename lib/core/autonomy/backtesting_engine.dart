import 'dart:math';

/// Backtesting Engine
/// Tests trading strategies against historical data to optimize profitability
class BacktestingEngine {
  final double initialBalance;
  double _currentBalance;
  int _totalTrades = 0;
  int _winningTrades = 0;
  double _maxDrawdown = 0.0;
  double _peakBalance = 0.0;

  BacktestingEngine({this.initialBalance = 10000.0}) : _currentBalance = initialBalance;

  /// Run a backtest for a given strategy and historical price data
  BacktestResult runTest({
    required List<double> historicalPrices,
    required StrategyFunction strategy,
    double stopLossPercent = 2.0,
    double takeProfitPercent = 5.0,
    double feePercent = 0.1,
  }) {
    _currentBalance = initialBalance;
    _peakBalance = initialBalance;
    _totalTrades = 0;
    _winningTrades = 0;
    _maxDrawdown = 0.0;

    bool inPosition = false;
    double entryPrice = 0.0;
    double positionSize = 0.0;

    for (int i = 20; i < historicalPrices.length; i++) {
      final window = historicalPrices.sublist(i - 20, i);
      final currentPrice = historicalPrices[i];

      // Update Max Drawdown
      if (_currentBalance > _peakBalance) _peakBalance = _currentBalance;
      final currentDrawdown = ((_peakBalance - _currentBalance) / _peakBalance) * 100;
      if (currentDrawdown > _maxDrawdown) _maxDrawdown = currentDrawdown;

      if (!inPosition) {
        // Strategy Check: Should we enter?
        final signal = strategy(window);
        if (signal == 'BUY') {
          inPosition = true;
          entryPrice = currentPrice;
          positionSize = (_currentBalance * 0.95) / entryPrice; // Use 95% of balance
          _currentBalance -= (_currentBalance * 0.95) * (feePercent / 100); // Pay fee
          _totalTrades++;
        }
      } else {
        // Exit Check: Stop Loss or Take Profit?
        final profitLoss = ((currentPrice - entryPrice) / entryPrice) * 100;

        if (profitLoss <= -stopLossPercent || profitLoss >= takeProfitPercent) {
          inPosition = false;
          final tradeResult = positionSize * currentPrice;
          _currentBalance = (_currentBalance * 0.05) + tradeResult;
          _currentBalance -= tradeResult * (feePercent / 100); // Pay fee
          
          if (profitLoss > 0) _winningTrades++;
        }
      }
    }

    return BacktestResult(
      initialBalance: initialBalance,
      finalBalance: _currentBalance,
      totalTrades: _totalTrades,
      winRate: _totalTrades > 0 ? (_winningTrades / _totalTrades) * 100 : 0,
      maxDrawdown: _maxDrawdown,
      netProfitPercent: ((_currentBalance - initialBalance) / initialBalance) * 100,
    );
  }
}

typedef StrategyFunction = String Function(List<double> priceWindow);

class BacktestResult {
  final double initialBalance;
  final double finalBalance;
  final int totalTrades;
  final double winRate;
  final double maxDrawdown;
  final double netProfitPercent;

  BacktestResult({
    required this.initialBalance,
    required this.finalBalance,
    required this.totalTrades,
    required this.winRate,
    required this.maxDrawdown,
    required this.netProfitPercent,
  });

  @override
  String toString() {
    return 'Backtest Result: Net Profit: ${netProfitPercent.toStringAsFixed(2)}%, Win Rate: ${winRate.toStringAsFixed(2)}%, Trades: $totalTrades, Max Drawdown: ${maxDrawdown.toStringAsFixed(2)}%';
  }
}
