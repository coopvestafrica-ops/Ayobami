import 'package:intl/intl.dart';

/// Advanced Portfolio Analytics & Reporting
class PortfolioAnalytics {
  /// Generate comprehensive portfolio report
  PortfolioReport generateReport({
    required Map<String, double> holdings,
    required Map<String, double> entryPrices,
    required Map<String, double> currentPrices,
  }) {
    double totalValue = 0;
    double totalCost = 0;
    final positions = <PositionMetric>[];
    
    for (final symbol in holdings.keys) {
      final quantity = holdings[symbol]!;
      final entryPrice = entryPrices[symbol] ?? 0;
      final currentPrice = currentPrices[symbol] ?? 0;
      
      final costBasis = quantity * entryPrice;
      final currentValue = quantity * currentPrice;
      final gainLoss = currentValue - costBasis;
      final gainLossPercent = (gainLoss / costBasis) * 100;
      
      totalValue += currentValue;
      totalCost += costBasis;
      
      positions.add(PositionMetric(
        symbol: symbol,
        quantity: quantity,
        entryPrice: entryPrice,
        currentPrice: currentPrice,
        costBasis: costBasis,
        currentValue: currentValue,
        gainLoss: gainLoss,
        gainLossPercent: gainLossPercent,
        weight: 0, // Calculated after loop
      ));
    }
    
    // Calculate portfolio weights
    for (final pos in positions) {
      pos.weight = (pos.currentValue / totalValue) * 100;
    }
    
    final totalGainLoss = totalValue - totalCost;
    final totalReturn = (totalGainLoss / totalCost) * 100;
    
    return PortfolioReport(
      totalValue: totalValue,
      totalCost: totalCost,
      totalGainLoss: totalGainLoss,
      totalReturn: totalReturn,
      positions: positions,
      diversificationScore: _calculateDiversification(positions),
      riskScore: _calculateRisk(positions),
      sharpeRatio: _calculateSharpeRatio(positions),
      concentrationRisk: _findConcentration(positions),
    );
  }
  
  double _calculateDiversification(List<PositionMetric> positions) {
    // Herfindahl-Hirschman Index: 0-100, higher = more concentrated
    double hhi = 0;
    for (final pos in positions) {
      hhi += (pos.weight) * (pos.weight);
    }
    return 100 - (hhi / 100); // Normalize to 0-100
  }
  
  double _calculateRisk(List<PositionMetric> positions) {
    // Calculate portfolio volatility
    double volatility = 0;
    for (final pos in positions) {
      volatility += pos.gainLossPercent.abs() * (pos.weight / 100);
    }
    return volatility;
  }
  
  double _calculateSharpeRatio(List<PositionMetric> positions) {
    // Simplified Sharpe Ratio (return / volatility)
    const riskFreeRate = 2.0; // 2% annual
    double avgReturn = positions.isEmpty ? 0 
        : positions.map((p) => p.gainLossPercent).reduce((a, b) => a + b) / positions.length;
    double volatility = _calculateRisk(positions);
    return volatility == 0 ? 0 : (avgReturn - riskFreeRate) / volatility;
  }
  
  String _findConcentration(List<PositionMetric> positions) {
    if (positions.isEmpty) return 'None';
    final topPosition = positions.reduce((a, b) => a.weight > b.weight ? a : b);
    if (topPosition.weight > 50) return 'CRITICAL';
    if (topPosition.weight > 30) return 'HIGH';
    if (topPosition.weight > 20) return 'MODERATE';
    return 'HEALTHY';
  }
}

class PortfolioReport {
  final double totalValue;
  final double totalCost;
  final double totalGainLoss;
  final double totalReturn;
  final List<PositionMetric> positions;
  final double diversificationScore;
  final double riskScore;
  final double sharpeRatio;
  final String concentrationRisk;
  
  PortfolioReport({
    required this.totalValue,
    required this.totalCost,
    required this.totalGainLoss,
    required this.totalReturn,
    required this.positions,
    required this.diversificationScore,
    required this.riskScore,
    required this.sharpeRatio,
    required this.concentrationRisk,
  });
}

class PositionMetric {
  final String symbol;
  final double quantity;
  final double entryPrice;
  final double currentPrice;
  final double costBasis;
  final double currentValue;
  final double gainLoss;
  final double gainLossPercent;
  double weight;
  
  PositionMetric({
    required this.symbol,
    required this.quantity,
    required this.entryPrice,
    required this.currentPrice,
    required this.costBasis,
    required this.currentValue,
    required this.gainLoss,
    required this.gainLossPercent,
    required this.weight,
  });
}
