import 'package:ayobami/domain/entities/chat_message.dart';

class AIResponseGenerator {
  
  static Future<AIResponse> generateResponse(String userMessage) async {
    final message = userMessage.toLowerCase().trim();
    
    // Greetings
    if (_isGreeting(message)) {
      return AIResponse(
        content: _getGreetingResponse(),
        type: MessageType.text,
      );
    }
    
    // Help requests
    if (message.contains('help') || message.contains('what can you do')) {
      return AIResponse(
        content: _getHelpResponse(),
        type: MessageType.text,
      );
    }
    
    // Crypto prices
    if (_isCryptoQuery(message)) {
      return _generateCryptoResponse(message);
    }
    
    // Forex rates
    if (_isForexQuery(message)) {
      return _generateForexResponse(message);
    }
    
    // Trading signals
    if (_isTradingSignalRequest(message)) {
      return _generateTradingSignalResponse(message);
    }
    
    // Calculator
    if (_isCalculation(message)) {
      return _generateCalculationResponse(message);
    }
    
    // Reminders
    if (_isReminderRequest(message)) {
      return _generateReminderResponse(message);
    }
    
    // App actions
    if (_isAppAction(message)) {
      return _generateAppActionResponse(message);
    }
    
    // Market analysis
    if (_isMarketAnalysis(message)) {
      return _generateMarketAnalysisResponse(message);
    }
    
    // Default AI response
    return AIResponse(
      content: _generateDefaultResponse(message),
      type: MessageType.text,
    );
  }
  
  // Helper methods
  static bool _isGreeting(String message) {
    final greetings = ['hello', 'hi', 'hey', 'good morning', 'good afternoon', 'good evening', 'what\'s up', 'howdy'];
    return greetings.any((g) => message.startsWith(g));
  }
  
  static String _getGreetingResponse() {
    return '''Hello! I'm Ayobami, your AI assistant. 👋

I can help you with:
📊 Crypto prices & market data
💱 Forex exchange rates
📈 Trading signals & analysis
🔢 Calculator & conversions
⏰ Reminders & scheduling
🌐 Web searches

Just ask me anything!''';
  }
  
  static String _getHelpResponse() {
    return '''Here's what I can help you with:

**📊 Market Data**
- "What's the price of Bitcoin?"
- "Show me crypto prices"
- "EUR/USD rate"

**📈 Trading**
- "Give me trading signals for Bitcoin"
- "Should I buy Ethereum?"
- "Market analysis"

**🔧 Utilities**
- "Calculate 100 * 5.5%"
- "Convert 1 BTC to USD"
- "Remind me to call mom at 5pm"

**🌐 Information**
- "Search for [topic]"
- "What is blockchain?"

**⚙️ Settings**
- "Toggle dark mode"
- "Change currency to EUR"

Just type naturally and I'll help!''';
  }
  
  static bool _isCryptoQuery(String message) {
    final cryptoKeywords = ['price', 'bitcoin', 'ethereum', 'btc', 'eth', 'crypto', 'coin', 'trading', 'market cap', 'volume'];
    return cryptoKeywords.any((k) => message.contains(k));
  }
  
  static bool _isForexQuery(String message) {
    final forexKeywords = ['forex', 'exchange rate', 'eur/usd', 'gbp/usd', 'usd/jpy', 'currency', 'dollar', 'euro', 'pound', 'yen'];
    return forexKeywords.any((k) => message.contains(k));
  }
  
  static bool _isTradingSignalRequest(String message) {
    final signalKeywords = ['signal', 'buy', 'sell', 'should i', 'trade', 'entry', 'exit', 'target', 'stop loss'];
    return signalKeywords.any((k) => message.contains(k));
  }
  
  static bool _isCalculation(String message) {
    final calcKeywords = ['calculate', 'what is', 'how much is', '+', '-', '*', '/', '×', '÷', '%'];
    return calcKeywords.any((k) => message.contains(k)) && 
           RegExp(r'\d').hasMatch(message);
  }
  
  static bool _isReminderRequest(String message) {
    final reminderKeywords = ['remind', 'reminder', 'alert', 'notify', 'remember to'];
    return reminderKeywords.any((k) => message.contains(k));
  }
  
