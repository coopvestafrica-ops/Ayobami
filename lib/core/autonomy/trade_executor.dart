class AutonomousTradeExecutor {
  final String binanceApiKey;
  final String binanceSecret;
  final bool isDemoMode;
  
  final List<ExecutedTrade> tradeHistory = [];
  
  AutonomousTradeExecutor({
    required this.binanceApiKey,
    required this.binanceSecret,
    this.isDemoMode = false,
  });
  
  Future<ExecutedTrade?> executeBuy({
    required String symbol,
    required double quantity,
    required double entryPrice,
    required double stopLoss,
    required double takeProfit,
  }) async {
    final trade = ExecutedTrade(
      id: 'ORDER_${DateTime.now().millisecondsSinceEpoch}',
      symbol: symbol,
      side: 'BUY',
      quantity: quantity,
      price: entryPrice,
      stopLoss: stopLoss,
      takeProfit: takeProfit,
      timestamp: DateTime.now(),
      status: 'EXECUTED',
      isDemo: isDemoMode,
    );
    
    tradeHistory.add(trade);
    return trade;
  }
  
  Future<ExecutedTrade?> executeSell({
    required String symbol,
    required double quantity,
    required double exitPrice,
  }) async {
    final trade = ExecutedTrade(
      id: 'ORDER_${DateTime.now().millisecondsSinceEpoch}',
      symbol: symbol,
      side: 'SELL',
      quantity: quantity,
      price: exitPrice,
      timestamp: DateTime.now(),
      status: 'EXECUTED',
      isDemo: isDemoMode,
    );
    
    tradeHistory.add(trade);
    return trade;
  }
}

class ExecutedTrade {
  final String id;
  final String symbol;
  final String side;
  final double quantity;
  final double price;
  final double? stopLoss;
  final double? takeProfit;
  final DateTime timestamp;
  final String status;
  final bool isDemo;
  
  ExecutedTrade({
    required this.id,
    required this.symbol,
    required this.side,
    required this.quantity,
    required this.price,
    this.stopLoss,
    this.takeProfit,
    required this.timestamp,
    required this.status,
    required this.isDemo,
  });
}
