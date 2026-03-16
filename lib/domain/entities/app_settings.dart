import 'package:equatable/equatable.dart';

class AppSettings extends Equatable {
  final bool isDarkMode;
  final bool isVoiceEnabled;
  final String defaultCurrency;
  final String userName;
  final bool notificationsEnabled;
  final bool priceAlertsEnabled;
  final String language;
  
  const AppSettings({
    this.isDarkMode = false,
    this.isVoiceEnabled = true,
    this.defaultCurrency = 'USD',
    this.userName = '',
    this.notificationsEnabled = true,
    this.priceAlertsEnabled = true,
    this.language = 'en',
  });
  
  AppSettings copyWith({
    bool? isDarkMode,
    bool? isVoiceEnabled,
    String? defaultCurrency,
    String? userName,
    bool? notificationsEnabled,
    bool? priceAlertsEnabled,
    String? language,
  }) {
    return AppSettings(
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
