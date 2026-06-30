import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ayobami/core/di/injection_container.dart' as di;
import 'package:ayobami/core/theme/app_theme.dart';
import 'package:ayobami/domain/entities/crypto_currency.dart';
import 'package:ayobami/presentation/bloc/market/market_bloc.dart';
import 'package:ayobami/presentation/bloc/market/market_event.dart';
import 'package:ayobami/presentation/bloc/market/market_state.dart';
import 'package:ayobami/presentation/bloc/portfolio/portfolio_bloc.dart';
import 'package:ayobami/presentation/pages/home_page.dart';
import 'package:ayobami/presentation/pages/market_page.dart';
import 'package:ayobami/presentation/pages/trading_signals_page.dart';
import 'package:ayobami/presentation/pages/portfolio_page.dart';
import 'package:ayobami/presentation/pages/price_alerts_page.dart';
import 'package:ayobami/presentation/pages/exchange_settings_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    final marketBloc = di.sl<MarketBloc>();
    final portfolioBloc = di.sl<PortfolioBloc>();
    marketBloc.add(const LoadMarketDataEvent());
    portfolioBloc.add(const LoadPortfolioEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.darkBackgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: _currentIndex,
          children: [
            const HomePage(),
            const MarketPage(),
            BlocBuilder<MarketBloc, MarketState>(
              builder: (context, state) {
                return TradingSignalsPage(cryptos: state.cryptos);
              },
            ),
            BlocBuilder<PortfolioBloc, PortfolioState>(
              builder: (context, state) {
                return BlocBuilder<MarketBloc, MarketState>(
                  builder: (context, marketState) {
                    return PortfolioPage(marketPrices: marketState.cryptos);
                  },
                );
              },
            ),
            BlocBuilder<MarketBloc, MarketState>(
              builder: (context, state) {
                return PriceAlertsPage(cryptos: state.cryptos);
              },
            ),
          ],
        ),
        bottomNavigationBar: _buildEnterpriseBottomNav(),
        drawer: _buildDrawer(),
      ),
    );
  }

  Widget _buildEnterpriseBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withOpacity(0.95),
        border: Border(
          top: BorderSide(color: AppTheme.glassBorder, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.auto_awesome, Icons.auto_awesome, 'AI', 0),
              _buildNavItem(1, Icons.candlestick_chart_outlined, Icons.candlestick_chart, 'Markets', 1),
              _buildNavItem(2, Icons.analytics_outlined, Icons.analytics, 'Signals', 2),
              _buildNavItem(3, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, 'Portfolio', 3),
              _buildNavItem(4, Icons.notifications_outlined, Icons.notifications, 'Alerts', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label, int navIndex) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              size: 20,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.darkCard, AppTheme.darkBackground],
        ),
      ),
      child: Drawer(
        backgroundColor: Colors.transparent,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'AYOBAMI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const Text(
                    'Enterprise Trading Intelligence',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildDrawerItem(Icons.auto_awesome, 'AI Assistant', () {
              Navigator.pop(context);
              setState(() => _currentIndex = 0);
            }),
            _buildDrawerItem(Icons.candlestick_chart, 'Markets', () {
              Navigator.pop(context);
              setState(() => _currentIndex = 1);
            }),
            _buildDrawerItem(Icons.analytics, 'Trading Signals', () {
              Navigator.pop(context);
              setState(() => _currentIndex = 2);
            }),
            _buildDrawerItem(Icons.account_balance_wallet, 'Portfolio', () {
              Navigator.pop(context);
              setState(() => _currentIndex = 3);
            }),
            _buildDrawerItem(Icons.notifications, 'Price Alerts', () {
              Navigator.pop(context);
              setState(() => _currentIndex = 4);
            }),
            const Divider(color: AppTheme.glassBorder),
            _buildDrawerItem(Icons.security, 'Security Settings', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ExchangeSettingsPage()));
            }),
            _buildDrawerItem(Icons.settings, 'Settings', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ExchangeSettingsPage()));
            }),
            _buildDrawerItem(Icons.info_outline, 'About', () {
              Navigator.pop(context);
              _showAboutDialog();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: onTap,
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppTheme.primaryColor),
            SizedBox(width: 12),
            Text('About Ayobami', style: TextStyle(color: AppTheme.textPrimary)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ayobami is an enterprise-grade AI-powered trading assistant designed for professional traders and investors.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            SizedBox(height: 16),
            Text(
              'Version 1.0.0',
              style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