  static bool _isAppAction(String message) {
    final actionKeywords = ['open', 'launch', 'call', 'message', 'email', 'search'];
    return actionKeywords.any((k) => message.contains(k));
  }
  
  static bool _isMarketAnalysis(String message) {
    final analysisKeywords = ['analysis', 'trend', 'bullish', 'bearish', 'outlook', 'forecast', 'predict'];
    return analysisKeywords.any((k) => message.contains(k));
  }
  
  static AIResponse _generateCryptoResponse(String message) {
    String response = '';
    
    if (message.contains('bitcoin') || message.contains('btc')) {
      response += '₿ **Bitcoin (BTC)**: I\'ll show you the current market data. Use the Markets tab for live prices!\n\n';
    }
    if (message.contains('ethereum') || message.contains('eth')) {
      return AIResponse(
        content: '**Ethereum (ETH)**\n\nI can show you ETH prices in the Markets section. Would you like me to:\n- Show current price?\n- Set a price alert?\n- Get trading signals?\n\nJust say "show ETH price" or navigate to Markets!',
        type: MessageType.marketData,
      );
    }
    
    response += '''To get detailed crypto prices and market data:

1. Go to the **Markets** tab
2. You'll see live prices for top cryptocurrencies
3. Tap any coin for detailed charts and info

Would you like me to set a price alert for a specific coin?''';
    
    return AIResponse(
      content: response,
      type: MessageType.marketData,
    );
  }
  
  static AIResponse _generateForexResponse(String message) {
    return AIResponse(
      content: '''💱 **Forex Rates**

You can find live forex exchange rates in the Markets section. 

**Popular pairs available:**
- EUR/USD (Euro/Dollar)
- GBP/USD (British Pound/Dollar)
- USD/JPY (Dollar/Yen)
- USD/CHF (Dollar/Swiss Franc)

Navigate to Markets → Forex for live rates!

Would you like me to set an alert for a specific currency pair?''',
      type: MessageType.marketData,
    );
  }
  
  static AIResponse _generateTradingSignalResponse(String message) {
    final symbol = _extractSymbol(message);
    
    return AIResponse(
      content: '''📈 **Trading Signal for ${symbol.toUpperCase()}**

**Current Analysis:**
- Trend: Consolidating
- Recommendation: Wait for clear entry

**Suggested Strategy:**
1. Wait for price to break key resistance
2. Entry: Wait for confirmation
3. Stop Loss: 2-3% below entry
4. Take Profit: 5-10% above entry

⚠️ **Disclaimer:** This is for educational purposes only. Always do your own research before trading. Past performance doesn't guarantee future results.

Would you like me to add this to your portfolio tracker?''',
      type: MessageType.tradingSignal,
    );
  }
  
  static String _extractSymbol(String message) {
    final symbols = ['btc', 'eth', 'eur/usd', 'gbp/usd', 'bitcoin', 'ethereum'];
    for (final s in symbols) {
      if (message.contains(s)) return s.toUpperCase();
    }
    return 'BTC/ETH';
  }
  
  static AIResponse _generateCalculationResponse(String message) {
    try {
      // Extract and evaluate simple math
      String expression = message
          .replaceAll('what is', '')
          .replaceAll('calculate', '')
          .replaceAll('=', '')
          .replaceAll(' ', '')
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('%', '/100');
      
      // Handle percentage calculations
      if (expression.contains('%')) {
        final parts = expression.split('%');
        if (parts.length == 2) {
          final number = double.tryParse(parts[0]) ?? 0;
          final result = number / 100;
          return AIResponse(
            content: '📱 **Calculation Result**\n\n$number% = **$result**',
            type: MessageType.calculator,
          );
        }
      }
      
      // Handle basic operations
      final result = _evaluateExpression(expression);
      
      return AIResponse(
        content: '📱 **Calculation Result**\n\n$expression = **$result**',
        type: MessageType.calculator,
      );
    } catch (e) {
      return AIResponse(
        content: 'I couldn\'t parse that calculation. Try saying:\n- "What is 100 + 50?"\n- "Calculate 25 * 4"\n- "What is 20% of 200?"',
        type: MessageType.error,
      );
    }
  }
  
