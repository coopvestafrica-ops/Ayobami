import 'package:ayobami/domain/entities/crypto_currency.dart';

class CryptoCurrencyModel extends CryptoCurrency {
  const CryptoCurrencyModel({
    required super.id,
    required super.symbol,
    required super.name,
    required super.image,
    required super.currentPrice,
    required super.marketCap,
    required super.marketCapRank,
    required super.priceChange24h,
    required super.priceChangePercentage24h,
    required super.high24h,
    required super.low24h,
    required super.totalVolume,
    super.sparklineData,
  });

  factory CryptoCurrencyModel.fromJson(Map<String, dynamic> json) {
    List<double>? sparkline;
    if (json['sparkline_in_7d'] != null && json['sparkline_in_7d']['price'] != null) {
      sparkline = (json['sparkline_in_7d']['price'] as List)
          .map((e) => (e as num).toDouble())
          .toList();
    }

    return CryptoCurrencyModel(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      image: json['image'] as String? ?? '',
      currentPrice: (json['current_price'] as num?)?.toDouble() ?? 0.0,
      marketCap: (json['market_cap'] as num?)?.toDouble() ?? 0.0,
      marketCapRank: json['market_cap_rank'] as int? ?? 0,
      priceChange24h: (json['price_change_24h'] as num?)?.toDouble() ?? 0.0,
      priceChangePercentage24h: (json['price_change_percentage_24h'] as num?)?.toDouble() ?? 0.0,
      high24h: (json['high_24h'] as num?)?.toDouble() ?? 0.0,
      low24h: (json['low_24h'] as num?)?.toDouble() ?? 0.0,
      totalVolume: (json['total_volume'] as num?)?.toDouble() ?? 0.0,
      sparklineData: sparkline,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'name': name,
      'image': image,
      'current_price': currentPrice,
      'market_cap': marketCap,
      'market_cap_rank': marketCapRank,
      'price_change_24h': priceChange24h,
      'price_change_percentage_24h': priceChangePercentage24h,
      'high_24h': high24h,
      'low_24h': low24h,
      'total_volume': totalVolume,
    };
  }
}

class ForexPairModel extends ForexPair {
  const ForexPairModel({
    required super.baseCurrency,
    required super.quoteCurrency,
    required super.pair,
    required super.rate,
    required super.change24h,
    required super.lastUpdated,
  });

  factory ForexPairModel.fromJson(String pair, Map<String, dynamic> json) {
    return ForexPairModel(
      baseCurrency: pair.split('/')[0],
      quoteCurrency: pair.split('/')[1],
      pair: pair,
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      change24h: (json['change_24h'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: DateTime.now(),
    );
  }

  factory ForexPairModel.fromApiResponse(String baseCurrency, Map<String, dynamic> rates, String quote) {
    final rate = (rates[quote] as num?)?.toDouble() ?? 0.0;
    return ForexPairModel(
      baseCurrency: baseCurrency,
      quoteCurrency: quote,
      pair: '$baseCurrency/$quote',
      rate: rate,
      change24h: 0.0, // API doesn't always provide this
      lastUpdated: DateTime.now(),
    );
  }
}
