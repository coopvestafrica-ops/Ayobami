class AppConstants {
  // API Endpoints
  static const String coinGeckoBaseUrl = 'https://api.coingecko.com/api/v3';
  static const String exchangeRateApiUrl = 'https://api.exchangerate-api.com/v4/latest';
  
  // App Info
  static const String appName = 'Ayobami';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Your Personal AI Assistant';
  
  // AI Responses
  static const String aiGreeting = 'Hello! I am Ayobami, your AI assistant. How can I help you today?';
  static const String aiTradingDisclaimer = 'Note: I can provide market information and analysis, but always do your own research before making investment decisions. Trading involves risk.';
  
  // Database
  static const String databaseName = 'ayobami.db';
  static const int databaseVersion = 1;
  
  // Tables
  static const String chatTable = 'chat_messages';
  static const String userMemoryTable = 'user_memory';
  static const String portfolioTable = 'portfolio';
  static const String alertsTable = 'price_alerts';
  static const String remindersTable = 'reminders';
  
  // Shared Preferences Keys
  static const String themeKey = 'theme_mode';
  static const String userNameKey = 'user_name';
  static const String userPreferencesKey = 'user_preferences';
  static const String firstLaunchKey = 'first_launch';
  static const String voiceEnabledKey = 'voice_enabled';
  
  // Trading Pairs
  static const List<String> cryptoList = [
    'bitcoin',
    'ethereum',
    'binancecoin',
    'solana',
    'cardano',
    'ripple',
    'polkadot',
    'dogecoin',
    'avalanche-2',
    'chainlink',
  ];
  
  static const List<String> forexPairs = [
    'EUR/USD',
    'GBP/USD',
    'USD/JPY',
    'USD/CHF',
    'AUD/USD',
    'USD/CAD',
    'NZD/USD',
    'EUR/GBP',
  ];
  
  // Default Currency
  static const String defaultCurrency = 'USD';
}
