import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ayobami/core/di/injection_container.dart' as di;
import 'package:ayobami/core/theme/app_theme.dart';
import 'package:ayobami/core/voice/voice_controller.dart';
import 'package:ayobami/presentation/bloc/chat/chat_bloc.dart';
import 'package:ayobami/presentation/bloc/chat/chat_event.dart';
import 'package:ayobami/presentation/bloc/chat/chat_state.dart';
import 'package:ayobami/presentation/bloc/market/market_bloc.dart';
import 'package:ayobami/presentation/bloc/market/market_state.dart';
import 'package:ayobami/presentation/widgets/chat_bubble.dart';
import 'package:ayobami/presentation/widgets/voice_button.dart';
import 'package:ayobami/presentation/pages/exchange_settings_page.dart';
import 'dart:math' as math;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final VoiceController _voiceController;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  
  // Simulated portfolio data
  double _portfolioValue = 125450.67;
  double _portfolioChange = 12.5;
  bool _showCommandCenter = true;

  @override
  void initState() {
    super.initState();
    _voiceController = di.sl<VoiceController>();
    _initializeVoice();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  Future<void> _initializeVoice() async {
    await _voiceController.initialize();
  }

  void _sendMessage(ChatBloc chatBloc) {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      chatBloc.add(SendMessageEvent(text));
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startListening(ChatBloc chatBloc) {
    chatBloc.add(const StartVoiceListeningEvent());
  }

  void _stopListening(ChatBloc chatBloc) {
    chatBloc.add(const StopVoiceListeningEvent());
  }

  void _speakResponse(ChatBloc chatBloc, String text) {
    chatBloc.add(SpeakResponseEvent(text));
  }

  void _stopSpeaking(ChatBloc chatBloc) {
    chatBloc.add(const StopSpeakingEvent());
  }

  void _navigateToSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ExchangeSettingsPage(),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _voiceController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        final chatBloc = context.read<ChatBloc>();
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: _buildEnterpriseAppBar(),
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.darkBackgroundGradient,
            ),
            child: Stack(
              children: [
                // Animated background particles
                _buildAnimatedBackground(),
                // Main content
                SafeArea(
                  child: _showCommandCenter 
                      ? _buildCommandCenter(chatBloc, state)
                      : _buildChatInterface(chatBloc, state),
                ),
              ],
            ),
          ),
          floatingActionButton: _buildSmartFAB(chatBloc, state),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  PreferredSizeWidget _buildEnterpriseAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white),
        ),
      ),
      title: ShaderMask(
        shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
        child: const Text(
          'AYOBAMI',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 3,
          ),
        ),
      ),
      actions: [
        // AI Status Indicator
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.successColor.withOpacity(0.5 + (_pulseController.value * 0.3)),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.successColor,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.successColor.withOpacity(_pulseController.value),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'AI ACTIVE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.successColor,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: _navigateToSettings,
        ),
      ],
    );
  }

  Widget _buildAnimatedBackground() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _GridPainter(),
      ),
    );
  }

  Widget _buildCommandCenter(ChatBloc chatBloc, ChatState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Market Ticker
          _buildMarketTicker(),
          const SizedBox(height: 16),
          
          // Portfolio Overview Card
          _buildPortfolioCard(),
          const SizedBox(height: 16),
          
          // AI Insights Panel
          _buildAIInsightsPanel(),
          const SizedBox(height: 16),
          
          // Active Positions
          _buildActivePositionsCard(),
          const SizedBox(height: 16),
          
          // Quick Actions
          _buildQuickActionsCard(),
          const SizedBox(height: 16),
          
          // Whale Tracker
          _buildWhaleTrackerCard(),
          const SizedBox(height: 16),
          
          // Chat toggle hint
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _showCommandCenter = false),
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('Open AI Chat'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketTicker() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTickerItem('BTC', '\$67,234', '+2.4%', true),
            _buildTickerItem('ETH', '\$3,456', '+1.8%', true),
            _buildTickerItem('SOL', '\$142.5', '-0.5%', false),
            _buildTickerItem('BNB', '\$578', '+0.9%', true),
            _buildTickerItem('XRP', '\$0.523', '+3.2%', true),
            _buildTickerItem('ADA', '\$0.456', '-1.1%', false),
          ],
        ),
      ),
    );
  }

  Widget _buildTickerItem(String symbol, String price, String change, bool isPositive) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Row(
        children: [
          Text(
            symbol,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            price,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: isPositive 
                  ? AppTheme.positiveColor.withOpacity(0.2)
                  : AppTheme.negativeColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              change,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isPositive ? AppTheme.positiveColor : AppTheme.negativeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.premiumCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Portfolio Value',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppTheme.successGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.trending_up, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      '12.5%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _portfolioValue),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return ShaderMask(
                shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                child: Text(
                  '\$${_formatCurrency(value)}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatItem('Today', '+\$1,234', true),
              const SizedBox(width: 24),
              _buildStatItem('Week', '+\$5,678', true),
              const SizedBox(width: 24),
              _buildStatItem('P&L', '+\$15,450', true),
            ],
          ),
          const SizedBox(height: 16),
          // Mini chart placeholder
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.darkElevated.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomPaint(
              painter: _MiniChartPainter(isPositive: true),
              size: const Size(double.infinity, 60),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, bool isPositive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textTertiary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: isPositive ? AppTheme.positiveColor : AppTheme.negativeColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAIInsightsPanel() {
    final insights = [
      {
        'icon': Icons.lightbulb_outline,
        'title': 'Bullish Signal',
        'description': 'BTC showing strong momentum. RSI indicates room for growth.',
        'color': AppTheme.successColor,
        'confidence': 85,
      },
      {
        'icon': Icons.warning_amber_outlined,
        'title': 'Risk Alert',
        'description': 'High volatility expected. Consider defensive positions.',
        'color': AppTheme.warningColor,
        'confidence': 72,
      },
      {
        'icon': Icons.auto_awesome,
        'title': 'AI Recommendation',
        'description': 'Diversify into SOL and AVAX for better risk-adjusted returns.',
        'color': AppTheme.primaryColor,
        'confidence': 78,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI Insights',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...insights.map((insight) => _buildInsightItem(insight)),
        ],
      ),
    );
  }

  Widget _buildInsightItem(Map<String, dynamic> insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkElevated.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (insight['color'] as Color).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (insight['color'] as Color).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              insight['icon'] as IconData,
              color: insight['color'] as Color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight['title'] as String,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  insight['description'] as String,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '${insight['confidence']}%',
                style: TextStyle(
                  color: insight['color'] as Color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'confidence',
                style: TextStyle(
                  color: AppTheme.textTertiary,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivePositionsCard() {
    final positions = [
      {'symbol': 'BTC', 'qty': '0.45', 'entry': '\$45,123', 'current': '\$48,200', 'pnl': '+6.8%', 'isPositive': true},
      {'symbol': 'ETH', 'qty': '5.2', 'entry': '\$2,850', 'current': '\$3,100', 'pnl': '+8.7%', 'isPositive': true},
      {'symbol': 'SOL', 'qty': '125', 'entry': '\$145', 'current': '\$158', 'pnl': '+9.0%', 'isPositive': true},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Active Positions',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...positions.map((pos) => _buildPositionRow(pos)),
        ],
      ),
    );
  }

  Widget _buildPositionRow(Map<String, dynamic> pos) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkElevated.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                pos['symbol'] as String,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pos['symbol'] as String,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  pos['qty'] as String,
                  style: const TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                pos['current'] as String,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: pos['isPositive'] 
                      ? AppTheme.positiveColor.withOpacity(0.2)
                      : AppTheme.negativeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  pos['pnl'] as String,
                  style: TextStyle(
                    color: pos['isPositive'] ? AppTheme.positiveColor : AppTheme.negativeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildActionButton(Icons.swap_horiz, 'Swap', AppTheme.primaryColor)),
              const SizedBox(width: 12),
              Expanded(child: _buildActionButton(Icons.add_circle_outline, 'Deposit', AppTheme.successColor)),
              const SizedBox(width: 12),
              Expanded(child: _buildActionButton(Icons.analytics_outlined, 'Analyze', AppTheme.accentColor)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildActionButton(Icons.security, 'Secure', AppTheme.accentPink)),
              const SizedBox(width: 12),
              Expanded(child: _buildActionButton(Icons.history, 'History', AppTheme.infoColor)),
              const SizedBox(width: 12),
              Expanded(child: _buildActionButton(Icons.more_horiz, 'More', AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWhaleTrackerCard() {
    final whales = [
      {'address': '0x1234...5678', 'amount': '\$2.5M BTC', 'type': 'Buy', 'exchange': 'Binance'},
      {'address': '0xabcd...efgh', 'amount': '\$1.8M ETH', 'type': 'Sell', 'exchange': 'Coinbase'},
      {'address': '0x9876...5432', 'amount': '\$3.2M SOL', 'type': 'Buy', 'exchange': 'FTX'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.waves, color: AppTheme.infoColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Whale Tracker',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.infoColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: AppTheme.infoColor),
                    SizedBox(width: 4),
                    Text(
                      'Real-time',
                      style: TextStyle(
                        color: AppTheme.infoColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...whales.map((whale) => _buildWhaleItem(whale)),
        ],
      ),
    );
  }

  Widget _buildWhaleItem(Map<String, dynamic> whale) {
    final isBuy = whale['type'] == 'Buy';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkElevated.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isBuy 
                  ? AppTheme.positiveColor.withOpacity(0.2)
                  : AppTheme.negativeColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.whatshot,
              color: isBuy ? AppTheme.positiveColor : AppTheme.negativeColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  whale['address'] as String,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  whale['exchange'] as String,
                  style: const TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isBuy 
                  ? AppTheme.positiveColor.withOpacity(0.2)
                  : AppTheme.negativeColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              whale['type'] as String,
              style: TextStyle(
                color: isBuy ? AppTheme.positiveColor : AppTheme.negativeColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            whale['amount'] as String,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInterface(ChatBloc chatBloc, ChatState state) {
    return Column(
      children: [
        // Back to command center button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.dashboard, color: AppTheme.textSecondary),
                onPressed: () => setState(() => _showCommandCenter = true),
              ),
              const Expanded(
                child: Text(
                  'AI Assistant',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
        Expanded(
          child: BlocConsumer<ChatBloc, ChatState>(
            listener: (context, state) {
              if (state.status == ChatStatus.success) {
                _scrollToBottom();
              }
            },
            builder: (context, state) {
              if (state.messages.isEmpty) {
                return _buildEmptyChatState();
              }
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: state.messages.length,
                itemBuilder: (context, index) {
                  final message = state.messages[index];
                  return ChatBubble(
                    message: message.content,
                    isUser: message.isUser,
                    onSpeak: message.isUser
                        ? null
                        : () => _speakResponse(chatBloc, message.content),
                  );
                },
              );
            },
          ),
        ),
        _buildChatInput(chatBloc, state),
      ],
    );
  }

  Widget _buildEmptyChatState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text(
            'Hello! I\'m Ayobami',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Your AI-powered trading assistant. Ask me anything about crypto!',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildSuggestionChip('Analyze BTC'),
              _buildSuggestionChip('Best portfolio?'),
              _buildSuggestionChip('Trading signals'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _messageController.text = text;
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.glassBorder),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatInput(ChatBloc chatBloc, ChatState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.9),
        border: Border(top: BorderSide(color: AppTheme.glassBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.voiceStatus == VoiceStatus.listening)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildListeningIndicator(),
                  const SizedBox(width: 12),
                  const Text(
                    'Listening...',
                    style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          if (state.isSpeaking)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.volume_up, color: AppTheme.successColor),
                  SizedBox(width: 8),
                  Text(
                    'Speaking...',
                    style: TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Ask Ayobami anything...',
                    hintStyle: const TextStyle(color: AppTheme.textTertiary),
                    filled: true,
                    fillColor: AppTheme.darkElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  onSubmitted: (_) => _sendMessage(chatBloc),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: () => _sendMessage(chatBloc),
                ),
              ),
              const SizedBox(width: 8),
              VoiceButton(
                isListening: state.voiceStatus == VoiceStatus.listening,
                onPressed: state.voiceStatus == VoiceStatus.listening
                    ? () => _stopListening(chatBloc)
                    : () => _startListening(chatBloc),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListeningIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        return AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final delay = index * 0.2;
            final value = ((_pulseController.value + delay) % 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 4,
              height: 16 * value,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildSmartFAB(ChatBloc chatBloc, ChatState state) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.4 + (_pulseController.value * 0.2)),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: state.voiceStatus == VoiceStatus.listening
                ? () => _stopListening(chatBloc)
                : () => _startListening(chatBloc),
            backgroundColor: AppTheme.primaryColor,
            child: Icon(
              state.voiceStatus == VoiceStatus.listening ? Icons.stop : Icons.mic,
              color: Colors.white,
              size: 28,
            ),
          ),
        );
      },
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K'.replaceAll('.0K', 'K');
    }
    return value.toStringAsFixed(2);
  }
}

// Custom painters for decorative elements
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.glassBorder.withOpacity(0.1)
      ..strokeWidth = 0.5;

    const spacing = 50.0;
    
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniChartPainter extends CustomPainter {
  final bool isPositive;

  _MiniChartPainter({required this.isPositive});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: isPositive 
            ? [AppTheme.positiveColor.withOpacity(0.5), AppTheme.positiveColor.withOpacity(0.0)]
            : [AppTheme.negativeColor.withOpacity(0.5), AppTheme.negativeColor.withOpacity(0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final linePaint = Paint()
      ..color = isPositive ? AppTheme.positiveColor : AppTheme.negativeColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final fillPath = Path();
    
    final points = 20;
    final random = math.Random(42);
    
    double startY = size.height * 0.7;
    path.moveTo(0, startY);
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, startY);
    
    for (int i = 0; i <= points; i++) {
      final x = (size.width / points) * i;
      final noise = (random.nextDouble() - 0.5) * 20;
      final trend = isPositive 
          ? -((size.height / points) * i * 0.5)
          : ((size.height / points) * i * 0.5);
      final y = (startY + trend + noise).clamp(10.0, size.height - 10);
      
      if (i == 0) {
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    
    canvas.drawPath(fillPath, paint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
