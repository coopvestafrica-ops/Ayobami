import 'package:flutter/material.dart';
import 'package:ayobami/core/ai/trading_signals.dart';
import 'package:ayobami/domain/entities/crypto_currency.dart';
import 'package:ayobami/data/datasources/remote/exchange_service.dart';

class TradingSignalsPage extends StatefulWidget {
  final List<CryptoCurrency> cryptos;
  
  const TradingSignalsPage({
    super.key,
    required this.cryptos,
  });

  @override
  State<TradingSignalsPage> createState() => _TradingSignalsPageState();
}

class _TradingSignalsPageState extends State<TradingSignalsPage> {
  final AITradingSignals _signals = AITradingSignals();
  List<TradingSignal> _signalsList = [];
  MarketSentiment _sentiment = MarketSentiment.neutral;
  
  @override
  void initState() {
    super.initState();
    _generateSignals();
  }
  
  void _generateSignals() {
    setState(() {
      _signalsList = _signals.analyzeMarket(widget.cryptos);
      _sentiment = _signals.analyzeSentiment(widget.cryptos);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Trading Signals'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _generateSignals,
          ),
        ],
      ),
      body: Column(
        children: [
          // Market sentiment card
          _buildSentimentCard(),
          
          // Signals list
          Expanded(
            child: _buildSignalsList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSentimentCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getSentimentColors(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _getSentimentColors().first.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _sentiment.emoji,
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 8),
          Text(
            _sentiment.displayName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _sentiment.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
  
  List<Color> _getSentimentColors() {
    switch (_sentiment) {
      case MarketSentiment.bullish:
        return [Colors.green, Colors.teal];
      case MarketSentiment.bearish:
        return [Colors.red, Colors.deepOrange];
      case MarketSentiment.neutral:
        return [Colors.blue, Colors.indigo];
      case MarketSentiment.fearful:
        return [Colors.grey, Colors.blueGrey];
      case MarketSentiment.greedy:
        return [Colors.orange, Colors.amber];
    }
  }
  
  Widget _buildSignalsList() {
    if (_signalsList.isEmpty) {
      return const Center(
        child: Text('No signals available'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _signalsList.length,
      itemBuilder: (context, index) {
        final signal = _signalsList[index];
        return _SignalCard(signal: signal);
      },
    );
  }
}

class _SignalCard extends StatelessWidget {
  final TradingSignal signal;
  
  const _SignalCard({required this.signal});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                _buildSignalBadge(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        signal.symbol,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${signal.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildConfidenceBadge(),
              ],
            ),
            
            const Divider(height: 24),
            
            // Reason
            Text(
              signal.reason,
              style: const TextStyle(fontSize: 14),
            ),
            
            const SizedBox(height: 16),
            
            // Targets
            Row(
              children: [
                Expanded(
                  child: _buildTargetChip(
                    'Target',
                    '\$${signal.targetPrice.toStringAsFixed(2)}',
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTargetChip(
                    'Stop Loss',
                    '\$${signal.stopLoss.toStringAsFixed(2)}',
                    Colors.red,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getActionColor(),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _showTradeDialog(context),
                child: Text('${signal.type.toUpperCase()} ${signal.symbol}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSignalBadge() {
    Color color;
    IconData icon;
    
    switch (signal.type) {
      case 'buy':
        color = Colors.green;
        icon = Icons.arrow_upward;
        break;
      case 'sell':
        color = Colors.red;
        icon = Icons.arrow_downward;
        break;
      default:
        color = Colors.grey;
        icon = Icons.pause;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
  
  Widget _buildConfidenceBadge() {
    final percent = (signal.confidence * 100).toInt();
    Color color;
    
    if (percent >= 75) {
      color = Colors.green;
    } else if (percent >= 50) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        '$percent% confidence',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
  
  Widget _buildTargetChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getActionColor() {
    switch (signal.type) {
      case 'buy':
        return Colors.green;
      case 'sell':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  void _showTradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Trade ${signal.symbol}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Signal: ${signal.type.toUpperCase()}'),
            Text('Entry: \$${signal.price.toStringAsFixed(2)}'),
            Text('Target: \$${signal.targetPrice.toStringAsFixed(2)}'),
            Text('Stop Loss: \$${signal.stopLoss.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            const Text(
              'To execute this trade, connect your exchange API in Settings.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}