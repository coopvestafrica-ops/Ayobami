import 'package:ayobami/domain/entities/crypto_currency.dart';
import 'package:ayobami/domain/entities/user_memory.dart';

abstract class MarketRepository {
  Future<List<CryptoCurrency>> getMarketData({String vsCurrency = 'usd'});
  Future<List<ForexPair>> getForexRates({String baseCurrency = 'USD'});
  Future<CryptoCurrency?> getCryptoDetails(String coinId);
  List<CryptoCurrency> getCachedCryptoData();
  List<ForexPair> getCachedForexData();
}
