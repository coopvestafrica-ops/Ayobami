import 'package:http/http.dart' as http;
import 'dart:convert';

/// Track whale wallets and copy their trades using Alchemy API
class WhaleTransactionTracker {
  static const String alchemyBaseUrl = 'https://eth-mainnet.g.alchemy.com/v2';
  final String alchemyKey;
  
  // Known major exchange wallets and whale addresses
  static const List<String> whaleAddresses = [
    '0x28C6c06290CC32205154560013d06173b00c96dE', // Binance Wallet
    '0x71660c4f941C50c53FE1E7aC71adD7062775a405', // Whale Wallet
    '0xAb5801a7D1267500016520F329029177505e0732', // Vitalik Buterin
  ];
  
  WhaleTransactionTracker({required this.alchemyKey});
  
  /// Get major transactions from known whale wallets
  Future<List<WhaleTransaction>> getWhaleTransactions({
    String? asset,
    double minAmount = 100000.0, // Only track $100k+ movements
  }) async {
    final List<WhaleTransaction> whaleTransactions = [];
    
    for (final address in whaleAddresses) {
      try {
        final response = await http.post(
          Uri.parse('$alchemyBaseUrl/$alchemyKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'jsonrpc': '2.0',
            'method': 'alchemy_getAssetTransfers',
            'params': [
              {
                'fromAddress': address,
                'category': ['external', 'internal', 'erc20'],
                'withMetadata': true,
                'maxCount': '0x10', // Get last 16 transactions
              }
            ],
            'id': 1,
          }),
        ).timeout(const Duration(seconds: 10));
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final transfers = data['result']['transfers'] as List;
          
          for (final transfer in transfers) {
            final value = (transfer['value'] as num?)?.toDouble() ?? 0.0;
            final symbol = transfer['asset'] as String? ?? 'ETH';
            
            if (value >= minAmount && (asset == null || symbol == asset)) {
              whaleTransactions.add(WhaleTransaction(
                walletAddress: address,
                asset: symbol,
                amount: value,
                transactionType: 'transfer',
                timestamp: DateTime.parse(transfer['metadata']['blockTimestamp']),
                hash: transfer['hash'],
              ));
            }
          }
        }
      } catch (e) {
        print('Whale Tracker Error for $address: $e');
      }
    }
    
    // Sort by most recent
    whaleTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return whaleTransactions;
  }
  
  /// Auto-execute same trade as whale (copy trading logic)
  Future<bool> copyWhaleTransaction({
    required WhaleTransaction transaction,
    required double myAmount,
  }) async {
    // This would call ExchangeService to execute the trade
    print('Copying whale trade: ${transaction.amount} ${transaction.asset} at ${transaction.timestamp}');
    return true;
  }
}

class WhaleTransaction {
  final String walletAddress;
  final String asset;
  final double amount;
  final String transactionType; 
  final DateTime timestamp;
  final String hash;
  
  WhaleTransaction({
    required this.walletAddress,
    required this.asset,
    required this.amount,
    required this.transactionType,
    required this.timestamp,
    required this.hash,
  });
}
