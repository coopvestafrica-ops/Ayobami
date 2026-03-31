import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// Coinbase API Integration
/// Supports: Trading, accounts, prices
class CoinbaseApiService {
  final String apiKey;
  final String apiSecret;
  final String passphrase;
  
  static const String _baseUrl = 'https://api.coinbase.com';
  
  CoinbaseApiService({
    required this.apiKey,
    required this.apiSecret,
    required this.passphrase,
  });
  
  /// Get account balances
  Future<List<CoinbaseAccount>> getAccounts() async {
    final timestamp = _getTimestamp();
    final method = 'GET';
    final path = '/v2/accounts';
    final message = '$timestamp$method$path';
    final signature = _generateSignature(message);
    
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http.get(
      uri,
      headers: {
        'CB-ACCESS-KEY': apiKey,
        'CB-ACCESS-SIGN': signature,
        'CB-ACCESS-TIMESTAMP': timestamp,
        'CB-ACCESS-PASSPHRASE': passphrase,
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final accounts = (data['data'] as List)
          .where((a) => double.parse(a['balance']['amount']) > 0)
          .map((a) => CoinbaseAccount(
            id: a['id'],
            name: a['name'],
            currency: a['balance']['currency'],
            balance: double.parse(a['balance']['amount']),
            available: double.parse(a['available']['amount']),
          ))
          .toList();
      return accounts;
    }
    
    throw Exception('Failed to get accounts: ${response.body}');
  }
  
  /// Get current price for a crypto
  Future<double> getSpotPrice(String currency) async {
    final path = '/v2/prices/$currency-USD/spot';
    final timestamp = _getTimestamp();
    final method = 'GET';
    final message = '$timestamp$method$path';
    final signature = _generateSignature(message);
    
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http.get(
      uri,
      headers: {
        'CB-ACCESS-KEY': apiKey,
        'CB-ACCESS-SIGN': signature,
        'CB-ACCESS-TIMESTAMP': timestamp,
        'CB-ACCESS-PASSPHRASE': passphrase,
      },
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return double.parse(data['data']['amount']);
    }
    
    throw Exception('Failed to get price: ${response.body}');
  }
  
  /// Get buy price (includes fees)
  Future<double> getBuyPrice(String currency) async {
    final path = '/v2/prices/$currency-USD/buy';
    final timestamp = _getTimestamp();
    final method = 'GET';
    final message = '$timestamp$method$path';
    final signature = _generateSignature(message);
    
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http.get(
      uri,
      headers: {
        'CB-ACCESS-KEY': apiKey,
        'CB-ACCESS-SIGN': signature,
        'CB-ACCESS-TIMESTAMP': timestamp,
        'CB-ACCESS-PASSPHRASE': passphrase,
      },
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return double.parse(data['data']['amount']);
    }
    
    throw Exception('Failed to get buy price: ${response.body}');
  }
  
  /// Get sell price (includes fees)
  Future<double> getSellPrice(String currency) async {
    final path = '/v2/prices/$currency-USD/sell';
    final timestamp = _getTimestamp();
    final method = 'GET';
    final message = '$timestamp$method$path';
    final signature = _generateSignature(message);
    
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http.get(
      uri,
      headers: {
        'CB-ACCESS-KEY': apiKey,
        'CB-ACCESS-SIGN': signature,
        'CB-ACCESS-TIMESTAMP': timestamp,
        'CB-ACCESS-PASSPHRASE': passphrase,
      },
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return double.parse(data['data']['amount']);
    }
    
    throw Exception('Failed to get sell price: ${response.body}');
  }
  
  /// Place buy order
  Future<CoinbaseOrder> placeBuyOrder({
    required String currency,
    required double amount,
  }) async {
    final timestamp = _getTimestamp();
    final method = 'POST';
    final path = '/v2/accounts/$currency/orders';
    final body = {
      'side': 'buy',
      'product_id': '$currency-USD',
      'funds': amount.toString(),
    };
    final message = '$timestamp$method$path${json.encode(body)}';
    final signature = _generateSignature(message);
    
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http.post(
      uri,
      headers: {
        'CB-ACCESS-KEY': apiKey,
        'CB-ACCESS-SIGN': signature,
        'CB-ACCESS-TIMESTAMP': timestamp,
        'CB-ACCESS-PASSPHRASE': passphrase,
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return CoinbaseOrder(
        id: data['data']['id'],
        side: data['data']['side'],
        productId: data['data']['product_id'],
        status: data['data']['status'],
        size: double.parse(data['data']['size'] ?? '0'),
        funds: double.parse(data['data']['funds'] ?? '0'),
        price: double.parse(data['data']['price'] ?? '0'),
      );
    }
    
    throw Exception('Order failed: ${response.body}');
  }
  
  /// Place sell order
  Future<CoinbaseOrder> placeSellOrder({
    required String currency,
    required double size,
  }) async {
    final timestamp = _getTimestamp();
    final method = 'POST';
    final path = '/v2/accounts/$currency/orders';
    final body = {
      'side': 'sell',
      'product_id': '$currency-USD',
      'size': size.toString(),
    };
    final message = '$timestamp$method$path${json.encode(body)}';
    final signature = _generateSignature(message);
    
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http.post(
      uri,
      headers: {
        'CB-ACCESS-KEY': apiKey,
        'CB-ACCESS-SIGN': signature,
        'CB-ACCESS-TIMESTAMP': timestamp,
        'CB-ACCESS-PASSPHRASE': passphrase,
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return CoinbaseOrder(
        id: data['data']['id'],
        side: data['data']['side'],
        productId: data['data']['product_id'],
        status: data['data']['status'],
        size: double.parse(data['data']['size'] ?? '0'),
        funds: double.parse(data['data']['funds'] ?? '0'),
        price: double.parse(data['data']['price'] ?? '0'),
      );
    }
    
    throw Exception('Order failed: ${response.body}');
  }
  
  /// Get list of available products (trading pairs)
  Future<List<CoinbaseProduct>> getProducts() async {
    final timestamp = _getTimestamp();
    final method = 'GET';
    final path = '/v2/products';
    final message = '$timestamp$method$path';
    final signature = _generateSignature(message);
    
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http.get(
      uri,
      headers: {
        'CB-ACCESS-KEY': apiKey,
        'CB-ACCESS-SIGN': signature,
        'CB-ACCESS-TIMESTAMP': timestamp,
        'CB-ACCESS-PASSPHRASE': passphrase,
      },
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['data'] as List)
          .where((p) => p['status'] == 'online')
          .map((p) => CoinbaseProduct(
            id: p['id'],
            baseCurrency: p['base_currency'],
            quoteCurrency: p['quote_currency'],
            status: p['status'],
          ))
          .toList();
    }
    
    throw Exception('Failed to get products: ${response.body}');
  }
  
  /// Get timestamp
  String _getTimestamp() => DateTime.now().millisecondsSinceEpoch.toString();
  
  /// Generate HMAC signature
  String _generateSignature(String message) {
    final key = utf8.encode(apiSecret);
    final bytes = utf8.encode(message);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return digest.toString();
  }
}

/// Account
class CoinbaseAccount {
  final String id;
  final String name;
  final String currency;
  final double balance;
  final double available;
  
  CoinbaseAccount({
    required this.id,
    required this.name,
    required this.currency,
    required this.balance,
    required this.available,
  });
}

/// Order
class CoinbaseOrder {
  final String id;
  final String side;
  final String productId;
  final String status;
  final double size;
  final double funds;
  final double price;
  
  CoinbaseOrder({
    required this.id,
    required this.side,
    required this.productId,
    required this.status,
    required this.size,
    required this.funds,
    required this.price,
  });
  
  bool get isDone => status == 'done';
  bool get isPending => status == 'pending';
}

/// Product
class CoinbaseProduct {
  final String id;
  final String baseCurrency;
  final String quoteCurrency;
  final String status;
  
  CoinbaseProduct({
    required this.id,
    required this.baseCurrency,
    required this.quoteCurrency,
    required this.status,
  });
}