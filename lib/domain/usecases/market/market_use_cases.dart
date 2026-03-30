import 'package:ayobami/domain/entities/crypto_currency.dart';
import 'package:ayobami/domain/repositories/market_repository.dart';

class GetMarketData {
  final MarketRepository repository;

  GetMarketData(this.repository);

  Future<MarketData> call({int limit = 50, String? cryptoId}) async {
    final cryptos = await repository.getMarketData();
    
    // Filter by cryptoId if provided
    List<CryptoCurrency> filteredCryptos = cryptos;
    if (cryptoId != null) {
      filteredCryptos = cryptos.where((c) => c.id == cryptoId).toList();
    } else if (limit > 0 && limit < cryptos.length) {
      filteredCryptos = cryptos.take(limit).toList();
    }
    
    final forexPairs = await repository.getForexRates();
    
    return MarketData(
      cryptos: filteredCryptos,
      forexPairs: forexPairs,
      lastUpdated: DateTime.now(),
    );
  }
}

class GetForexRates {
  final MarketRepository repository;

  GetForexRates(this.repository);

  Future<List<ForexPair>> call({String baseCurrency = 'USD'}) async {
    return await repository.getForexRates(baseCurrency: baseCurrency);
  }
}
