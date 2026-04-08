import 'dart:async';
import 'package:ayobami/core/ai/trading_signals.dart';
import 'package:ayobami/data/datasources/remote/exchange_service.dart';
import 'package:ayobami/domain/entities/app_settings.dart';
import 'package:ayobami/domain/repositories/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AutonomousTradingService {
  final ExchangeService exchangeService;
  final SettingsRepository settingsRepository;
  final AITradingSignals signalGenerator;
  
  bool _isRunning = false;
  Timer? _timer;
  
  // Track active positions for SL/TP management
  // In a real app, this should be persisted in a database
  final Map<String, ActivePosition> _activePositions = {};

  AutonomousTradingService({
    required this.exchangeService,
    required this.settingsRepository,
    required this.signalGenerator,
  });

  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;
    
    // Run every 1 minute for risk management
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      await _manageRisk();
    });
    
    print('AutonomousTradingService: Started');
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
    _activePositions[signal.symbol] = ActivePosition(
      symbol: signal.symbol,
      entryPrice: signal.price,
      quantity: quantity,
      stopLoss: stopLoss,
      takeProfit: takeProfit,
      timestamp: DateTime.now(),
    );
    
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
  }
}

class ActivePosition {
  final String symbol;
  final double entryPrice;
  final double quantity;
  final double stopLoss;
  final double takeProfit;
  final DateTime timestamp;

  ActivePosition({
    required this.symbol,
    required this.entryPrice,
    required this.quantity,
    required this.stopLoss,
    required this.takeProfit,
    required this.timestamp,
  });
}
