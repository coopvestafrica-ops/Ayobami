import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ayobami/core/theme/app_theme.dart';
import 'package:ayobami/data/datasources/remote/exchange_service.dart';
import 'package:ayobami/domain/entities/crypto_currency.dart';
import 'dart:math' as math;

class PortfolioPage extends StatefulWidget {
  final List<CryptoCurrency> marketPrices;
  
  const PortfolioPage({
    super.key,
    required this.marketPrices,
  });

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> with TickerProviderStateMixin {
  List<PortfolioHolding> _holdings = [];
  bool _isLoading = true;
  String? _error;
  bool _isSyncing = false;
  int _selectedTimeframe = 0;
  late AnimationController _refreshController;
  
  // Portfolio metrics (simulated for demo)
  double _totalValue = 125450.67;
  double _totalProfit = 15450.32;
  double _dayChange = 1234.56;
  double _sharpeRatio = 1.85;
  double _maxDrawdown = -8.2;
  double _winRate = 68.5;

  @override
  void initState() {
    super.initState();
    _loadPortfolio();
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadPortfolio() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final holdingsJson = prefs.getStringList('portfolio_holdings') ?? [];
      
      final holdings = holdingsJson.isEmpty
          ? [
              PortfolioHolding(symbol: 'BTC', amount: 0.45, avgBuyPrice: 42000),
              PortfolioHolding(symbol: 'ETH', amount: 5.2, avgBuyPrice: 2800),
              PortfolioHolding(symbol: 'SOL', amount: 125, avgBuyPrice: 95),
              PortfolioHolding(symbol: 'AVAX', amount: 50, avgBuyPrice: 35),
              PortfolioHolding(symbol: 'LINK', amount: 200, avgBuyPrice: 12),
            ]
          : holdingsJson.map((json) {
              final parts = json.split('|');
              return PortfolioHolding(
                symbol: parts[0],
                amount: double.parse(parts[1]),
                avgBuyPrice: double.parse(parts[2]),
              );
            }).toList();

      setState(() {
        _holdings = holdings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _syncFromExchange() async {
    setState(() => _isSyncing = true);
    _refreshController.repeat();

    try {
      final prefs = await SharedPreferences.getInstance();
      final binanceKey = prefs.getString('binance_api_key');
      final binanceSecret = prefs.getString('binance_api_secret');
      
      if (binanceKey == null || binanceSecret == null) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Connect API keys in Settings to sync'),
                ],
              ),
              backgroundColor: AppTheme.warningColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }

    _refreshController.stop();
    _refreshController.reset();
    setState(() => _isSyncing = false);
  }

  void _showAddHoldingDialog() {
    final symbolController = TextEditingController();
    final amountController = TextEditingController();
    final priceController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Add New Holding',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: symbolController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Symbol',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  hintText: 'e.g., BTC, ETH',
                  hintStyle: const TextStyle(color: AppTheme.textTertiary),
                  filled: true,
                  fillColor: AppTheme.darkElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  hintText: 'Enter quantity',
                  hintStyle: const TextStyle(color: AppTheme.textTertiary),
                  filled: true,
                  fillColor: AppTheme.darkElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Average Buy Price',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  prefixText: '\$ ',
                  prefixStyle: const TextStyle(color: AppTheme.textSecondary),
                  hintText: '0.00',
                  hintStyle: const TextStyle(color: AppTheme.textTertiary),
                  filled: true,
                  fillColor: AppTheme.darkElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppTheme.glassBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _loadPortfolio();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Add Holding'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.darkBackgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildEnterpriseAppBar(),
        body: _isLoading ? _buildLoadingState() : _buildContent(),
        floatingActionButton: _buildAddButton(),
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
          'PORTFOLIO',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 3,
          ),
        ),
      ),
      actions: [
        AnimatedBuilder(
          animation: _refreshController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _refreshController.value * 2 * math.pi,
              child: IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: _isSyncing ? AppTheme.primaryColor : AppTheme.textSecondary,
                ),
                onPressed: _isSyncing ? null : _syncFromExchange,
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.analytics_outlined, color: AppTheme.textSecondary),
          onPressed: () => _showAnalyticsSheet(),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppTheme.primaryColor,
          ),
          SizedBox(height: 16),
          Text(
            'Loading portfolio...',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPortfolioValueCard(),
          const SizedBox(height: 16),
          _buildTimeframeSelector(),
          const SizedBox(height: 16),
          _buildPerformanceChart(),
          const SizedBox(height: 16),
          _buildRiskMetricsCard(),
          const SizedBox(height: 16),
          _buildAssetAllocationCard(),
          const SizedBox(height: 16),
          _buildHoldingsSection(),
        ],
      ),
    );
  }

  Widget _buildPortfolioValueCard() {
    final profitPercent = _totalValue > 0 ? (_totalProfit / (_totalValue - _totalProfit) * 100) : 0;
    final dayChangePercent = (_dayChange / _totalValue) * 100;
    final isDayPositive = _dayChange >= 0;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Portfolio Value',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Protected', style: TextStyle(color: Colors.white, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _totalValue),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Text(
                '\$${_formatCurrency(value)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildValueStat('All Time P&L', '${profitPercent >= 0 ? '+' : ''}\$${_formatCurrency(_totalProfit)}', profitPercent)),
              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
              Expanded(child: _buildValueStat('Today', '${isDayPositive ? '+' : ''}\$${_formatCurrency(_dayChange)}', dayChangePercent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueStat(String label, String value, double percent) {
    final isPositive = percent >= 0;
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isPositive ? Colors.white.withOpacity(0.2) : Colors.red.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${isPositive ? '+' : ''}${percent.toStringAsFixed(1)}%',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeframeSelector() {
    final timeframes = ['1D', '1W', '1M', '3M', '1Y', 'ALL'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Row(
        children: List.generate(timeframes.length, (index) {
          final isSelected = _selectedTimeframe == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTimeframe = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppTheme.primaryGradient : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  timeframes[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPerformanceChart() {
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
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.show_chart, color: AppTheme.primaryColor, size: 18),
              ),
              const SizedBox(width: 12),
              const Text('Performance', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppTheme.successGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('+12.5%', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: CustomPaint(
              painter: _PortfolioChartPainter(),
              size: const Size(double.infinity, 150),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskMetricsCard() {
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
                decoration: BoxDecoration(color: AppTheme.warningColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.security, color: AppTheme.warningColor, size: 18),
              ),
              const SizedBox(width: 12),
              const Text('Risk Metrics', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildMetricItem('Sharpe Ratio', _sharpeRatio.toString(), _sharpeRatio >= 1)),
              Expanded(child: _buildMetricItem('Win Rate', '${_winRate.toStringAsFixed(1)}%', true)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMetricItem('Max Drawdown', '${_maxDrawdown.toStringAsFixed(1)}%', false)),
              Expanded(child: _buildMetricItem('Risk Score', 'Medium', null, label: 'MEDIUM')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, bool? isPositive, {String? label}) {
    final color = isPositive == null ? AppTheme.warningColor : (isPositive ? AppTheme.successColor : AppTheme.errorColor);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textTertiary, fontSize: 11)),
          const SizedBox(height: 4),
          Text(label ?? value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAssetAllocationCard() {
    final allocations = [
      {'name': 'BTC', 'value': 45, 'color': const Color(0xFFF7931A)},
      {'name': 'ETH', 'value': 30, 'color': const Color(0xFF627EEA)},
      {'name': 'SOL', 'value': 15, 'color': const Color(0xFF00FFA3)},
      {'name': 'Others', 'value': 10, 'color': const Color(0xFF6366F1)},
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
                decoration: BoxDecoration(color: AppTheme.accentColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.pie_chart, color: AppTheme.accentColor, size: 18),
              ),
              const SizedBox(width: 12),
              const Text('Asset Allocation', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CustomPaint(painter: _AllocationChartPainter(allocations)),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: allocations.map((a) => _buildAllocationRow(a)).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationRow(Map<String, dynamic> allocation) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: allocation['color'] as Color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Text(allocation['name'] as String, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12)),
          const Spacer(),
          Text('${allocation['value']}%', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHoldingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            const Text('Holdings', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('${_holdings.length} assets', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 16),
        ..._holdings.map((holding) => _buildHoldingCard(holding)),
      ],
    );
  }

  Widget _buildHoldingCard(PortfolioHolding holding) {
    double currentPrice = 0;
    try {
      final priceData = widget.marketPrices.firstWhere(
        (p) => p.symbol.toLowerCase() == holding.symbol.toLowerCase(),
      );
      currentPrice = priceData.currentPrice;
    } catch (_) {
      currentPrice = holding.avgBuyPrice * 1.1;
    }
    
    final currentValue = holding.amount * currentPrice;
    final costBasis = holding.amount * holding.avgBuyPrice;
    final profit = currentValue - costBasis;
    final profitPercent = costBasis > 0 ? (profit / costBasis) * 100 : 0;
    final isPositive = profit >= 0;
    
    final colors = {
      'BTC': const Color(0xFFF7931A),
      'ETH': const Color(0xFF627EEA),
      'SOL': const Color(0xFF00FFA3),
      'AVAX': const Color(0xFFE84142),
      'LINK': const Color(0xFF2A5ADA),
    };
    final color = colors[holding.symbol.toUpperCase()] ?? AppTheme.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                holding.symbol.substring(0, 1).toUpperCase(),
                style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(holding.symbol.toUpperCase(), style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 2),
                Text(
                  '${holding.amount.toStringAsFixed(4)} @ \$${holding.avgBuyPrice.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppTheme.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${_formatCurrency(currentValue)}', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive ? AppTheme.successColor.withOpacity(0.1) : AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isPositive ? AppTheme.successColor : AppTheme.errorColor,
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${isPositive ? '+' : ''}${profitPercent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: isPositive ? AppTheme.successColor : AppTheme.errorColor,
                        fontSize: 11,
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
    );
  }

  Widget _buildAddButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: AppTheme.primaryColor.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _showAddHoldingDialog,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAnalyticsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppTheme.glassBorder, borderRadius: BorderRadius.circular(2)),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Advanced Analytics', style: TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    _buildAnalyticsRow('Total Return', '+\$15,450', '+14.2%', true),
                    _buildAnalyticsRow('Annualized Return', '28.5%', null, true),
                    _buildAnalyticsRow('Best Trade', 'BTC Long', '+45.2%', true),
                    _buildAnalyticsRow('Worst Trade', 'SOL Short', '-12.3%', false),
                    _buildAnalyticsRow('Avg Trade Duration', '14 days', null, null),
                    _buildAnalyticsRow('Total Trades', '156', null, null),
                    _buildAnalyticsRow('Profitable Trades', '107 (68.5%)', null, true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsRow(String label, String value, String? percent, bool? isPositive) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.glassBorder))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  color: isPositive == null ? AppTheme.textPrimary : (isPositive ? AppTheme.successColor : AppTheme.errorColor),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (percent != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isPositive ?? true) ? AppTheme.successColor.withOpacity(0.1) : AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(percent, style: TextStyle(color: isPositive ?? true ? AppTheme.successColor : AppTheme.errorColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(2)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K'.replaceAll('.0K', 'K');
    return value.toStringAsFixed(2);
  }
}

class PortfolioHolding {
  final String symbol;
  final double amount;
  final double avgBuyPrice;

  PortfolioHolding({required this.symbol, required this.amount, required this.avgBuyPrice});
}

class _PortfolioChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [AppTheme.successColor.withOpacity(0.5), AppTheme.successColor.withOpacity(0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final linePaint = Paint()
      ..color = AppTheme.successColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final fillPath = Path();
    final points = 30;
    final random = math.Random(42);
    double startY = size.height * 0.7;
    path.moveTo(0, startY);
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, startY);
    
    for (int i = 0; i <= points; i++) {
      final x = (size.width / points) * i;
      final noise = (random.nextDouble() - 0.3) * 15;
      final trend = -(size.height / points) * i * 0.4;
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

class _AllocationChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> allocations;
  _AllocationChartPainter(this.allocations);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 5;
    double startAngle = -math.pi / 2;
    
    for (final allocation in allocations) {
      final sweepAngle = (allocation['value'] as int) / 100 * 2 * math.pi;
      final paint = Paint()
        ..color = allocation['color'] as Color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
    
    final centerPaint = Paint()..color = AppTheme.darkCard..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 15, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
