import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ayobami/data/datasources/remote/exchange_service.dart';
import 'package:ayobami/domain/entities/crypto_currency.dart';

class PortfolioPage extends StatefulWidget {
  final List<CryptoCurrency> marketPrices;
  
  const PortfolioPage({
    super.key,
    required this.marketPrices,
  });

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  List<PortfolioHolding> _holdings = [];
  bool _isLoading = true;
  String? _error;
  bool _isSyncing = false;
  double _totalValue = 0;
  double _totalProfit = 0;

  @override
  void initState() {
    super.initState();
    _loadPortfolio();
  }

  Future<void> _loadPortfolio() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load stored holdings
      final prefs = await SharedPreferences.getInstance();
      final holdingsJson = prefs.getStringList('portfolio_holdings') ?? [];
      
      final holdings = holdingsJson.map((json) {
        final parts = json.split('|');
        return PortfolioHolding(
          symbol: parts[0],
          amount: double.parse(parts[1]),
          avgBuyPrice: double.parse(parts[2]),
        );
      }).toList();

      // Calculate current values
      double totalValue = 0;
      double totalProfit = 0;
      
      for (final holding in holdings) {
        final price = widget.marketPrices.firstWhere(
          (p) => p.symbol.toLowerCase() == holding.symbol.toLowerCase(),
          orElse: () => widget.marketPrices.first,
        );
        final currentValue = holding.amount * price.currentPrice;
        final costBasis = holding.amount * holding.avgBuyPrice;
        
        totalValue += currentValue;
        totalProfit += currentValue - costBasis;
      }

      setState(() {
        _holdings = holdings;
        _totalValue = totalValue;
        _totalProfit = totalProfit;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _syncFromExchange() async {
    setState(() => _isSyncing = true);

    try {
      // Load exchange API keys
      final prefs = await SharedPreferences.getInstance();
      final binanceKey = prefs.getString('binance_api_key');
      final binanceSecret = prefs.getString('binance_api_secret');
      
      if (binanceKey == null || binanceSecret == null) {
        throw Exception('Exchange not configured. Go to Settings.');
      }

      // Note: In production, you would call the exchange API here
      // For now, show placeholder
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync feature - connect API keys to sync holdings'),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }

    setState(() => _isSyncing = false);
  }

  void _showAddHoldingDialog() {
    final symbolController = TextEditingController();
    final amountController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Holding'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: symbolController,
              decoration: const InputDecoration(
                labelText: 'Symbol (e.g., BTC)',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Avg. Buy Price',
                border: OutlineInputBorder(),
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Save holding
              Navigator.pop(context);
              _loadPortfolio();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            onPressed: _isSyncing ? null : _syncFromExchange,
            tooltip: 'Sync from exchange',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddHoldingDialog,
            tooltip: 'Add holding',
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary card
          _buildSummaryCard(),
          
          // Holdings list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _holdings.isEmpty
                    ? _buildEmptyState()
                    : _buildHoldingsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final profitPercent = _totalValue > 0 ? (_totalProfit / (_totalValue - _totalProfit) * 100) : 0;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo, Colors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Total Value',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${_totalValue.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_totalProfit >= 0 ? '+' : ''}\$${_totalProfit.toStringAsFixed(2)} (${profitPercent.toStringAsFixed(1)}%)',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No holdings yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Sync from exchange or add manually', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddHoldingDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Holding'),
          ),
        ],
      ),
    );
  }

  Widget _buildHoldingsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _holdings.length,
      itemBuilder: (context, index) {
        final holding = _holdings[index];
        final price = widget.marketPrices.firstWhere(
          (p) => p.symbol.toLowerCase() == holding.symbol.toLowerCase(),
          orElse: () => widget.marketPrices.first,
        );
        
        final currentValue = holding.amount * price.currentPrice;
        final costBasis = holding.amount * holding.avgBuyPrice;
        final profit = currentValue - costBasis;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(
              holding.symbol.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${holding.amount.toStringAsFixed(6)} @ \$${holding.avgBuyPrice.toStringAsFixed(2)}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${currentValue.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${profit >= 0 ? '+' : ''}\$${profit.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: profit >= 0 ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Portfolio holding model
class PortfolioHolding {
  final String symbol;
  final double amount;
  final double avgBuyPrice;

  PortfolioHolding({
    required this.symbol,
    required this.amount,
    required this.avgBuyPrice,
  });
}