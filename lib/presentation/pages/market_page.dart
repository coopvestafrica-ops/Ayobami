import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ayobami/core/di/injection_container.dart';
import 'package:ayobami/core/theme/app_theme.dart';
import 'package:ayobami/domain/entities/crypto_currency.dart';
import 'package:ayobami/presentation/bloc/market/market_bloc.dart';
import 'package:ayobami/presentation/bloc/market/market_event.dart';
import 'package:ayobami/presentation/bloc/market/market_state.dart';
import 'package:ayobami/presentation/widgets/trading_view_chart.dart';
import 'package:ayobami/data/datasources/remote/exchange_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

class MarketPage extends StatefulWidget {
  const MarketPage({super.key});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  int _selectedTimeframe = 1; // 1D, 1W, 1M, 1Y
  bool _showHeatmap = false;
  String _sortBy = 'market_cap'; // market_cap, gainers, losers, volume
  
  final List<Map<String, dynamic>> _marketMovers = [
    {'symbol': 'PEPE', 'change': 45.2, 'price': 0.00001234},
    {'symbol': 'WIF', 'change': 28.5, 'price': 2.34},
    {'symbol': 'ORDI', 'change': 22.1, 'price': 45.6},
    {'symbol': 'SATS', 'change': 18.9, 'price': 0.000234},
    {'symbol': 'RENDER', 'change': 15.4, 'price': 7.89},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MarketBloc>()..add(const LoadMarketDataEvent()),
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.darkBackgroundGradient,
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: _buildEnterpriseAppBar(),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildCryptoTab(),
              _buildHeatmapTab(),
              _buildForexTab(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildEnterpriseAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const ShaderMask(
        shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
        child: Text(
          'MARKET',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 3,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _showHeatmap ? Icons.list : Icons.grid_view,
            color: AppTheme.textSecondary,
          ),
          onPressed: () {
            setState(() => _showHeatmap = !_showHeatmap);
            if (_showHeatmap) {
              _tabController.animateTo(1);
            } else {
              _tabController.animateTo(0);
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.filter_list, color: AppTheme.textSecondary),
          onPressed: () => _showSortOptions(),
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.primaryColor,
        indicatorWeight: 3,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: AppTheme.textSecondary,
        tabs: const [
          Tab(text: 'MARKETS', icon: Icon(Icons.candlestick_chart, size: 20)),
          Tab(text: 'HEATMAP', icon: Icon(Icons.grid_on, size: 20)),
          Tab(text: 'FOREX', icon: Icon(Icons.currency_exchange, size: 20)),
        ],
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sort By',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSortOption('Market Cap', 'market_cap'),
            _buildSortOption('Top Gainers', 'gainers'),
            _buildSortOption('Top Losers', 'losers'),
            _buildSortOption('Volume 24h', 'volume'),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, String value) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: AppTheme.textPrimary)),
      trailing: _sortBy == value 
          ? const Icon(Icons.check, color: AppTheme.primaryColor)
          : null,
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(context);
      },
    );
  }
  
  Widget _buildCryptoTab() {
    return BlocBuilder<MarketBloc, MarketState>(
      builder: (context, state) {
        return Column(
          children: [
            // Timeframe selector
            _buildTimeframeSelector(),
            
            // Search and filters
            _buildSearchAndFilters(context),
            
            // Market movers carousel
            if (state.status != MarketStatus.loading)
              _buildMarketMoversCarousel(),
            
            // Crypto list
            Expanded(
              child: state.status == MarketStatus.loading
                  ? _buildLoadingState()
                  : state.status == MarketStatus.error
                      ? _buildErrorState(state.errorMessage)
                      : _buildCryptoList(context, state),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimeframeSelector() {
    final timeframes = [
      {'label': '1D', 'value': 1},
      {'label': '1W', 'value': 7},
      {'label': '1M', 'value': 30},
      {'label': '1Y', 'value': 365},
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Row(
        children: timeframes.map((tf) {
          final isSelected = _selectedTimeframe == tf['value'];
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTimeframe = tf['value'] as int),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppTheme.primaryGradient : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tf['label'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Search crypto...',
                  hintStyle: TextStyle(color: AppTheme.textTertiary),
                  prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (query) {
                  context.read<MarketBloc>().add(SearchCryptoEvent(query));
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildFilterButton('Gainers', Icons.trending_up, AppTheme.successColor),
          const SizedBox(width: 8),
          _buildFilterButton('Losers', Icons.trending_down, AppTheme.negativeColor),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketMoversCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_fire_department, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'Top Movers',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: AppTheme.accentColor),
                    SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: AppTheme.accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _marketMovers.length,
            itemBuilder: (context, index) {
              final mover = _marketMovers[index];
              return _buildMoverCard(mover);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMoverCard(Map<String, dynamic> mover) {
    final change = mover['change'] as double;
    final isPositive = change >= 0;
    
    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: isPositive 
            ? LinearGradient(
                colors: [AppTheme.successColor.withOpacity(0.2), AppTheme.darkCard],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [AppTheme.negativeColor.withOpacity(0.2), AppTheme.darkCard],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPositive 
              ? AppTheme.successColor.withOpacity(0.3)
              : AppTheme.negativeColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                mover['symbol'] as String,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                color: isPositive ? AppTheme.successColor : AppTheme.negativeColor,
                size: 14,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\$${mover['price'] < 1 ? mover['price'].toStringAsFixed(6) : mover['price'].toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPositive 
                      ? AppTheme.successColor.withOpacity(0.2)
                      : AppTheme.negativeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${isPositive ? '+' : ''}${change.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: isPositive ? AppTheme.successColor : AppTheme.negativeColor,
                    fontSize: 12,
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

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Loading market data...',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 48),
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load market data',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            error ?? 'Unknown error',
            style: const TextStyle(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<MarketBloc>().add(const RefreshMarketDataEvent());
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildCryptoList(BuildContext context, MarketState state) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<MarketBloc>().add(const RefreshMarketDataEvent());
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: state.filteredCryptos.length,
        itemBuilder: (context, index) {
          final crypto = state.filteredCryptos[index];
          return _buildCryptoCard(context, crypto);
        },
      ),
    );
  }

  Widget _buildCryptoCard(BuildContext context, CryptoCurrency crypto) {
    final isPositive = crypto.priceChangePercentage24h >= 0;
    final changeColor = isPositive ? AppTheme.successColor : AppTheme.negativeColor;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showCryptoDetails(context, crypto),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Rank
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.darkElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${crypto.marketCapRank}',
                      style: const TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Icon and name
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: crypto.image.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(crypto.image, width: 36, height: 36),
                          )
                        : Text(
                            crypto.symbol.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Name and symbol
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        crypto.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        crypto.symbol.toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Mini sparkline
                Container(
                  width: 60,
                  height: 30,
                  margin: const EdgeInsets.only(right: 12),
                  child: CustomPaint(
                    painter: _SparklinePainter(isPositive: isPositive),
                  ),
                ),
                
                // Price and change
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${_formatPrice(crypto.currentPrice)}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: changeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                            color: changeColor,
                            size: 10,
                          ),
                          Text(
                            '${isPositive ? '+' : ''}${crypto.priceChangePercentage24h.toStringAsFixed(2)}%',
                            style: TextStyle(
                              color: changeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeatmapTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Market Heatmap',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sector performance over selected timeframe',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 24),
          _buildHeatmapGrid(),
          const SizedBox(height: 24),
          _buildHeatmapLegend(),
        ],
      ),
    );
  }

  Widget _buildHeatmapGrid() {
    final sectors = [
      {'name': 'DeFi', 'change': 12.5},
      {'name': 'Layer1', 'change': 8.3},
      {'name': 'Gaming', 'change': -3.2},
      {'name': 'NFT', 'change': -7.8},
      {'name': 'Metaverse', 'change': 5.4},
      {'name': 'AI', 'change': 15.2},
      {'name': 'Meme', 'change': 28.5},
      {'name': 'Privacy', 'change': -1.5},
      {'name': 'Infrastructure', 'change': 6.7},
      {'name': 'RWA', 'change': 9.1},
      {'name': 'Social', 'change': -2.8},
      {'name': 'Storage', 'change': 4.2},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: sectors.length,
      itemBuilder: (context, index) {
        final sector = sectors[index];
        return _buildHeatmapTile(sector);
      },
    );
  }

  Widget _buildHeatmapTile(Map<String, dynamic> sector) {
    final change = sector['change'] as double;
    final isPositive = change >= 0;
    final intensity = (change.abs() / 30).clamp(0.2, 1.0);
    
    final color = isPositive 
        ? AppTheme.successColor.withOpacity(intensity)
        : AppTheme.negativeColor.withOpacity(intensity);

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPositive 
              ? AppTheme.successColor.withOpacity(intensity + 0.2)
              : AppTheme.negativeColor.withOpacity(intensity + 0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            sector['name'] as String,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${isPositive ? '+' : ''}${change.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem('-20%', AppTheme.negativeColor.withOpacity(0.8)),
          _buildLegendItem('-10%', AppTheme.negativeColor.withOpacity(0.4)),
          _buildLegendItem('0%', AppTheme.darkElevated),
          _buildLegendItem('+10%', AppTheme.successColor.withOpacity(0.4)),
          _buildLegendItem('+30%', AppTheme.successColor.withOpacity(0.8)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildForexTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.currency_exchange, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text(
            'Forex Trading',
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
              'Professional forex trading with real-time rates and AI-powered analysis',
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
            label: const Text('Get Notified'),
          ),
        ],
      ),
    );
  }
  
  void _showCryptoDetails(BuildContext context, CryptoCurrency crypto) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CryptoDetailSheet(crypto: crypto),
    );
  }
  
  String _formatPrice(double price) {
    if (price >= 1) {
      return price.toStringAsFixed(2);
    } else {
      return price.toStringAsFixed(6);
    }
  }
}

class _CryptoDetailSheet extends StatelessWidget {
  final CryptoCurrency crypto;
  
  const _CryptoDetailSheet({required this.crypto});
  
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: crypto.image.isNotEmpty
                        ? NetworkImage(crypto.image)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          crypto.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          crypto.symbol.toUpperCase(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '#${crypto.marketCapRank}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Price
              Text(
                '\$${_formatPrice(crypto.currentPrice)}',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              
             // Price change
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: crypto.priceChangePercentage24h >= 0
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${crypto.priceChangePercentage24h.toStringAsFixed(2)}% (24h)',
                  style: TextStyle(
                    color: crypto.priceChangePercentage24h >= 0
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // TradingView Chart Section
              const Text(
                'Chart',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              
              // TradingView Chart
              TradingViewChart(
                symbol: '${crypto.symbol.toUpperCase()}USDT',
                isForex: false,
              ),
              
              const SizedBox(height: 24),
              
              // Stats
              _StatRow(label: 'Market Cap', value: _formatLargeNumber(crypto.marketCap)),
              _StatRow(label: '24h Volume', value: _formatLargeNumber(crypto.totalVolume)),
              _StatRow(label: '24h High', value: '\$${_formatPrice(crypto.high24h)}'),
              _StatRow(label: '24h Low', value: '\$${_formatPrice(crypto.low24h)}'),
              
              const SizedBox(height: 24),
              
              // Quick actions
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _handleTrade(context, crypto, 'BUY'),
                      child: const Text('Buy'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _handleTrade(context, crypto, 'SELL'),
                      child: const Text('Sell'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  String _formatPrice(double price) {
    if (price >= 1) {
      return price.toStringAsFixed(2);
    } else {
      return price.toStringAsFixed(6);
    }
  }
  
  String _formatLargeNumber(double number) {
    if (number >= 1e12) {
      return '\$${(number / 1e12).toStringAsFixed(2)}T';
    } else if (number >= 1e9) {
      return '\$${(number / 1e9).toStringAsFixed(2)}B';
    } else if (number >= 1e6) {
      return '\$${(number / 1e6).toStringAsFixed(2)}M';
    } else {
      return '\$${number.toStringAsFixed(2)}';
    }
  }

  Future<void> _handleTrade(BuildContext context, CryptoCurrency crypto, String side) async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('binance_api_key');
    final apiSecret = prefs.getString('binance_api_secret');
    final isTestnet = prefs.getBool('binance_testnet') ?? false;

    if (apiKey == null || apiSecret == null || apiKey.isEmpty || apiSecret.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please configure Binance API keys in Settings first')),
        );
      }
      return;
    }

    final exchangeService = ExchangeService();
    await exchangeService.initBinance(
      apiKey: apiKey,
      apiSecret: apiSecret,
      isTestnet: isTestnet,
    );

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) {
          final amountController = TextEditingController();
          return AlertDialog(
            title: Text('$side ${crypto.symbol.toUpperCase()}'),
            content: TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                hintText: 'Enter quantity to trade',
              ),
              keyboardType: TextInputType.number,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text);
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid amount')),
                    );
                    return;
                  }

                  Navigator.pop(context);
                  try {
                    if (side == 'BUY') {
                      await exchangeService.placeBuyOrder(
                        symbol: '${crypto.symbol.toUpperCase()}USDT',
                        amount: amount,
                        price: crypto.currentPrice,
                      );
                    } else {
                      await exchangeService.placeSellOrder(
                        symbol: '${crypto.symbol.toUpperCase()}USDT',
                        quantity: amount,
                        price: crypto.currentPrice,
                      );
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Successfully placed $side order for $amount ${crypto.symbol.toUpperCase()}')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Trade failed: ${e.toString()}')),
                      );
                    }
                  }
                },
                child: Text(side),
              ),
            ],
          );
        },
      );
    }
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  
  const _StatRow({required this.label, required this.value});
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
