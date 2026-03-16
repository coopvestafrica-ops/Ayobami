import 'package:ayobami/domain/entities/crypto_currency.dart';
import 'package:ayobami/domain/repositories/market_repository.dart';

class GetMarketData {
  final MarketRepository repository;

  GetMarketData(this.repository);

  Future<List<CryptoCurrency>> call({String vsCurrency = 'usd'}) async {
    return await repository.getMarketData(vsCurrency: vsCurrency);
  }
}

class GetForexRates {
  final MarketRepository repository;

  GetForexRates(this.repository);

  Future<List<ForexPair>> call({String baseCurrency = 'USD'}) async {
    return await repository.getForexRates(baseCurrency: baseCurrency);
  }
}
