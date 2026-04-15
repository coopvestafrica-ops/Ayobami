import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ayobami/core/constants/app_constants.dart';
import 'package:ayobami/data/datasources/local/database_helper.dart';
import 'package:ayobami/data/models/chat_message_model.dart';
import 'package:ayobami/data/models/portfolio_item_model.dart';
import 'package:ayobami/domain/entities/app_settings.dart';
import 'package:ayobami/domain/entities/user_memory.dart';

abstract class LocalDataSource {
  // Chat
  Future<List<ChatMessageModel>> getChatHistory();
  Future<void> saveMessage(ChatMessageModel message);
  Future<void> clearChatHistory();
  
  // User Memory
  Future<List<UserMemory>> getUserMemory();
  Future<void> saveUserMemory(UserMemory memory);
  Future<void> deleteUserMemory(String id);
  
  // Portfolio
  Future<List<PortfolioItemModel>> getPortfolio();
  Future<void> addToPortfolio(PortfolioItemModel item);
  Future<void> removeFromPortfolio(String id);
  
  // Price Alerts
  Future<List<PriceAlertModel>> getPriceAlerts();
  Future<void> addPriceAlert(PriceAlertModel alert);
  Future<void> removePriceAlert(String id);
  
  // Reminders
  Future<List<ReminderModel>> getReminders();
  Future<void> addReminder(ReminderModel reminder);
  Future<void> removeReminder(String id);
  Future<void> updateReminder(ReminderModel reminder);
  
  // Settings
  Future<AppSettings> getSettings();
  Future<void> saveSettings(AppSettings settings);
  
    // Trading Positions
  Future<List<Map<String, dynamic>>> getActivePositions();
  Future<void> savePosition(Map<String, dynamic> position);
  Future<void> deletePosition(String symbol);

  // Cache
  Future<void> cacheCryptoData(String data);
  Future<String?> getCachedCryptoData();
  Future<void> cacheForexData(String data);
  Future<String?> getCachedForexData();
}

class LocalDataSourceImpl implements LocalDataSource {
  final SharedPreferences sharedPreferences;
  final DatabaseHelper databaseHelper;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  LocalDataSourceImpl({
    required this.sharedPreferences,
    required this.databaseHelper,
  });

  @override
  Future<List<ChatMessageModel>> getChatHistory() async {
    final db = await databaseHelper.database;
    final result = await db.query(
      AppConstants.chatTable,
      orderBy: 'timestamp ASC',
    );
    return result.map((json) => ChatMessageModel.fromJson(json)).toList();
  }

