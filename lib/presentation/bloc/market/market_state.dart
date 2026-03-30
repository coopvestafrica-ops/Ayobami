import 'package:equatable/equatable.dart';
import 'package:ayobami/domain/entities/crypto_currency.dart';

enum MarketStatus { initial, loading, success, error }

class MarketState extends Equatable {
  final MarketStatus status;
  final List<CryptoCurrency> cryptos;
  final List<CryptoCurrency> searchResults;
  final CryptoCurrency? selectedCrypto;
  final String? errorMessage;
  final String filter;
  final double? globalMarketCap;
  final double? global24hVolume;
  
  const MarketState({
    this.status = MarketStatus.initial,
    this.cryptos = const [],
    this.searchResults = const [],
    this.selectedCrypto,
    this.errorMessage,
    this.filter = 'all',
    this.globalMarketCap,
    this.global24hVolume,
  });
  
  MarketState copyWith({
    MarketStatus? status,
    List<CryptoCurrency>? cryptos,
    List<CryptoCurrency>? searchResults,
    CryptoCurrency? selectedCrypto,
    String? errorMessage,
    String? filter,
    double? globalMarketCap,
    double? global24hVolume,
  }) {
    return MarketState(
      status: status ?? this.status,
      cryptos: cryptos ?? this.cryptos,
      searchResults: searchResults ?? this.searchResults,
      selectedCrypto: selectedCrypto,
      errorMessage: errorMessage ?? this.errorMessage,
      filter: filter ?? this.filter,
      globalMarketCap: globalMarketCap ?? this.globalMarketCap,
      global24hVolume: global24hVolume ?? this.global24hVolume,
    );
  }
  
  List<CryptoCurrency> get filteredCryptos {
    switch (filter) {
      case 'gainers':
        return cryptos.where((c) => c.priceChangePercentage24h > 0).toList()
          ..sort((a, b) => b.priceChangePercentage24h.compareTo(a.priceChangePercentage24h));
      case 'losers':
        return cryptos.where((c) => c.priceChangePercentage24h < 0).toList()
          ..sort((a, b) => a.priceChangePercentage24h.compareTo(b.priceChangePercentage24h));
      default:
        return cryptos;
    }
  }
  
  @override
  List<Object?> get props => [
    status, cryptos, searchResults, selectedCrypto, 
    errorMessage, filter, globalMarketCap, global24hVolume
  ];
}