/// Portfolio Insurance - Hedging & Risk Protection
class PortfolioInsurance {
  /// Create put option hedge for downside protection
  Future<HedgePosition> createPutHedge({
    required String symbol,
    required double portfolioValue,
    required double strikePrice,
    required DateTime expiryDate,
  }) async {
    final premiumCost = _calculatePremium(portfolioValue, strikePrice);
    
    return HedgePosition(
      type: 'PUT_OPTION',
      symbol: symbol,
      notionalValue: portfolioValue,
      strikePrice: strikePrice,
      premium: premiumCost,
      protectionLevel: ((portfolioValue - strikePrice) / portfolioValue) * 100,
      expiryDate: expiryDate,
      status: 'ACTIVE',
    );
  }
  
  /// Create collar strategy (buy put + sell call)
  Future<HedgePosition> createCollar({
    required String symbol,
    required double portfolioValue,
    required double putStrike,
    required double callStrike,
  }) async {
    final putPremium = _calculatePremium(portfolioValue, putStrike);
    final callPremium = _calculatePremium(portfolioValue, callStrike);
    final netCost = putPremium - callPremium;
    
    return HedgePosition(
      type: 'COLLAR',
      symbol: symbol,
      notionalValue: portfolioValue,
      strikePrice: putStrike,
      premium: netCost,
      protectionLevel: 95,
      expiryDate: DateTime.now().add(Duration(days: 90)),
      status: 'ACTIVE',
    );
  }
  
  /// Get insurance recommendations
  Future<List<InsuranceRecommendation>> getRecommendations({
    required double portfolioValue,
    required double volatility,
    required double maxDrawdown,
  }) async {
    return [
      InsuranceRecommendation(
        type: 'PUT_HEDGE',
        description: 'Protect against 20%+ downside',
        cost: portfolioValue * 0.02,
        protection: '20% downside protection',
        recommended: volatility > 50,
      ),
      InsuranceRecommendation(
        type: 'COLLAR',
        description: 'Low-cost protection with capped upside',
        cost: portfolioValue * 0.005,
        protection: '15% protection, 10% max gain',
        recommended: volatility > 40,
      ),
    ];
  }
  
  double _calculatePremium(double value, double strike) {
    // Simplified Black-Scholes approximation
    return value * 0.02; // 2% premium
  }
}

class HedgePosition {
  final String type;
  final String symbol;
  final double notionalValue;
  final double strikePrice;
  final double premium;
  final double protectionLevel;
  final DateTime expiryDate;
  final String status;
  
  HedgePosition({
    required this.type,
    required this.symbol,
    required this.notionalValue,
    required this.strikePrice,
    required this.premium,
    required this.protectionLevel,
    required this.expiryDate,
    required this.status,
  });
}

class InsuranceRecommendation {
  final String type;
  final String description;
  final double cost;
  final String protection;
  final bool recommended;
  
  InsuranceRecommendation({
    required this.type,
    required this.description,
    required this.cost,
    required this.protection,
    required this.recommended,
  });
}
