import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ayobami/core/di/injection_container.dart' as di;
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
    // Load market data and portfolio data when app starts
    _loadInitialData();
  }

  void _loadInitialData() {
    final marketBloc = di.sl<MarketBloc>();
    final portfolioBloc = di.sl<PortfolioBloc>();
    
    // Fetch market data
    marketBloc.add(const LoadMarketDataEvent());
    
    // Fetch portfolio data
    portfolioBloc.add(const LoadPortfolioEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              // PortfolioPage expects List<CryptoCurrency> for market prices
              // We can get this from MarketBloc
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: Icon(Icons.chat),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.trending_up_outlined),
            selectedIcon: Icon(Icons.trending_up),
            label: 'Market',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_graph_outlined),
            selectedIcon: Icon(Icons.auto_graph),
            label: 'Signals',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Portfolio',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
        ],
      ),
      drawer: _buildDrawer(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 30,
                  child: Icon(Icons.person, size: 30),
                ),
                const SizedBox(height: 12),
                Text(
                  'Ayobami',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  'AI Trading Assistant',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Price Alerts'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 4);
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('Portfolio'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 3);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExchangeSettingsPage(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog();
            },
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Ayobami'),
        content: const Text(
          'Ayobami is an AI-powered trading assistant that helps you make informed decisions in the crypto market.',
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
