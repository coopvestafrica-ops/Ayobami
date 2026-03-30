import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ayobami/data/models/crypto_currency_model.dart';

/// Market API service for fetching crypto and forex data
class MarketApiService {
  static const String _coinGeckoBaseUrl = 'https://api.coingecko.com/api/v3';
  
  // Fetch top cryptocurrencies by market cap
  Future<List<CryptoCurrencyModel>> getTopCryptos({
    int limit = 20,
    String vsCurrency = 'usd',
  }) async {
    try {
      final url = Uri.parse(
        '$_coinGeckoBaseUrl/coins/markets'
        '?vs_currency=$vsCurrency'
        '&order=market_cap_desc'
        '&per_page=$limit'
        '&page=1'
        '&sparkline=false'
        '&price_change_percentage=24h',
      );
      
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CryptoCurrencyModel.fromJson(json)).toList();
      }
      
      throw Exception('Failed to fetch crypto markets: ${response.statusCode}');
    } catch (e) {
      throw Exception('Market API error: $e');
    }
  }
  
  // Fetch specific crypto by ID
  Future<CryptoCurrencyModel> getCryptoById(String id) async {
    try {
      final url = Uri.parse('$_coinGeckoBaseUrl/coins/$id');
      
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CryptoCurrencyModel.fromJson(data);
      }
      
      throw Exception('Failed to fetch crypto: ${response.statusCode}');
    } catch (e) {
      throw Exception('Market API error: $e');
    }
  }
  
  // Fetch crypto price with more details
  Future<Map<String, dynamic>> getCryptoPrice(String id) async {
    try {
      final url = Uri.parse(
        '$_coinGeckoBaseUrl/simple/price'
        '?ids=$id'
        '&vs_currencies=usd'
        '&include_24hr_change=true'
        '&include_market_cap=true',
      );
      
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      
      throw Exception('Failed to fetch price: ${response.statusCode}');
    } catch (e) {
      throw Exception('Market API error: $e');
    }
  }
  
  // Get global market data
  Future<Map<String, dynamic>> getGlobalData() async {
    try {
      final url = Uri.parse('$_coinGeckoBaseUrl/global');
      
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] as Map<String, dynamic>;
      }
      
      throw Exception('Failed to fetch global data: ${response.statusCode}');
    } catch (e) {
      throw Exception('Market API error: $e');
    }
  }
  
  // Search for cryptos
  Future<List<Map<String, dynamic>>> searchCrypto(String query) async {
    try {
      final url = Uri.parse('$_coinGeckoBaseUrl/search?query=$query');
      
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['coins'] ?? []);
      }
      
      throw Exception('Failed to search: ${response.statusCode}');
    } catch (e) {
      throw Exception('Market API error: $e');
    }
  }
}