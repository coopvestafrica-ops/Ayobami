/// Premium Technical Analysis Indicators
class PremiumTechnicalAnalysis {
  /// Calculate MACD (Moving Average Convergence Divergence)
  MACDIndicator calculateMACD({
    required List<double> prices,
    int fastPeriod = 12,
    int slowPeriod = 26,
    int signalPeriod = 9,
  }) {
    final ema12 = _calculateEMA(prices, fastPeriod);
    final ema26 = _calculateEMA(prices, slowPeriod);
    final macdLine = ema12 - ema26;
    
    return MACDIndicator(
      macdLine: macdLine,
      signalLine: 0, // Simplified
      histogram: 0, // Simplified
    );
  }
  
  /// Calculate Bollinger Bands
  BollingerBands calculateBollingerBands({
    required List<double> prices,
    int period = 20,
    double stdDevs = 2.0,
  }) {
    final sma = prices.reduce((a, b) => a + b) / prices.length;
    final variance = prices
        .map((p) => (p - sma) * (p - sma))
        .reduce((a, b) => a + b) / prices.length;
    final stdDev = (variance).sqrt();
    
    return BollingerBands(
      upper: sma + (stdDev * stdDevs),
      middle: sma,
      lower: sma - (stdDev * stdDevs),
      price: prices.last,
    );
  }
  
  /// Calculate Stochastic Oscillator
  StochasticOscillator calculateStochastic({
    required List<double> prices,
    int period = 14,
  }) {
    final recent = prices.sublist(prices.length - period);
    final high = recent.reduce((a, b) => a > b ? a : b);
    final low = recent.reduce((a, b) => a < b ? a : b);
    final kLine = ((prices.last - low) / (high - low)) * 100;
    
    return StochasticOscillator(
      kLine: kLine,
      dLine: 0, // Simplified
      overbought: kLine > 80,
      oversold: kLine < 20,
    );
  }
  
  /// Calculate Volume Weighted Average Price (VWAP)
  double calculateVWAP({
    required List<double> prices,
    required List<double> volumes,
  }) {
    double numerator = 0;
    double denominator = 0;
    
    for (int i = 0; i < prices.length; i++) {
      numerator += prices[i] * volumes[i];
      denominator += volumes[i];
    }
    
    return numerator / denominator;
  }
  
  double _calculateEMA(List<double> prices, int period) {
    final k = 2.0 / (period + 1);
    var ema = prices.take(period).reduce((a, b) => a + b) / period;
    
    for (int i = period; i < prices.length; i++) {
      ema = (prices[i] * k) + (ema * (1 - k));
    }
    return ema;
  }
}

class MACDIndicator {
  final double macdLine;
  final double signalLine;
  final double histogram;
  
  MACDIndicator({
    required this.macdLine,
    required this.signalLine,
    required this.histogram,
  });
}

class BollingerBands {
  final double upper;
  final double middle;
  final double lower;
  final double price;
  
  BollingerBands({
    required this.upper,
    required this.middle,
    required this.lower,
    required this.price,
  });
  
  String get signal {
    if (price > upper) return 'OVERBOUGHT';
    if (price < lower) return 'OVERSOLD';
    return 'NEUTRAL';
  }
}

class StochasticOscillator {
  final double kLine;
  final double dLine;
  final bool overbought;
  final bool oversold;
  
  StochasticOscillator({
    required this.kLine,
    required this.dLine,
    required this.overbought,
    required this.oversold,
  });
}
