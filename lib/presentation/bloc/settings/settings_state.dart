import 'package:equatable/equatable.dart';
import 'package:ayobami/domain/entities/app_settings.dart';

class SettingsState extends Equatable {
  final bool isDarkMode;
  final bool isVoiceEnabled;
  final String defaultCurrency;
  final String userName;
  final bool notificationsEnabled;
  final bool priceAlertsEnabled;
  final String language;

  const SettingsState({
    this.isDarkMode = false,
    this.isVoiceEnabled = true,
    this.defaultCurrency = 'USD',
    this.userName = '',
    this.notificationsEnabled = true,
    this.priceAlertsEnabled = true,
    this.language = 'en',
  });

  factory SettingsState.fromSettings(AppSettings settings) {
    return SettingsState(
      isDarkMode: settings.isDarkMode,
      isVoiceEnabled: settings.isVoiceEnabled,
      defaultCurrency: settings.defaultCurrency,
      userName: settings.userName,
      notificationsEnabled: settings.notificationsEnabled,
      priceAlertsEnabled: settings.priceAlertsEnabled,
      language: settings.language,
    );
  }

  AppSettings toSettings() {
    return AppSettings(
      isDarkMode: isDarkMode,
      isVoiceEnabled: isVoiceEnabled,
      defaultCurrency: defaultCurrency,
      userName: userName,
      notificationsEnabled: notificationsEnabled,
      priceAlertsEnabled: priceAlertsEnabled,
      language: language,
    );
  }

  SettingsState copyWith({
    bool? isDarkMode,
    bool? isVoiceEnabled,
    String? defaultCurrency,
    String? userName,
    bool? notificationsEnabled,
    bool? priceAlertsEnabled,
    String? language,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isVoiceEnabled: isVoiceEnabled ?? this.isVoiceEnabled,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      userName: userName ?? this.userName,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      priceAlertsEnabled: priceAlertsEnabled ?? this.priceAlertsEnabled,
      language: language ?? this.language,
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
  ];
}
