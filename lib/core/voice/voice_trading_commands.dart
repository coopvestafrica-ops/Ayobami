import 'package:ayobami/domain/entities/crypto_currency.dart';
import 'package:ayobami/core/ai/trading_signals.dart';

/// Voice trading command parser
/// Converts spoken commands into actionable trading operations
class VoiceTradingCommands {
  /// Parse voice input and return command
  VoiceCommand? parseCommand(String text) {
    final lowerText = text.toLowerCase();
    
    // Buy commands
    if (_containsAny(lowerText, ['buy', 'purchase', 'get', 'invest'])) {
      return _parseBuyCommand(text);
    }
    
    // Sell commands
    if (_containsAny(lowerText, ['sell', 'sell', 'liquidate', 'dump'])) {
      return _parseSellCommand(text);
    }
    
    // Price check commands
    if (_containsAny(lowerText, ['price', 'worth', 'value', 'cost'])) {
      return _parsePriceCommand(text);
    }
    
    // Signal commands
    if (_containsAny(lowerText, ['signal', 'recommend', 'should', 'opinion'])) {
      return _parseSignalCommand(text);
    }
    
    // Alert commands
    if (_containsAny(lowerText, ['alert', 'notify', 'warn', 'remind'])) {
      return _parseAlertCommand(text);
    }
    
    // Portfolio commands
    if (_containsAny(lowerText, ['portfolio', 'holdings', 'balance', 'account'])) {
      return VoiceCommand(
        type: CommandType.portfolio,
        rawText: text,
      );
    }
    
    // Market commands
    if (_containsAny(lowerText, ['market', 'market', 'trending', 'top'])) {
      return VoiceCommand(
        type: CommandType.market,
        rawText: text,
      );
    }
    
    return null;
  }
  
  VoiceCommand? _parseBuyCommand(String text) {
    final lowerText = text.toLowerCase();
    final crypto = _extractCrypto(lowerText);
    final amount = _extractAmount(lowerText);
    
    return VoiceCommand(
      type: CommandType.buy,
      cryptoSymbol: crypto,
      amount: amount,
      rawText: text,
    );
  }
  
  VoiceCommand? _parseSellCommand(String text) {
    final lowerText = text.toLowerCase();
    final crypto = _extractCrypto(lowerText);
    final amount = _extractAmount(lowerText);
    
    return VoiceCommand(
      type: CommandType.sell,
      cryptoSymbol: crypto,
      amount: amount,
      rawText: text,
    );
  }
  
  VoiceCommand? _parsePriceCommand(String text) {
    final lowerText = text.toLowerCase();
    final crypto = _extractCrypto(lowerText);
    
    return VoiceCommand(
      type: CommandType.price,
      cryptoSymbol: crypto,
      rawText: text,
    );
  }
  
  VoiceCommand? _parseSignalCommand(String text) {
    final lowerText = text.toLowerCase();
    final crypto = _extractCrypto(lowerText);
    
    return VoiceCommand(
      type: CommandType.signal,
      cryptoSymbol: crypto,
      rawText: text,
    );
  }
  
  VoiceCommand? _parseAlertCommand(String text) {
    final lowerText = text.toLowerCase();
    final crypto = _extractCrypto(lowerText);
    final price = _extractPrice(lowerText);
    final isAbove = lowerText.contains('above') || lowerText.contains('higher');
    
    return VoiceCommand(
      type: CommandType.alert,
      cryptoSymbol: crypto,
      targetPrice: price,
      alertAbove: isAbove,
      rawText: text,
    );
  }
  
  String? _extractCrypto(String text) {
    final cryptos = ['bitcoin', 'btc', 'ethereum', 'eth', 'solana', 'sol', 
                     'cardano', 'ada', 'polkadot', 'dot', 'ripple', 'xrp',
                     'dogecoin', 'doge', 'avalanche', 'avax', 'polygon', 'matic'];
    
    for (final crypto in cryptos) {
      if (text.contains(crypto)) {
        return crypto;
      }
    }
    return null;
  }
  
