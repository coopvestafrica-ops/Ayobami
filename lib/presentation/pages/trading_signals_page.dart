import 'package:flutter/material.dart';
import 'package:ayobami/core/ai/trading_signals.dart';
import 'package:ayobami/domain/entities/crypto_currency.dart';
import 'package:ayobami/data/datasources/remote/exchange_service.dart';
import 'package:ayobami/core/services/autonomous_trading_service.dart';
import 'package:ayobami/domain/repositories/settings_repository.dart';
import 'package:get_it/get_it.dart';

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
  final AITradingSignals _signals = GetIt.I<AITradingSignals>();
  List<TradingSignal> _signalsList = [];
  MarketSentiment _sentiment = MarketSentiment.neutral;
  bool _isAutoTradeEnabled = false;
  bool _isLoading = false;
  int _analyzedCount = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _generateSignals();
  }

  @override
  void didUpdateWidget(covariant TradingSignalsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If market data arrived after the page was first built (cryptos list
    // was empty on initial push), re-run the analyser.
    if (oldWidget.cryptos.length != widget.cryptos.length &&
        widget.cryptos.isNotEmpty) {
      _generateSignals();
    }
  }
  
  Future<void> _loadSettings() async {
    final settingsRepo = GetIt.I<SettingsRepository>();
    final settings = await settingsRepo.getSettings();
    setState(() {
      _isAutoTradeEnabled = settings.autoTradeEnabled;
    });
  }
  
  Future<void> _generateSignals() async {
    if (widget.cryptos.isEmpty) {
      // Market data not loaded yet - nothing to analyse.
      setState(() {
        _isLoading = false;
        _signalsList = [];
        _analyzedCount = 0;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final signals = await _signals.analyzeMarket(widget.cryptos);
      final sentiment = _signals.analyzeSentiment(widget.cryptos);
      if (!mounted) return;
      setState(() {
        _signalsList = signals;
        _sentiment = sentiment;
        _analyzedCount = widget.cryptos.length;
        _isLoading = false;
      });

      // If auto-trade is enabled, trigger the service for strong signals.
      if (_isAutoTradeEnabled) {
        await _triggerAutoTrade();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not fetch market data: $e';
      });
    }
  }

  Future<void> _triggerAutoTrade() async {
    final tradingService = GetIt.I<AutonomousTradingService>();
    final settingsRepo = GetIt.I<SettingsRepository>();
    final settings = await settingsRepo.getSettings();
    
    for (final signal in _signalsList) {
      if (signal.confidence >= 0.8) {
        await tradingService.executeSignal(signal, settings);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Trading Signals'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_isAutoTradeEnabled)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Chip(
                label: Text('AUTO', style: TextStyle(fontSize: 10, color: Colors.white)),
                backgroundColor: Colors.green,
                padding: EdgeInsets.zero,
              ),
            ),
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
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Fetching Binance klines & running technical analysis…'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: _generateSignals,
              ),
            ],
          ),
        ),
      );
    }

    if (widget.cryptos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Waiting for market data to load. Open the Market tab to trigger a refresh.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_signalsList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sentiment_neutral, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                'Analysed $_analyzedCount symbols — no actionable signals right now.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'Most tickers are sitting in the neutral RSI 35–65 range, '
                'or are not listed on Binance for klines. Pull to refresh to '
                're-analyse.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                onPressed: _generateSignals,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _generateSignals,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _signalsList.length,
        itemBuilder: (context, index) {
          final signal = _signalsList[index];
          return _SignalCard(signal: signal);
        },
      ),
    );
  }
}

class _SignalCard extends StatefulWidget {
  final TradingSignal signal;
  
  const _SignalCard({required this.signal});

  @override
  State<_SignalCard> createState() => _SignalCardState();
}

class _SignalCardState extends State<_SignalCard> {
  bool _isExecuting = false;

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
                        widget.signal.symbol,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${widget.signal.price.toStringAsFixed(2)}',
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
              widget.signal.reason,
              style: const TextStyle(fontSize: 14),
            ),
            
            const SizedBox(height: 16),
            
            // Targets
            Row(
              children: [
                Expanded(
                  child: _buildTargetChip(
                    'Target',
                    '\$${widget.signal.targetPrice.toStringAsFixed(2)}',
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTargetChip(
                    'Stop Loss',
                    '\$${widget.signal.stopLoss.toStringAsFixed(2)}',
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
                onPressed: _isExecuting ? null : () => _handleManualTrade(context),
                child: _isExecuting 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('${widget.signal.type.toUpperCase()} ${widget.signal.symbol}'),
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
    
    switch (widget.signal.type) {
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
    final percent = (widget.signal.confidence * 100).toInt();
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
    switch (widget.signal.type) {
      case 'buy':
        return Colors.green;
      case 'sell':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  Future<void> _handleManualTrade(BuildContext context) async {
    final exchangeService = GetIt.I<ExchangeService>();
    if (!exchangeService.isBinanceConnected && !exchangeService.isCoinbaseConnected) {
      _showErrorDialog(context, 'Exchange not connected. Please go to Settings to connect your exchange API.');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm ${widget.signal.type.toUpperCase()}'),
        content: Text('Do you want to execute a ${widget.signal.type} order for ${widget.signal.symbol} at \$${widget.signal.price.toStringAsFixed(2)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _getActionColor(), foregroundColor: Colors.white),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isExecuting = true);
      try {
        final tradingService = GetIt.I<AutonomousTradingService>();
        final settingsRepo = GetIt.I<SettingsRepository>();
        final settings = await settingsRepo.getSettings();
        
        // Temporarily enable auto-trade for this manual execution if it's disabled
        final effectiveSettings = settings.copyWith(autoTradeEnabled: true);
        await tradingService.executeSignal(widget.signal, effectiveSettings);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully executed ${widget.signal.type} order for ${widget.signal.symbol}')),
          );
        }
      } catch (e) {
        if (mounted) _showErrorDialog(context, 'Trade failed: $e');
      } finally {
        if (mounted) setState(() => _isExecuting = false);
      }
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }
}
