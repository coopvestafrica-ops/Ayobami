import 'package:equatable/equatable.dart';

class AppSettings extends Equatable {
  final bool isDarkMode;
  final bool isVoiceEnabled;
  final String defaultCurrency;
  final String userName;
  final bool notificationsEnabled;
  final bool priceAlertsEnabled;
  final String language;
  final String openaiApiKey;
  
  // Auto-Trade Settings
  final bool autoTradeEnabled;
  final double maxPositionSize; // Max % of balance per trade
  final double stopLossPercent;
  final double takeProfitPercent;
  final bool executeStrongSignalsOnly;
  
  // Onboarding
  final bool hasCompletedOnboarding;

  const AppSettings({
    this.isDarkMode = false,
    this.isVoiceEnabled = true,
    this.defaultCurrency = 'USD',
    this.userName = '',
    this.notificationsEnabled = true,
    this.priceAlertsEnabled = true,
    this.language = 'en',
    this.openaiApiKey = '',
    this.autoTradeEnabled = false,
    this.maxPositionSize = 10.0,
    this.stopLossPercent = 5.0,
    this.takeProfitPercent = 10.0,
    this.executeStrongSignalsOnly = true,
    this.hasCompletedOnboarding = false,
  });
  
  AppSettings copyWith({
    bool? isDarkMode,
    bool? isVoiceEnabled,
    String? defaultCurrency,
    String? userName,
    bool? notificationsEnabled,
    bool? priceAlertsEnabled,
    String? language,
    String? openaiApiKey,
    bool? autoTradeEnabled,
    double? maxPositionSize,
    double? stopLossPercent,
    double? takeProfitPercent,
    bool? executeStrongSignalsOnly,
    bool? hasCompletedOnboarding,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isVoiceEnabled: isVoiceEnabled ?? this.isVoiceEnabled,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      userName: userName ?? this.userName,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      priceAlertsEnabled: priceAlertsEnabled ?? this.priceAlertsEnabled,
      language: language ?? this.language,
      openaiApiKey: openaiApiKey ?? this.openaiApiKey,
      autoTradeEnabled: autoTradeEnabled ?? this.autoTradeEnabled,
      maxPositionSize: maxPositionSize ?? this.maxPositionSize,
      stopLossPercent: stopLossPercent ?? this.stopLossPercent,
      takeProfitPercent: takeProfitPercent ?? this.takeProfitPercent,
      executeStrongSignalsOnly: executeStrongSignalsOnly ?? this.executeStrongSignalsOnly,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }
  
  @override
  List<Object?> get props => [
    isDarkMode,
    isVoiceEnabled,
    defaultCurrency,
    userName,
    notificationsEnabled,
    priceAlertsEnabled,
    language,
    openaiApiKey,
    autoTradeEnabled,
    maxPositionSize,
    stopLossPercent,
    takeProfitPercent,
    executeStrongSignalsOnly,
    hasCompletedOnboarding,
  ];
}
