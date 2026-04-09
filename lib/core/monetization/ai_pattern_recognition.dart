/// AI-Powered Candlestick Pattern Recognition
class AIPatternRecognition {
  /// Detect advanced candlestick patterns
  List<CandlestickPattern> detectPatterns(List<Candle> candles) {
    final patterns = <CandlestickPattern>[];
    
    for (int i = 2; i < candles.length; i++) {
      // Bullish patterns
      if (_isMorningStar(candles, i)) {
        patterns.add(CandlestickPattern(
          name: 'Morning Star',
          type: 'bullish',
          strength: 0.8,
          confidence: 0.85,
          position: i,
        ));
      }
      
      if (_isHammer(candles, i)) {
        patterns.add(CandlestickPattern(
          name: 'Hammer',
          type: 'bullish',
          strength: 0.7,
          confidence: 0.75,
          position: i,
        ));
      }
      
      // Bearish patterns
      if (_isShootingStar(candles, i)) {
        patterns.add(CandlestickPattern(
          name: 'Shooting Star',
          type: 'bearish',
          strength: 0.75,
          confidence: 0.80,
          position: i,
        ));
      }
      
      if (_isEngulfing(candles, i)) {
        patterns.add(CandlestickPattern(
          name: 'Engulfing',
          type: candles[i].close > candles[i-1].close ? 'bullish' : 'bearish',
          strength: 0.85,
          confidence: 0.90,
          position: i,
        ));
      }
    }
    
    return patterns;
  }
  
  bool _isMorningStar(List<Candle> candles, int i) {
    return candles[i-2].close > candles[i-2].open &&
           candles[i-1].close < candles[i-1].open &&
           candles[i].close > candles[i].open;
  }
  
  bool _isHammer(List<Candle> candles, int i) {
    final body = (candles[i].close - candles[i].open).abs();
    final lowerWick = candles[i].open - candles[i].low;
    return lowerWick > body * 2;
  }
  
  bool _isShootingStar(List<Candle> candles, int i) {
    final body = (candles[i].close - candles[i].open).abs();
    final upperWick = candles[i].high - candles[i].close;
    return upperWick > body * 2;
  }
  
  bool _isEngulfing(List<Candle> candles, int i) {
    return candles[i].high > candles[i-1].high &&
           candles[i].low < candles[i-1].low;
  }
}

class Candle {
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  
  Candle({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });
}

class CandlestickPattern {
  final String name;
  final String type; // 'bullish' or 'bearish'
  final double strength;
  final double confidence;
  final int position;
  
  CandlestickPattern({
    required this.name,
    required this.type,
    required this.strength,
    required this.confidence,
    required this.position,
  });
}
