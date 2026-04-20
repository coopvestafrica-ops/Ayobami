import 'package:ayobami/domain/entities/crypto_currency.dart';
import 'package:ayobami/core/monetization/technical_analysis.dart';
import 'package:ayobami/core/services/binance_api_service.dart';

/// Market Sentiment Enum
enum MarketSentiment {
  bullish('Bullish', '🚀', 'Market is showing strong upward momentum'),
  bearish('Bearish', '📉', 'Market is under selling pressure'),
  neutral('Neutral', '⚖️', 'Market is consolidating'),
  fearful('Fearful', '😨', 'High volatility and negative sentiment'),
  greedy('Greedy', '🤑', 'Extreme optimism and potential overextension');

  final String displayName;
  final String emoji;
  final String description;

  const MarketSentiment(this.displayName, this.emoji, this.description);
}

/// AI Trading Signal Generator.
///
/// Uses real historical candle closes from Binance's public `/klines` endpoint
/// to compute RSI / MACD / Bollinger indicators. If Binance is unreachable or
/// the symbol is not listed, the crypto is skipped rather than emitting a
/// signal based on noise.
class AITradingSignals {
  final PremiumTechnicalAnalysis _technicalAnalysis = PremiumTechnicalAnalysis();
  final BinanceApiService _binanceApi;

  /// Number of historical candles pulled per signal computation.
  static const int _historyLength = 100;

  /// Candle interval used for signal computation.
  static const String _interval = '1h';

  AITradingSignals({BinanceApiService? binanceApi})
      : _binanceApi = binanceApi ?? BinanceApiService();

  /// Generate trading signals for a list of cryptocurrencies.
  ///
  /// Fetches real historical closes per symbol in parallel. Symbols that
  /// Binance does not recognise (or for which the API call fails) are
  /// silently skipped.
  Future<List<TradingSignal>> analyzeMarket(List<CryptoCurrency> cryptos) async {
    final results = await Future.wait(
      cryptos.map(_analyzeCrypto),
      eagerError: false,
    );

    final signals = results.whereType<TradingSignal>().toList();
    signals.sort((a, b) => b.confidence.compareTo(a.confidence));
    return signals;
  }

  /// Analyze market sentiment from the 24h price-change distribution.
  /// This uses data already present on the CryptoCurrency entity and does
  /// not need a network call.
  MarketSentiment analyzeSentiment(List<CryptoCurrency> cryptos) {
    if (cryptos.isEmpty) return MarketSentiment.neutral;

    int upCount = 0;
    double avgChange = 0;

    for (final crypto in cryptos) {
      if (crypto.priceChangePercentage24h > 0) upCount++;
      avgChange += crypto.priceChangePercentage24h;
    }

    avgChange /= cryptos.length;
    final double upRatio = upCount / cryptos.length;

    if (avgChange > 5 && upRatio > 0.8) return MarketSentiment.greedy;
    if (avgChange > 1 && upRatio > 0.6) return MarketSentiment.bullish;
    if (avgChange < -5 && upRatio < 0.2) return MarketSentiment.fearful;
    if (avgChange < -1 && upRatio < 0.4) return MarketSentiment.bearish;

    return MarketSentiment.neutral;
  }

  /// Analyze a single cryptocurrency using real historical closes.
  Future<TradingSignal?> _analyzeCrypto(CryptoCurrency crypto) async {
    final symbol = _toBinanceSymbol(crypto.symbol);

    final prices = await _binanceApi.getKlineCloses(
      symbol,
      interval: _interval,
      limit: _historyLength,
    );

    // Require enough history for RSI / Bollinger to be meaningful.
    if (prices.length < 30) return null;

    final rsi = _calculateRSI(prices);
    final bb = _technicalAnalysis.calculateBollingerBands(prices: prices);

    String type = 'hold';
    double confidence = 0.5;
    String reason = 'Neutral market conditions';

    if (rsi < 35 && bb.signal == 'OVERSOLD') {
      type = 'buy';
      confidence = 0.88;
      reason = 'Strong Buy: RSI Oversold & Price at Bollinger Lower Band';
    } else if (rsi < 50 && rsi > 40) {
      type = 'buy';
      confidence = 0.72;
      reason = 'Moderate Buy: Recovery from dip with positive momentum';
    } else if (rsi > 65 || bb.signal == 'OVERBOUGHT') {
      type = 'sell';
      confidence = 0.85;
      reason = 'Strong Sell: RSI Overbought & Price at Bollinger Upper Band';
    } else if (rsi > 55) {
      type = 'sell';
      confidence = 0.68;
      reason = 'Moderate Sell: Weakening price action';
    }

    return TradingSignal(
      symbol: crypto.symbol.toUpperCase(),
      type: type,
      price: crypto.currentPrice,
      targetPrice: type == 'buy'
          ? crypto.currentPrice * 1.08
          : crypto.currentPrice * 0.95,
      stopLoss: type == 'buy'
          ? crypto.currentPrice * 0.96
          : crypto.currentPrice * 1.03,
      confidence: confidence,
      reason: reason,
      timestamp: DateTime.now(),
    );
  }

  /// Wilder-style RSI over the default 14 period.
  double _calculateRSI(List<double> prices, {int period = 14}) {
    if (prices.length <= period) return 50.0;

    double gains = 0;
    double losses = 0;
    for (int i = prices.length - period; i < prices.length; i++) {
      final diff = prices[i] - prices[i - 1];
      if (diff >= 0) {
        gains += diff;
      } else {
        losses -= diff;
      }
    }

    if (losses == 0) return 100.0;
    final rs = gains / losses;
    return 100 - (100 / (1 + rs));
  }

  /// Get a signal for a single crypto. Returns null if no historical data
  /// is available (e.g. symbol not listed on Binance).
  Future<TradingSignal?> getSignalFor(CryptoCurrency crypto) =>
      _analyzeCrypto(crypto);

  /// Convert a CoinGecko-style ticker (e.g. "btc", "eth") to Binance's
  /// USDT pair format ("BTCUSDT"). Symbols that already include a quote
  /// currency are passed through.
  String _toBinanceSymbol(String raw) {
    final upper = raw.toUpperCase();
    if (upper.endsWith('USDT') || upper.endsWith('USD') || upper.endsWith('BTC')) {
      return upper;
    }
    return '${upper}USDT';
  }
}
// `TradingSignal` itself lives in `lib/domain/entities/crypto_currency.dart`
// and is re-exported here for convenience so callers only need one import.
