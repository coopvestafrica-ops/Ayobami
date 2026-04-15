import 'dart:async';
import 'package:ayobami/core/ai/trading_signals.dart';
import 'package:ayobami/data/datasources/local/local_data_source.dart';
import 'package:ayobami/data/datasources/remote/exchange_service.dart';
import 'package:ayobami/domain/entities/app_settings.dart';
import 'package:ayobami/domain/entities/crypto_currency.dart';
import 'package:ayobami/domain/repositories/settings_repository.dart';

class AutonomousTradingService {
  final ExchangeService exchangeService;
  final SettingsRepository settingsRepository;
  final AITradingSignals signalGenerator;
  final LocalDataSource localDataSource;
  
  bool _isRunning = false;
  Timer? _timer;
  
  // Track active positions for SL/TP management
  // Persisted in database via localDataSource
  final Map<String, ActivePosition> _activePositions = {};

  AutonomousTradingService({
    required this.exchangeService,
    required this.settingsRepository,
    required this.signalGenerator,
    required this.localDataSource,
  });

  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;
    
    // Restore active positions from persistent storage
    await _restorePositions();
    
    // Run every 1 minute for risk management
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      await _manageRisk();
    });
    
    print('AutonomousTradingService: Started with ${_activePositions.length} restored positions');
  }
  
  /// Restore active positions from local storage on startup
  Future<void> _restorePositions() async {
    try {
      final positions = await localDataSource.getActivePositions();
      for (final posData in positions) {
        final position = ActivePosition(
          symbol: posData['symbol'] as String,
          entryPrice: (posData['entry_price'] as num).toDouble(),
          quantity: (posData['quantity'] as num).toDouble(),
          stopLoss: (posData['stop_loss'] as num).toDouble(),
          takeProfit: (posData['take_profit'] as num).toDouble(),
          highestPrice: (posData['highest_price'] as num).toDouble(),
          timestamp: DateTime.parse(posData['timestamp'] as String),
        );
        _activePositions[position.symbol] = position;
      }
      print('AutonomousTradingService: Restored ${positions.length} positions from storage');
    } catch (e) {
      print('AutonomousTradingService: Error restoring positions: $e');
    }
  }

  
  /// Portfolio rebalancing (ensure assets stay within target ratios)
  Future<void> rebalance(Map<String, double> targetRatios) async {
    print('AutonomousTradingService: Starting rebalancing...');
    try {
      final balances = await exchangeService.getBalances();
      final settings = await settingsRepository.getSettings();
      
      // Calculate total portfolio value
      double totalValue = 0;
      final assetValues = <String, double>{};
      
      for (final balance in balances) {
        if (balance.total > 0) {
          final price = await exchangeService.getPrice('${balance.asset}USDT');
          final value = balance.total * price;
          assetValues[balance.asset] = value;
          totalValue += value;
        }
      }
      
      // Rebalance to target ratios
      for (final entry in targetRatios.entries) {
        final asset = entry.key;
        final targetRatio = entry.value;
        final targetValue = totalValue * targetRatio;
        final currentValue = assetValues[asset] ?? 0;
        
        if ((currentValue - targetValue).abs() > 100) {
          // Rebalance needed
          if (currentValue < targetValue) {
            // Buy
            final amountToSpend = targetValue - currentValue;
            final quantity = amountToSpend / (await exchangeService.getPrice('${asset}USDT'));
            await exchangeService.placeBuyOrder(
              symbol: '${asset}USDT',
              amount: quantity,
            );
            print('AutonomousTradingService: Rebalanced - Bought $quantity of $asset');
          } else {
            // Sell
            final quantity = (currentValue - targetValue) / (await exchangeService.getPrice('${asset}USDT'));
            await exchangeService.placeSellOrder(
              symbol: '${asset}USDT',
              quantity: quantity,
            );
            print('AutonomousTradingService: Rebalanced - Sold $quantity of $asset');
          }
        }
      }
      print('AutonomousTradingService: Rebalancing completed');
    } catch (e) {
      print('AutonomousTradingService: Rebalancing error: $e');
    }
  }

  void stop() {
    _timer?.cancel();
    _isRunning = false;
    print('AutonomousTradingService: Stopped');
  }

  Future<void> _manageRisk() async {
    if (_activePositions.isEmpty) return;

    try {
      final settings = await settingsRepository.getSettings();
      if (!settings.autoTradeEnabled) return;

      final symbols = _activePositions.keys.toList();
      for (final symbol in symbols) {
        final position = _activePositions[symbol]!;
        final currentPrice = await exchangeService.getPrice(symbol);
        
        
        // Update highest price for trailing stop
        if (currentPrice > position.highestPrice) {
          position.highestPrice = currentPrice;
          // Dynamically adjust Stop Loss (Trailing at 5% below peak)
          position.stopLoss = position.highestPrice * 0.95;
          // Persist the updated position
          await _persistPosition(position);
        }

        // Check Stop Loss
        if (currentPrice <= position.stopLoss) {
          print('AutonomousTradingService: STOP LOSS triggered for $symbol at $currentPrice');
          await _executeExit(symbol, currentPrice, 'Stop Loss');
        } 
        // Check Take Profit
        else if (currentPrice >= position.takeProfit) {
          print('AutonomousTradingService: TAKE PROFIT triggered for $symbol at $currentPrice');
          await _executeExit(symbol, currentPrice, 'Take Profit');
        }
      }
    } catch (e) {
      print('AutonomousTradingService Risk Management Error: $e');
    }
  }

  Future<void> _executeExit(String symbol, double price, String reason) async {
    try {
      final position = _activePositions[symbol]!;
      await exchangeService.placeSellOrder(
        symbol: symbol,
        quantity: position.quantity,
      );
      _activePositions.remove(symbol);
      
      // Remove from persistent storage
      await localDataSource.deletePosition(symbol);
      
      print('AutonomousTradingService: Exited $symbol due to $reason at $price');
    } catch (e) {
      print('AutonomousTradingService Exit Error for $symbol: $e');
    }
  }

  Future<void> executeSignal(TradingSignal signal, AppSettings settings) async {
    if (!settings.autoTradeEnabled) return;
    
    // Filter by confidence if required
    if (settings.executeStrongSignalsOnly && signal.confidence < 0.8) {
      print('AutonomousTradingService: Skipping signal due to low confidence (${signal.confidence})');
      return;
    }

    try {
      if (signal.type == 'buy') {
        // Don't buy if we already have a position
        if (_activePositions.containsKey(signal.symbol)) {
          print('AutonomousTradingService: Already have a position in ${signal.symbol}');
          return;
        }
        await _handleBuySignal(signal, settings);
      } else if (signal.type == 'sell') {
        // Only sell if we have an active position
        if (_activePositions.containsKey(signal.symbol)) {
          await _handleSellSignal(signal, settings);
        }
      }
    } catch (e) {
      print('AutonomousTradingService Execution Error: $e');
    }
  }

  Future<void> _handleBuySignal(TradingSignal signal, AppSettings settings) async {
    final balances = await exchangeService.getBalances();
    final usdtBalance = balances.firstWhere(
      (b) => b.asset == 'USDT' || b.asset == 'USD',
      orElse: () => ExchangeBalance(asset: 'USDT', free: 0, locked: 0, total: 0),
    ).free;

    // Calculate amount based on max position size setting
    final amountToSpend = usdtBalance * (settings.maxPositionSize / 100);
    if (amountToSpend < 10) {
      print('AutonomousTradingService: Amount to spend too low ($amountToSpend)');
      return;
    }

    final quantity = amountToSpend / signal.price;

    print('AutonomousTradingService: Executing AUTO-BUY for ${signal.symbol} at ${signal.price}');
    
    final order = await exchangeService.placeBuyOrder(
      symbol: signal.symbol,
      amount: quantity,
      price: signal.price,
    );
    
    // Calculate SL/TP based on settings
    final stopLoss = signal.price * (1 - (settings.stopLossPercent / 100));
    final takeProfit = signal.price * (1 + (settings.takeProfitPercent / 100));

    // Track the position
    final position = ActivePosition(
      symbol: signal.symbol,
      entryPrice: signal.price,
      quantity: quantity,
      stopLoss: stopLoss,
      takeProfit: takeProfit,
      highestPrice: signal.price,
      timestamp: DateTime.now(),
    );
    _activePositions[signal.symbol] = position;
    
    // Persist the position
    await _persistPosition(position);
    
    print('AutonomousTradingService: Position tracked. SL: $stopLoss, TP: $takeProfit');
  }

  Future<void> _handleSellSignal(TradingSignal signal, AppSettings settings) async {
    final position = _activePositions[signal.symbol];
    if (position == null) return;

    print('AutonomousTradingService: Executing AUTO-SELL for ${signal.symbol} at ${signal.price} (Signal)');
    
    await exchangeService.placeSellOrder(
      symbol: signal.symbol,
      quantity: position.quantity,
    );
    
    _activePositions.remove(signal.symbol);
    
    // Remove from persistent storage
    await localDataSource.deletePosition(signal.symbol);
  }
  
  /// Persist a position to local storage
  Future<void> _persistPosition(ActivePosition position) async {
    try {
      await localDataSource.savePosition({
        'symbol': position.symbol,
        'entry_price': position.entryPrice,
        'quantity': position.quantity,
        'stop_loss': position.stopLoss,
        'take_profit': position.takeProfit,
        'highest_price': position.highestPrice,
        'timestamp': position.timestamp.toIso8601String(),
      });
    } catch (e) {
      print('AutonomousTradingService: Error persisting position: $e');
    }
  }
}

class ActivePosition {
  final String symbol;
  final double entryPrice;
  final double quantity;
  final double stopLoss;
  final double takeProfit;
  double highestPrice;
  final DateTime timestamp;

  ActivePosition({
    required this.symbol,
    required this.entryPrice,
    required this.quantity,
    required this.stopLoss,
    required this.takeProfit,
    required this.highestPrice,
    required this.timestamp,
  });
}
