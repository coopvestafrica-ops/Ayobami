/// Track positions about to liquidate for arbitrage opportunities
class LiquidationAlertService {
  /// Get positions near liquidation on lending protocols
  Future<List<LiquidationRisk>> getLiquidationAlerts() async {
    return [
      LiquidationRisk(
        protocol: 'Aave',
        borrower: '0x1234...',
        borrowedAsset: 'USDC',
        borrowedAmount: 100000,
        collateral: 'ETH',
        collateralAmount: 50,
        liquidationPrice: 1200,
        currentPrice: 1250,
        riskPercent: 96,
        timeToLiquidation: Duration(hours: 2),
      ),
    ];
  }
}

class LiquidationRisk {
  final String protocol;
  final String borrower;
  final String borrowedAsset;
  final double borrowedAmount;
  final String collateral;
  final double collateralAmount;
  final double liquidationPrice;
  final double currentPrice;
  final double riskPercent;
  final Duration timeToLiquidation;
  
  LiquidationRisk({
    required this.protocol,
    required this.borrower,
    required this.borrowedAsset,
    required this.borrowedAmount,
    required this.collateral,
    required this.collateralAmount,
    required this.liquidationPrice,
    required this.currentPrice,
    required this.riskPercent,
    required this.timeToLiquidation,
  });
}
