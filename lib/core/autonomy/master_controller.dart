import 'autonomous_trading_engine.dart';
import 'exit_strategy_manager.dart';
import 'trade_executor.dart';
import 'risk_management.dart';

class AutonomousTradingController {
  final AutonomousTradingEngine tradingEngine;
  final ExitStrategyManager exitStrategy;
  final AutonomousTradeExecutor tradeExecutor;
  final RiskManagementSystem riskManagement;
  
  final List<ActivePosition> activePositions = [];
  final List<TradeLog> tradeLog = [];
  
  AutonomousTradingController({
    required this.tradingEngine,
    required this.exitStrategy,
    required this.tradeExecutor,
    required this.riskManagement,
  });
  
  Future<void> runTradingLoop({
    required String symbol,
    required List<double> prices,
    required List<double> volumes,
    required double portfolioValue,
    required double marketSentiment,
    required List<String> whaleTransactions,
  }) async {
    final currentPrice = prices.last;
    
    for (final position in activePositions) {
      if (position.symbol == symbol) {
        final exitSignal = await exitStrategy.shouldExit(
          symbol: symbol,
          entryPrice: position.entryPrice,
          stopLoss: position.stopLoss,
          takeProfit: position.takeProfit,
          currentPrice: currentPrice,
          profitTarget: position.profitTarget,
          timeInTrade: DateTime.now().difference(position.entryTime).inMinutes,
          priceHistory: prices,
        );
        
        if (exitSignal != null && exitSignal.recommendedAction == 'EXIT_NOW') {
          print('⏹️ EXIT: ${exitSignal.action} | P&L: ${exitSignal.profitLoss.toStringAsFixed(2)}%');
          
          await tradeExecutor.executeSell(
            symbol: symbol,
            quantity: position.quantity,
            exitPrice: currentPrice,
          );
          
          activePositions.remove(position);
          return;
        }
      }
    }
    
    final decision = await tradingEngine.makeTradeDecision(
      symbol: symbol,
      prices: prices,
      volumes: volumes,
      currentPrice: currentPrice,
      portfolioValue: portfolioValue,
      entryPrices: [],
      holdings: {},
      marketSentiment: marketSentiment,
      whaleTransactions: whaleTransactions,
    );
    
    if (decision.signal == 'STRONG_BUY' || decision.signal == 'BUY') {
      print('✅ BUY SIGNAL: ${decision.signal} (Confidence: ${(decision.confidence*100).toStringAsFixed(0)}%)');
      
      final buyTrade = await tradeExecutor.executeBuy(
        symbol: symbol,
        quantity: decision.positionSize,
        entryPrice: decision.entryPrice,
        stopLoss: decision.stopLoss,
        takeProfit: decision.takeProfit,
      );
      
      if (buyTrade != null) {
        activePositions.add(ActivePosition(
          id: buyTrade.id,
          symbol: symbol,
          entryPrice: buyTrade.price,
          quantity: buyTrade.quantity,
          stopLoss: buyTrade.stopLoss!,
          takeProfit: buyTrade.takeProfit!,
          profitTarget: decision.riskRewardRatio * 100,
          entryTime: DateTime.now(),
        ));
      }
    }
  }
}

class ActivePosition {
  final String id;
  final String symbol;
  final double entryPrice;
  final double quantity;
  final double stopLoss;
  final double takeProfit;
  final double profitTarget;
  final DateTime entryTime;
  
  ActivePosition({
    required this.id,
    required this.symbol,
    required this.entryPrice,
    required this.quantity,
    required this.stopLoss,
    required this.takeProfit,
    required this.profitTarget,
    required this.entryTime,
  });
}

class TradeLog {
  final String tradeId;
  final String symbol;
  final String side;
  final double quantity;
  final double price;
  final DateTime timestamp;
  
  TradeLog({
    required this.tradeId,
    required this.symbol,
    required this.side,
    required this.quantity,
    required this.price,
    required this.timestamp,
  });
}