  @override
  Future<void> saveMessage(ChatMessageModel message) async {
    final db = await databaseHelper.database;
    await db.insert(
      AppConstants.chatTable,
      message.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> clearChatHistory() async {
    final db = await databaseHelper.database;
    await db.delete(AppConstants.chatTable);
  }

  @override
  Future<List<UserMemory>> getUserMemory() async {
    final db = await databaseHelper.database;
    final result = await db.query(AppConstants.userMemoryTable);
    return result.map((json) => UserMemory(
      id: json['id'] as String,
      key: json['key'] as String,
      value: json['value'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    )).toList();
  }

  @override
  Future<void> saveUserMemory(UserMemory memory) async {
    final db = await databaseHelper.database;
    await db.insert(
      AppConstants.userMemoryTable,
      {
        'id': memory.id,
        'key': memory.key,
        'value': memory.value,
        'created_at': memory.createdAt.toIso8601String(),
        'updated_at': memory.updatedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteUserMemory(String id) async {
    final db = await databaseHelper.database;
    await db.delete(
      AppConstants.userMemoryTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<PortfolioItemModel>> getPortfolio() async {
    final db = await databaseHelper.database;
    final result = await db.query(AppConstants.portfolioTable);
    return result.map((json) => PortfolioItemModel.fromJson(json)).toList();
  }

  @override
  Future<void> addToPortfolio(PortfolioItemModel item) async {
    final db = await databaseHelper.database;
    await db.insert(
      AppConstants.portfolioTable,
      item.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> removeFromPortfolio(String id) async {
    final db = await databaseHelper.database;
    await db.delete(
      AppConstants.portfolioTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<PriceAlertModel>> getPriceAlerts() async {
    final db = await databaseHelper.database;
    final result = await db.query(AppConstants.alertsTable);
    return result.map((json) => PriceAlertModel.fromJson(json)).toList();
  }

  @override
  Future<void> addPriceAlert(PriceAlertModel alert) async {
    final db = await databaseHelper.database;
    await db.insert(
      AppConstants.alertsTable,
      alert.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> removePriceAlert(String id) async {
    final db = await databaseHelper.database;
    await db.delete(
      AppConstants.alertsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<ReminderModel>> getReminders() async {
    final db = await databaseHelper.database;
    final result = await db.query(
      AppConstants.remindersTable,
      orderBy: 'date_time ASC',
    );
    return result.map((json) => ReminderModel.fromJson(json)).toList();
  }

  @override
  Future<void> addReminder(ReminderModel reminder) async {
    final db = await databaseHelper.database;
    await db.insert(
      AppConstants.remindersTable,
      reminder.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> removeReminder(String id) async {
    final db = await databaseHelper.database;
    await db.delete(
      AppConstants.remindersTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> updateReminder(ReminderModel reminder) async {
    final db = await databaseHelper.database;
    await db.update(
      AppConstants.remindersTable,
      reminder.toJson(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  @override
  Future<AppSettings> getSettings() async {
    final isDarkMode = sharedPreferences.getBool(AppConstants.themeKey) ?? false;
    final isVoiceEnabled = sharedPreferences.getBool(AppConstants.voiceEnabledKey) ?? true;
    final userName = sharedPreferences.getString(AppConstants.userNameKey) ?? '';
    final defaultCurrency = sharedPreferences.getString('default_currency') ?? 'USD';
    final notificationsEnabled = sharedPreferences.getBool('notifications_enabled') ?? true;
    final priceAlertsEnabled = sharedPreferences.getBool('price_alerts_enabled') ?? true;
    final language = sharedPreferences.getString('language') ?? 'en';
    final openaiApiKey = await secureStorage.read(key: 'openai_api_key') ?? '';
    
    // Auto-Trade Settings
    final autoTradeEnabled = sharedPreferences.getBool('auto_trade_enabled') ?? false;
    final maxPositionSize = sharedPreferences.getDouble('max_position_size') ?? 10.0;
    final stopLossPercent = sharedPreferences.getDouble('stop_loss_percent') ?? 5.0;
    final takeProfitPercent = sharedPreferences.getDouble('take_profit_percent') ?? 10.0;
    final executeStrongSignalsOnly = sharedPreferences.getBool('execute_strong_signals_only') ?? true;

    return AppSettings(
      isDarkMode: isDarkMode,
      isVoiceEnabled: isVoiceEnabled,
      userName: userName,
      defaultCurrency: defaultCurrency,
      notificationsEnabled: notificationsEnabled,
      priceAlertsEnabled: priceAlertsEnabled,
      language: language,
      openaiApiKey: openaiApiKey,
      autoTradeEnabled: autoTradeEnabled,
      maxPositionSize: maxPositionSize,
      stopLossPercent: stopLossPercent,
      takeProfitPercent: takeProfitPercent,
      executeStrongSignalsOnly: executeStrongSignalsOnly,
    );
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    await sharedPreferences.setBool(AppConstants.themeKey, settings.isDarkMode);
    await sharedPreferences.setBool(AppConstants.voiceEnabledKey, settings.isVoiceEnabled);
    await sharedPreferences.setString(AppConstants.userNameKey, settings.userName);
    await sharedPreferences.setString('default_currency', settings.defaultCurrency);
    await sharedPreferences.setBool('notifications_enabled', settings.notificationsEnabled);
    await sharedPreferences.setBool('price_alerts_enabled', settings.priceAlertsEnabled);
    await sharedPreferences.setString('language', settings.language);
    await secureStorage.write(key: 'openai_api_key', value: settings.openaiApiKey);
    
    // Auto-Trade Settings
    await sharedPreferences.setBool('auto_trade_enabled', settings.autoTradeEnabled);
    await sharedPreferences.setDouble('max_position_size', settings.maxPositionSize);
    await sharedPreferences.setDouble('stop_loss_percent', settings.stopLossPercent);
    await sharedPreferences.setDouble('take_profit_percent', settings.takeProfitPercent);
    await sharedPreferences.setBool('execute_strong_signals_only', settings.executeStrongSignalsOnly);
  }

  @override
  Future<void> cacheCryptoData(String data) async {
    await sharedPreferences.setString('cached_crypto_data', data);
    await sharedPreferences.setInt('crypto_cache_time', DateTime.now().millisecondsSinceEpoch);
  }

  @override
  Future<String?> getCachedCryptoData() async {
    final cacheTime = sharedPreferences.getInt('crypto_cache_time');
    if (cacheTime != null) {
      final cacheAge = DateTime.now().millisecondsSinceEpoch - cacheTime;
      if (cacheAge < 5 * 60 * 1000) {
        return sharedPreferences.getString('cached_crypto_data');
      }
    }
    return null;
  }

  @override
  Future<void> cacheForexData(String data) async {
    await sharedPreferences.setString('cached_forex_data', data);
    await sharedPreferences.setInt('forex_cache_time', DateTime.now().millisecondsSinceEpoch);
  }

  @override
  Future<String?> getCachedForexData() async {
    final cacheTime = sharedPreferences.getInt('forex_cache_time');
    if (cacheTime != null) {
      final cacheAge = DateTime.now().millisecondsSinceEpoch - cacheTime;
      if (cacheAge < 5 * 60 * 1000) {
        return sharedPreferences.getString('cached_forex_data');
      }
    }
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> getActivePositions() async {
    final db = await databaseHelper.database;
    return await db.query('trading_positions');
  }

  @override
  Future<void> savePosition(Map<String, dynamic> position) async {
    final db = await databaseHelper.database;
    await db.insert('trading_positions', position, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> deletePosition(String symbol) async {
    final db = await databaseHelper.database;
    await db.delete('trading_positions', where: 'symbol = ?', whereArgs: [symbol]);
  }

}