  static double _evaluateExpression(String expr) {
    // Simple expression evaluator
    expr = expr.replaceAll(' ', '');
    
    // Handle addition and subtraction
    final addSubRegex = RegExp(r'^(-?\d+\.?\d*)([\+\-])(.+)$');
    var match = addSubRegex.firstMatch(expr);
    
    if (match != null) {
      final a = double.parse(match.group(1)!);
      final op = match.group(2)!;
      final b = double.parse(match.group(3)!);
      
      if (op == '+') return a + b;
      if (op == '-') return a - b;
    }
    
    // Handle multiplication and division
    final mulDivRegex = RegExp(r'^(-?\d+\.?\d*)([\*/])(.+)$');
    match = mulDivRegex.firstMatch(expr);
    
    if (match != null) {
      final a = double.parse(match.group(1)!);
      final op = match.group(2)!;
      final b = double.parse(match.group(3)!);
      
      if (op == '*') return a * b;
      if (op == '/') return b != 0 ? a / b : 0;
    }
    
    return double.tryParse(expr) ?? 0;
  }
  
  static AIResponse _generateReminderResponse(String message) {
    return AIResponse(
      content: '''⏰ **Reminder Created**

I'd be happy to set a reminder for you! 

To create a reminder:
1. Go to the **Portfolio** tab
2. Tap on **Reminders**
3. Add your reminder with date and time

**Quick tip:** You can also set price alerts for your favorite cryptocurrencies!

Would you like help with anything else?''',
      type: MessageType.reminder,
    );
  }
  
  static AIResponse _generateAppActionResponse(String message) {
    if (message.contains('open') || message.contains('launch')) {
      return AIResponse(
        content: '''I can help you open other apps! 

However, I work within the Ayobami app. You can:
- Use the **Markets** tab for crypto/forex
- Use the **Portfolio** tab for tracking
- Use the **Settings** tab for customization

For external apps, use your device's voice assistant (Siri/Google Assistant).

Is there something specific you'd like me to help with?''',
        type: MessageType.text,
      );
    }
    
    return AIResponse(
      content: 'I can help you with various tasks within Ayobami. What would you like to do?',
      type: MessageType.text,
    );
  }
  
  static AIResponse _generateMarketAnalysisResponse(String message) {
    final symbol = _extractSymbol(message);
    
    return AIResponse(
      content: '''📊 **Market Analysis for ${symbol.toUpperCase()}**

**Current Market Overview:**
- Market sentiment: Mixed
- Volatility: Moderate

**Key Observations:**
1. Price is consolidating near key levels
2. Trading volume is average
3. No major news catalysts currently

**Outlook:**
- Short-term: Sideways to slightly bullish
- Medium-term: Depends on market sentiment

📈 For live charts and detailed analysis, visit the Markets tab!

⚠️ Remember: This is not financial advice. Always research before investing.''',
      type: MessageType.marketData,
    );
  }
  
  static String _generateDefaultResponse(String message) {
    final responses = [
      '''I'm not sure I understood that. Let me help you with:

• **Crypto prices** - "What's Bitcoin worth?"
• **Forex rates** - "EUR/USD rate please"
• **Trading** - "Give me a trading signal"
• **Calculator** - "Calculate 100 * 5"
• **Reminders** - "Remind me to..."

Or try the quick action buttons below!''',
      
      '''I'd be happy to help! Here are some things I can do:

📊 Show crypto & forex prices
📈 Provide trading signals  
🔢 Perform calculations
⏰ Set reminders & alerts

What would you like to explore?''',
      
      '''I'm here to assist! Try asking me:

• "What's the price of Bitcoin?"
• "Show me Ethereum prices"
• "Calculate 10 + 5"
• "EUR to USD rate"
• "Trading signal for BTC"

Or navigate using the tabs below!''',
    ];
    
    return responses[DateTime.now().millisecond % responses.length];
  }
}

class AIResponse {
  final String content;
  final MessageType type;
  
  AIResponse({required this.content, required this.type});
}
