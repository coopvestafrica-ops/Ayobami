import 'package:ayobami/data/datasources/remote/binance_api_service.dart';
import 'package:ayobami/data/datasources/remote/coinbase_api_service.dart';

/// Unified Exchange Service
/// Manages multiple exchange APIs for trading
class ExchangeService {
  BinanceApiService? _binance;
  CoinbaseApiService? _coinbase;
  ExchangeType _activeExchange = ExchangeType.binance;
  
  /// Initialize with Binance credentials
  Future<void> initBinance({
    required String apiKey,
    required String apiSecret,
    bool isTestnet = false,
  }) async {
    _binance = BinanceApiService(
      apiKey: apiKey,
      apiSecret: apiSecret,
      isTestnet: isTestnet,
    );
  }
  
  /// Initialize with Coinbase credentials
  Future<void> initCoinbase({
    required String apiKey,
    required String apiSecret,
    required String passphrase,
  }) async {
    _coinbase = CoinbaseApiService(
      apiKey: apiKey,
      apiSecret: apiSecret,
      passphrase: passphrase,
    );
  }
  
  /// Set active exchange
  void setActiveExchange(ExchangeType type) {
    _activeExchange = type;
  }
  
  /// Get available exchanges
  ExchangeType? get activeExchange => _activeExchange;
  
  /// Check if connected
  bool get isBinanceConnected => _binance != null;
  bool get isCoinbaseConnected => _coinbase != null;
  
  /// Get current exchange name
  String get exchangeName {
    switch (_activeExchange) {
      case ExchangeType.binance:
        return 'Binance';
      case ExchangeType.coinbase:
        return 'Coinbase';
    }
  }
  
  /// Get price from active exchange
  Future<double> getPrice(String symbol) async {
    // Convert to exchange format (e.g., BTC-USD -> BTCUSDT)
    final pair = _convertSymbol(symbol, toExchange: true);
    
    if (_binance != null && _activeExchange == ExchangeType.binance) {
      return await _binance!.getPrice(pair);
    } else if (_coinbase != null && _activeExchange == ExchangeType.coinbase) {
      return await _coinbase!.getSpotPrice(symbol.split('-')[0]);
    }
    
    throw Exception('Exchange not connected');
  }
  
  /// Get account balances
  Future<List<ExchangeBalance>> getBalances() async {
    if (_activeExchange == ExchangeType.binance && _binance != null) {
      final balances = await _binance!.getAccountBalances();
      return balances.map((b) => ExchangeBalance(
        asset: b.asset,
        free: b.free,
        locked: b.locked,
        total: b.total,
      )).toList();
    } else if (_activeExchange == ExchangeType.coinbase && _coinbase != null) {
      final accounts = await _coinbase!.getAccounts();
      return accounts.map((a) => ExchangeBalance(
        asset: a.currency,
        free: a.available,
        locked: a.balance - a.available,
        total: a.balance,
      )).toList();
    }
    
    throw Exception('Exchange not connected');
  }
  
  /// Place buy order
  Future<ExchangeOrder> placeBuyOrder({
    required String symbol,
    required double amount,
    required double price,
    OrderType orderType = OrderType.market,
    double? stopPrice,
    double? icebergQty,
  }) async {
    if (_activeExchange == ExchangeType.binance && _binance != null) {
      final pair = _convertSymbol(symbol, toExchange: true);
      
      BinanceOrder order;
      if (orderType == OrderType.limit) {
        order = await _binance!.placeLimitOrder(
          symbol: pair,
          side: 'BUY',
          quantity: amount,
          price: price,
        );
      } else if (orderType == OrderType.oco) {
        // Binance OCO (Stop-Loss Limit + Take-Profit Limit)
        // Simplified implementation: using stopPrice as trigger
        throw UnimplementedError('Binance OCO order implementation requires separate API call');
      } else {
        order = await _binance!.placeMarketOrder(
          symbol: pair,
          side: 'BUY',
          quantity: amount,
        );
      }

      return ExchangeOrder(
        id: order.orderId.toString(),
        symbol: order.symbol,
        side: 'buy',
        status: order.status,
        price: order.price,
        quantity: order.quantity,
        filled: order.executedQty,
      );
    } else if (_activeExchange == ExchangeType.coinbase && _coinbase != null) {
      // Coinbase Pro/Exchange Advanced Order Logic
      final order = await _coinbase!.placeBuyOrder(
        currency: symbol,
        amount: amount,
      );
      return ExchangeOrder(
        id: order.id,
        symbol: order.productId,
        side: 'buy',
        status: order.status,
        price: order.price,
        quantity: order.size,
        filled: order.funds,
      );
    }
    
    throw Exception('Exchange not connected');
  }
  
  /// Place sell order
  Future<ExchangeOrder> placeSellOrder({
    required String symbol,
    required double quantity,
    required double price,
    OrderType orderType = OrderType.market,
    double? stopPrice,
  }) async {
    if (_activeExchange == ExchangeType.binance && _binance != null) {
      final pair = _convertSymbol(symbol, toExchange: true);
      
      BinanceOrder order;
      if (orderType == OrderType.limit) {
        order = await _binance!.placeLimitOrder(
          symbol: pair,
          side: 'SELL',
          quantity: quantity,
          price: price,
        );
      } else {
        order = await _binance!.placeMarketOrder(
          symbol: pair,
          side: 'SELL',
          quantity: quantity,
        );
      }

      return ExchangeOrder(
        id: order.orderId.toString(),
        symbol: order.symbol,
        side: 'sell',
        status: order.status,
        price: order.price,
        quantity: order.quantity,
        filled: order.executedQty,
      );
    } else if (_activeExchange == ExchangeType.coinbase && _coinbase != null) {
      final order = await _coinbase!.placeSellOrder(
        currency: symbol,
        size: quantity,
      );
      return ExchangeOrder(
        id: order.id,
        symbol: order.productId,
        side: 'sell',
        status: order.status,
        price: order.price,
        quantity: order.size,
        filled: order.funds,
      );
    }
    
    throw Exception('Exchange not connected');
  }
  
  /// Convert symbol between formats
  String _convertSymbol(String symbol, {bool toExchange = false}) {
    if (toExchange) {
      return symbol.replaceAll('-', '').replaceAll('/', '');
    }
    return symbol.replaceAll('USDT', '-USD').replaceAll('/', '-');
  }
  
  /// Disconnect all exchanges
  Future<void> disconnect() async {
    _binance = null;
    _coinbase = null;
    _activeExchange = ExchangeType.binance;
  }
}

/// Exchange type enum
enum ExchangeType {
  binance,
  coinbase,
}

/// Order type enum
enum OrderType {
  market,
  limit,
  oco,
  iceberg,
}

/// Balance representation
class ExchangeBalance {
  final String asset;
  final double free;
  final double locked;
  final double total;
  
  ExchangeBalance({
    required this.asset,
    required this.free,
    required this.locked,
    required this.total,
  });
  
  bool get hasBalance => total > 0;
}

/// Order representation
class ExchangeOrder {
  final String id;
  final String symbol;
  final String side;
  final String status;
  final double price;
  final double quantity;
  final double filled;
  
  ExchangeOrder({
    required this.id,
    required this.symbol,
    required this.side,
    required this.status,
    required this.price,
    required this.quantity,
    required this.filled,
  });
  
  bool get isFilled => status == 'FILLED' || status == 'done';
  bool get isPending => status == 'NEW' || status == 'pending' || status == 'open';
  double get fillPercent => quantity > 0 ? (filled / quantity * 100) : 0;
}
