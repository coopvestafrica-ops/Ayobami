/// Tax-optimized Portfolio Rebalancing
class PortfolioRebalancer {
  /// Calculate optimal rebalancing to target allocation
  Future<List<RebalanceAction>> calculateRebalancing({
    required Map<String, double> currentHoldings,
    required Map<String, double> targetAllocation,
  }) async {
    final actions = <RebalanceAction>[];
    final totalValue = currentHoldings.values.fold(0.0, (a, b) => a + b);
    
    for (final entry in targetAllocation.entries) {
      final asset = entry.key;
      final targetPercent = entry.value;
      final targetValue = totalValue * (targetPercent / 100);
      final currentValue = currentHoldings[asset] ?? 0;
      final diff = targetValue - currentValue;
      
      if (diff.abs() > 100) { // Min \$100 transaction
        actions.add(RebalanceAction(
          asset: asset,
          action: diff > 0 ? 'buy' : 'sell',
          amount: diff.abs(),
          estimatedGasFee: 50,
        ));
      }
    }
    return actions;
  }
}

class RebalanceAction {
  final String asset;
  final String action;
  final double amount;
  final double estimatedGasFee;
  
  RebalanceAction({
    required this.asset,
    required this.action,
    required this.amount,
    required this.estimatedGasFee,
  });
}
