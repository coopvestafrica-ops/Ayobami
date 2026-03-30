import 'package:ayobami/data/datasources/local/local_data_source.dart';
import 'package:ayobami/data/datasources/remote/market_api_service.dart';
import 'package:ayobami/data/models/crypto_currency_model.dart';
import 'package:ayobami/domain/entities/crypto_currency.dart';
import 'package:ayobami/domain/repositories/market_repository.dart';

class MarketRepositoryImpl implements MarketRepository {
  final MarketApiService marketApiService;
  final LocalDataSource localDataSource;
  
  List<CryptoCurrency> _cachedCryptos = [];
  List<ForexPair> _cachedForex = [];
  DateTime? _lastFetch;

  MarketRepositoryImpl({
    required this.marketApiService,
    required this.localDataSource,
  });

  @override
  Future<List<CryptoCurrency>> getMarketData({String vsCurrency = 'usd'}) async {
    try {
      final cryptos = await marketApiService.getTopCryptos(
        limit: 50,
        vsCurrency: vsCurrency,
      );
      _cachedCryptos = cryptos;
      _lastFetch = DateTime.now();
      return cryptos;
    } catch (e) {
      // Return cached data if available
      if (_cachedCryptos.isNotEmpty) {
        return _cachedCryptos;
      }
      rethrow;
    }
  }

  @override
  Future<List<ForexPair>> getForexRates({String baseCurrency = 'USD'}) async {
    // Common forex pairs
    final pairs = ['EUR', 'GBP', 'JPY', 'CAD', 'AUD'];
    final List<ForexPair> forexPairs = [];
    
    for (final quote in pairs) {
      try {
        // Simulated forex rates (in production, use a real forex API)
        // For now, return mock data
        forexPairs.add(ForexPairModel(
          baseCurrency: baseCurrency,
          quoteCurrency: quote,
          pair: '$baseCurrency/$quote',
          rate: _getMockForexRate(baseCurrency, quote),
          change24h: (DateTime.now().millisecond % 100) / 100 - 0.5,
          lastUpdated: DateTime.now(),
        ));
      } catch (e) {
        continue;
      }
    }
    
    _cachedForex = forexPairs;
    return forexPairs;
  }

  @override
  Future<CryptoCurrency?> getCryptoDetails(String coinId) async {
    try {
      return await marketApiService.getCryptoById(coinId);
    } catch (e) {
      return null;
    }
  }

  @override
  List<CryptoCurrency> getCachedCryptoData() => _cachedCryptos;

  @override
  List<ForexPair> getCachedForexData() => _cachedForex;

  double _getMockForexRate(String base, String quote) {
    // Simulated rates - replace with real API in production
    final rates = {
      'EUR': 0.92,
      'GBP': 0.79,
      'JPY': 149.50,
      'CAD': 1.36,
      'AUD': 1.53,
    };
    return rates[quote] ?? 1.0;
  }
}