  double? _extractAmount(String text) {
    // Look for numbers with optional currency
    final regex = RegExp(r'(\d+(?:\.\d+)?)\s*(?:dollars|usd|\$|coins?|tokens?)?');
    final match = regex.firstMatch(text);
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }
    return null;
  }
  
  double? _extractPrice(String text) {
    final regex = RegExp(r'(?:at|when|above|below)\s*\$?(\d+(?:\.\d+)?)');
    final match = regex.firstMatch(text);
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }
    return null;
  }
  
  bool _containsAny(String text, List<String> words) {
    return words.any((word) => text.contains(word));
  }
  
  /// Generate response text for a command
  String generateResponse(VoiceCommand command, CryptoCurrency? crypto) {
    switch (command.type) {
      case CommandType.buy:
        if (command.cryptoSymbol != null && command.amount != null) {
          return 'I can help you buy ${command.amount} ${command.cryptoSymbol}. '
                 'Please confirm in the app to execute this trade.';
        }
        return 'I need more details. Please specify which crypto and how much you want to buy.';
      
      case CommandType.sell:
        if (command.cryptoSymbol != null && command.amount != null) {
          return 'I can help you sell ${command.amount} ${command.cryptoSymbol}. '
                 'Please confirm in the app to execute this trade.';
        }
        return 'I need more details. Please specify which crypto and how much you want to sell.';
      
      case CommandType.price:
        if (crypto != null) {
          return '${crypto.name} is currently at \$${crypto.currentPrice.toStringAsFixed(2)}. '
                 'It\'s ${crypto.priceChangePercentage24h >= 0 ? 'up' : 'down'} '
                 '${crypto.priceChangePercentage24h.abs().toStringAsFixed(2)}% today.';
        }
        return 'I couldn\'t find that cryptocurrency. Would you like me to show the market prices?';
      
      case CommandType.signal:
        // Use AI signals logic
        if (crypto != null) {
          final signals = AITradingSignals();
          final signal = signals.getSignalFor(crypto);
          if (signal != null) {
            return 'For ${crypto.name}, my analysis shows a ${signal.type.toUpperCase()} signal '
                   'with ${(signal.confidence * 100).toInt()}% confidence. '
                   '${signal.reason}';
          }
        }
        return 'I don\'t have a clear signal for that crypto right now.';
      
      case CommandType.alert:
        return 'I\'ll set a price alert for ${command.cryptoSymbol} '
               '${command.alertAbove ? 'above' : 'below'} \$${command.targetPrice?.toStringAsFixed(2)}.';
      
      case CommandType.portfolio:
        return 'Checking your portfolio... You can view your holdings in the Portfolio tab.';
      
      case CommandType.market:
        return 'Let me show you the current market data.';
      
      case CommandType.help:
        return 'I can help you with: checking prices, buying, selling, '
               'setting alerts, viewing signals, and checking your portfolio.';
    }
  }
}

/// Voice command model
class VoiceCommand {
  final CommandType type;
  final String? cryptoSymbol;
  final double? amount;
  final double? targetPrice;
  final bool alertAbove;
  final String rawText;
  
  VoiceCommand({
    required this.type,
    this.cryptoSymbol,
    this.amount,
    this.targetPrice,
    this.alertAbove = true,
    required this.rawText,
  });
  
  String get description {
    switch (type) {
      case CommandType.buy:
        return 'Buy $amount $cryptoSymbol';
      case CommandType.sell:
        return 'Sell $amount $cryptoSymbol';
      case CommandType.price:
        return 'Check $cryptoSymbol price';
      case CommandType.signal:
        return 'Get signal for $cryptoSymbol';
      case CommandType.alert:
        return 'Alert $cryptoSymbol ${alertAbove ? "above" : "below"} $targetPrice';
      case CommandType.portfolio:
        return 'Check portfolio';
      case CommandType.market:
        return 'Show market';
      case CommandType.help:
        return 'Show help';
    }
  }
}

/// Command type enum
enum CommandType {
  buy,
  sell,
  price,
  signal,
  alert,
  portfolio,
  market,
  help,
}