import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Price alert model
class PriceAlert {
  final String id;
  final String cryptoId;
  final String symbol;
  final double targetPrice;
  final AlertCondition condition; // above, below
  final bool isEnabled;
  final DateTime createdAt;
  final bool triggered;

  PriceAlert({
    required this.id,
    required this.cryptoId,
    required this.symbol,
    required this.targetPrice,
    required this.condition,
    this.isEnabled = true,
    required this.createdAt,
    this.triggered = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'cryptoId': cryptoId,
    'symbol': symbol,
    'targetPrice': targetPrice,
    'condition': condition.name,
    'isEnabled': isEnabled,
    'createdAt': createdAt.toIso8601String(),
    'triggered': triggered,
  };

  factory PriceAlert.fromJson(Map<String, dynamic> json) => PriceAlert(
    id: json['id'],
    cryptoId: json['cryptoId'],
    symbol: json['symbol'],
    targetPrice: json['targetPrice'].toDouble(),
    condition: AlertCondition.values.firstWhere(
      (e) => e.name == json['condition'],
      orElse: () => AlertCondition.above,
    ),
    isEnabled: json['isEnabled'] ?? true,
    createdAt: DateTime.parse(json['createdAt']),
    triggered: json['triggered'] ?? false,
  );

  PriceAlert copyWith({
    String? id,
    String? cryptoId,
    String? symbol,
    double? targetPrice,
    AlertCondition? condition,
    bool? isEnabled,
    DateTime? createdAt,
    bool? triggered,
  }) => PriceAlert(
    id: id ?? this.id,
    cryptoId: cryptoId ?? this.cryptoId,
    symbol: symbol ?? this.symbol,
    targetPrice: targetPrice ?? this.targetPrice,
    condition: condition ?? this.condition,
    isEnabled: isEnabled ?? this.isEnabled,
    createdAt: createdAt ?? this.createdAt,
    triggered: triggered ?? this.triggered,
  );
}

enum AlertCondition { above, below }

/// Service to manage price alerts
class PriceAlertsService {
  static const String _alertsKey = 'price_alerts';
  
  Future<List<PriceAlert>> getAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final alertsJson = prefs.getStringList(_alertsKey) ?? [];
    return alertsJson.map((json) => PriceAlert.fromJson(jsonDecode(json))).toList();
  }
  
  Future<void> addAlert(PriceAlert alert) async {
    final prefs = await SharedPreferences.getInstance();
    final alerts = await getAlerts();
    alerts.add(alert);
    await _saveAlerts(prefs, alerts);
  }
  
  Future<void> removeAlert(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final alerts = await getAlerts();
    alerts.removeWhere((a) => a.id == id);
    await _saveAlerts(prefs, alerts);
  }
  
  Future<void> updateAlert(PriceAlert alert) async {
    final prefs = await SharedPreferences.getInstance();
    final alerts = await getAlerts();
    final index = alerts.indexWhere((a) => a.id == alert.id);
    if (index != -1) {
      alerts[index] = alert;
      await _saveAlerts(prefs, alerts);
    }
  }
  
  Future<void> toggleAlert(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final alerts = await getAlerts();
    final index = alerts.indexWhere((a) => a.id == id);
    if (index != -1) {
      alerts[index] = alerts[index].copyWith(isEnabled: !alerts[index].isEnabled);
      await _saveAlerts(prefs, alerts);
    }
  }
  
  Future<void> _saveAlerts(SharedPreferences prefs, List<PriceAlert> alerts) async {
    await prefs.setStringList(
      _alertsKey,
      alerts.map((a) => jsonEncode(a.toJson())).toList(),
    );
  }
  
  /// Check if any alerts should trigger
  Future<List<PriceAlert>> checkAlerts(List<Map<String, dynamic>> prices) async {
    final alerts = await getAlerts();
    final triggered = <PriceAlert>[];
    
    for (final alert in alerts) {
      if (!alert.isEnabled || alert.triggered) continue;
      
      final priceData = prices.firstWhere(
        (p) => p['id'] == alert.cryptoId,
        orElse: () => null,
      );
      
      if (priceData == null) continue;
      
      final currentPrice = (priceData['currentPrice'] as num).toDouble();
      bool shouldTrigger = false;
      
      if (alert.condition == AlertCondition.above && currentPrice >= alert.targetPrice) {
        shouldTrigger = true;
      } else if (alert.condition == AlertCondition.below && currentPrice <= alert.targetPrice) {
        shouldTrigger = true;
      }
      
      if (shouldTrigger) {
        triggered.add(alert.copyWith(triggered: true));
        await updateAlert(alert.copyWith(triggered: true));
      }
    }
    
    return triggered;
  }
}