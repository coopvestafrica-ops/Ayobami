import 'package:equatable/equatable.dart';

class CryptoCurrency extends Equatable {
  final String id;
  final String symbol;
  final String name;
  final String image;
  final double currentPrice;
  final double marketCap;
  final int marketCapRank;
  final double priceChange24h;
  final double priceChangePercentage24h;
  final double high24h;
  final double low24h;
  final double totalVolume;
  final List<double>? sparklineData;
  
  const CryptoCurrency({
    required this.id,
    required this.symbol,
    required this.name,
    required this.image,
    required this.currentPrice,
    required this.marketCap,
    required this.marketCapRank,
    required this.priceChange24h,
    required this.priceChangePercentage24h,
    required this.high24h,
    required this.low24h,
    required this.totalVolume,
    this.sparklineData,
  });
  
  bool get isPriceUp => priceChangePercentage24h >= 0;

  CryptoCurrency copyWith({
    String? id,
    String? symbol,
    String? name,
    String? image,
    double? currentPrice,
    double? marketCap,
    int? marketCapRank,
    double? priceChange24h,
    double? priceChangePercentage24h,
    double? high24h,
    double? low24h,
    double? totalVolume,
    List<double>? sparklineData,
  }) {
    return CryptoCurrency(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      image: image ?? this.image,
      currentPrice: currentPrice ?? this.currentPrice,
      marketCap: marketCap ?? this.marketCap,
      marketCapRank: marketCapRank ?? this.marketCapRank,
      priceChange24h: priceChange24h ?? this.priceChange24h,
      priceChangePercentage24h: priceChangePercentage24h ?? this.priceChangePercentage24h,
      high24h: high24h ?? this.high24h,
      low24h: low24h ?? this.low24h,
      totalVolume: totalVolume ?? this.totalVolume,
      sparklineData: sparklineData ?? this.sparklineData,
    );
  }
  
  @override
  List<Object?> get props => [
    id, symbol, name, image, currentPrice, marketCap, marketCapRank,
    priceChange24h, priceChangePercentage24h, high24h, low24h, totalVolume, sparklineData
  ];
}

class ForexPair extends Equatable {
  final String baseCurrency;
  final String quoteCurrency;
  final String pair;
  final double rate;
  final double change24h;
  final DateTime lastUpdated;
  
  const ForexPair({
    required this.baseCurrency,
    required this.quoteCurrency,
    required this.pair,
    required this.rate,
    required this.change24h,
    required this.lastUpdated,
  });
  
  bool get isUp => change24h >= 0;

  ForexPair copyWith({
    String? baseCurrency,
    String? quoteCurrency,
    String? pair,
    double? rate,
    double? change24h,
    DateTime? lastUpdated,
  }) {
    return ForexPair(
      baseCurrency: baseCurrency ?? this.baseCurrency,
      quoteCurrency: quoteCurrency ?? this.quoteCurrency,
      pair: pair ?? this.pair,
      rate: rate ?? this.rate,
      change24h: change24h ?? this.change24h,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
  
  @override
  List<Object?> get props => [baseCurrency, quoteCurrency, pair, rate, change24h, lastUpdated];
}

class MarketData extends Equatable {
  final List<CryptoCurrency> cryptos;
  final List<ForexPair> forexPairs;
  final DateTime lastUpdated;
  
  const MarketData({
    required this.cryptos,
    required this.forexPairs,
    required this.lastUpdated,
  });
  
  @override
  List<Object?> get props => [cryptos, forexPairs, lastUpdated];
}

class TradingSignal extends Equatable {
  final String symbol;
  final String type; // buy, sell, hold
  final double price;
  final double targetPrice;
  final double stopLoss;
  final double confidence;
  final String reason;
  final DateTime timestamp;
  
  const TradingSignal({
    required this.symbol,
    required this.type,
    required this.price,
    required this.targetPrice,
    required this.stopLoss,
    required this.confidence,
    required this.reason,
    required this.timestamp,
  });
  
  @override
  List<Object?> get props => [symbol, type, price, targetPrice, stopLoss, confidence, reason, timestamp];
}
