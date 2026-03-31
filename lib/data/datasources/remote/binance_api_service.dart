import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// Binance API Integration
/// Supports: Market data, account info, placings orders
class BinanceApiService {
  final String apiKey;
  final String apiSecret;
  final bool isTestnet;
  
  static const String _baseUrl = 'https://api.binance.com';
  static const String _testnetUrl = 'https://testnet.binance.vision';
  
  BinanceApiService({
    required this.apiKey,
    required this.apiSecret,
    this.isTestnet = false,
  });
  
  String get _url => isTestnet ? _testnetUrl : _baseUrl;
  
  /// Get account balances
  Future<List<BinanceBalance>> getAccountBalances() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final query = 'timestamp=$timestamp';
    final signature = _generateSignature(query);
    
    final uri = Uri.parse('$_url/api/v3/account?$query&signature=$signature');
    final response = await http.get(
      uri,
      headers: {'X-MBX-APIKEY': apiKey},
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final balances = (data['balances'] as List)
          .where((b) => double.parse(b['free']) > 0 || double.parse(b['locked']) > 0)
          .map((b) => BinanceBalance(
            asset: b['asset'],
            free: double.parse(b['free']),
            locked: double.parse(b['locked']),
          ))
          .toList();
      return balances;
    }
    
    throw Exception('Failed to get account: ${response.body}');
  }
  
  /// Get current price for a symbol
  Future<double> getPrice(String symbol) async {
    final uri = Uri.parse('$_url/api/v3/ticker/price?symbol=$symbol');
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return double.parse(data['price']);
    }
    
    throw Exception('Failed to get price: ${response.body}');
  }
  
  /// Get 24h ticker stats
  Future<BinanceTicker> get24hTicker(String symbol) async {
    final uri = Uri.parse('$_url/api/v3/ticker/24hr?symbol=$symbol');
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return BinanceTicker(
        symbol: data['symbol'],
        lastPrice: double.parse(data['lastPrice']),
        priceChange: double.parse(data['priceChange']),
        priceChangePercent: double.parse(data['priceChangePercent']),
        highPrice: double.parse(data['highPrice']),
        lowPrice: double.parse(data['lowPrice']),
        volume: double.parse(data['volume']),
        quoteVolume: double.parse(data['quoteVolume']),
      );
    }
    
    throw Exception('Failed to get ticker: ${response.body}');
  }
  
  /// Get all tickers
  Future<List<BinanceTicker>> getAllTickers() async {
    final uri = Uri.parse('$_url/api/v3/ticker/24hr');
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .where((t) => t['quoteVolume'] > 1000000) // Filter low volume
          .map((t) => BinanceTicker(
            symbol: t['symbol'],
            lastPrice: double.parse(t['lastPrice']),
            priceChange: double.parse(t['priceChange']),
            priceChangePercent: double.parse(t['priceChangePercent']),
            highPrice: double.parse(t['highPrice']),
            lowPrice: double.parse(t['lowPrice']),
            volume: double.parse(t['volume']),
            quoteVolume: double.parse(t['quoteVolume']),
          ))
          .toList();
    }
    
    throw Exception('Failed to get tickers: ${response.body}');
  }
  
  /// Place market order
  Future<BinanceOrder> placeMarketOrder({
    required String symbol,
    required String side, // BUY or SELL
    required double quantity,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final query = 'symbol=$symbol&side=$side&type=MARKET&quantity=$quantity&timestamp=$timestamp';
    final signature = _generateSignature(query);
    
    final uri = Uri.parse('$_url/api/v3/order?$query&signature=$signature');
    final response = await http.post(
      uri,
      headers: {
        'X-MBX-APIKEY': apiKey,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return BinanceOrder(
        orderId: data['orderId'],
        symbol: data['symbol'],
        side: data['side'],
        type: data['type'],
        status: data['status'],
        price: double.parse(data['price'] ?? '0'),
        quantity: double.parse(data['origQty']),
        executedQty: double.parse(data['executedQty']),
      );
    }
    
    throw Exception('Order failed: ${response.body}');
  }
  
  /// Place limit order
  Future<BinanceOrder> placeLimitOrder({
    required String symbol,
    required String side,
    required double quantity,
    required double price,
    String timeInForce = 'GTC',
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final query = 'symbol=$symbol&side=$side&type=LIMIT&quantity=$quantity&price=$price&timeInForce=$timeInForce&timestamp=$timestamp';
    final signature = _generateSignature(query);
    
    final uri = Uri.parse('$_url/api/v3/order?$query&signature=$signature');
    final response = await http.post(
      uri,
      headers: {
        'X-MBX-APIKEY': apiKey,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return BinanceOrder(
        orderId: data['orderId'],
        symbol: data['symbol'],
        side: data['side'],
        type: data['type'],
        status: data['status'],
        price: double.parse(data['price']),
        quantity: double.parse(data['origQty']),
        executedQty: double.parse(data['executedQty']),
      );
    }
    
    throw Exception('Order failed: ${response.body}');
  }
  
  /// Cancel order
  Future<void> cancelOrder({
    required String symbol,
    required int orderId,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final query = 'symbol=$symbol&orderId=$orderId&timestamp=$timestamp';
    final signature = _generateSignature(query);
    
    final uri = Uri.parse('$_url/api/v3/order?$query&signature=$signature');
    final response = await http.delete(
      uri,
      headers: {'X-MBX-APIKEY': apiKey},
    );
    
    if (response.statusCode != 200) {
      throw Exception('Cancel failed: ${response.body}');
    }
  }
  
  /// Get open orders
  Future<List<BinanceOrder>> getOpenOrders() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final query = 'timestamp=$timestamp';
    final signature = _generateSignature(query);
    
    final uri = Uri.parse('$_url/api/v3/openOrders?$query&signature=$signature');
    final response = await http.get(
      uri,
      headers: {'X-MBX-APIKEY': apiKey},
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((o) => BinanceOrder(
        orderId: o['orderId'],
        symbol: o['symbol'],
        side: o['side'],
        type: o['type'],
        status: o['status'],
        price: double.parse(o['price']),
        quantity: double.parse(o['origQty']),
        executedQty: double.parse(o['executedQty']),
      )).toList();
    }
    
    throw Exception('Failed to get orders: ${response.body}');
  }
  
  /// Get exchange info (available trading pairs)
  Future<List<BinanceSymbol>> getExchangeInfo() async {
    final uri = Uri.parse('$_url/api/v3/exchangeInfo');
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final symbols = (data['symbols'] as List)
          .where((s) => s['status'] == 'TRADING')
          .map((s) => BinanceSymbol(
            symbol: s['symbol'],
            baseAsset: s['baseAsset'],
            quoteAsset: s['quoteAsset'],
            status: s['status'],
          ))
          .toList();
      return symbols;
    }
    
    throw Exception('Failed to get exchange info: ${response.body}');
  }
  
  /// Generate HMAC signature for API request
  String _generateSignature(String query) {
    final key = utf8.encode(apiSecret);
    final bytes = utf8.encode(query);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return digest.toString();
  }
}

/// Account balance
class BinanceBalance {
  final String asset;
  final double free;
  final double locked;
  
  BinanceBalance({
    required this.asset,
    required this.free,
    required this.locked,
  });
  
  double get total => free + locked;
}

/// 24h ticker
class BinanceTicker {
  final String symbol;
  final double lastPrice;
  final double priceChange;
  final double priceChangePercent;
  final double highPrice;
  final double lowPrice;
  final double volume;
  final double quoteVolume;
  
  BinanceTicker({
    required this.symbol,
    required this.lastPrice,
    required this.priceChange,
    required this.priceChangePercent,
    required this.highPrice,
    required this.lowPrice,
    required this.volume,
    required this.quoteVolume,
  });
}

/// Order
class BinanceOrder {
  final int orderId;
  final String symbol;
  final String side;
  final String type;
  final String status;
  final double price;
  final double quantity;
  final double executedQty;
  
  BinanceOrder({
    required this.orderId,
    required this.symbol,
    required this.side,
    required this.type,
    required this.status,
    required this.price,
    required this.quantity,
    required this.executedQty,
  });
  
  bool get isFilled => status == 'FILLED';
  bool get isPartiallyFilled => executedQty > 0 && executedQty < quantity;
}

/// Trading pair
class BinanceSymbol {
  final String symbol;
  final String baseAsset;
  final String quoteAsset;
  final String status;
  
  BinanceSymbol({
    required this.symbol,
    required this.baseAsset,
    required this.quoteAsset,
    required this.status,
  });
}