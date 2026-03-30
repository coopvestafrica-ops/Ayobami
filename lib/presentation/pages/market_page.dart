import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ayobami/core/di/injection_container.dart';
import 'package:ayobami/domain/entities/crypto_currency.dart';
import 'package:ayobami/presentation/bloc/market/market_bloc.dart';
import 'package:ayobami/presentation/bloc/market/market_event.dart';
import 'package:ayobami/presentation/bloc/market/market_state.dart';

class MarketPage extends StatefulWidget {
  const MarketPage({super.key});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Market'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Crypto'),
              Tab(text: 'Forex'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildCryptoTab(),
            _buildForexTab(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCryptoTab() {
    return BlocBuilder<MarketBloc, MarketState>(
      builder: (context, state) {
        return Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search crypto...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
                onChanged: (query) {
                  context.read<MarketBloc>().add(SearchCryptoEvent(query));
                },
              ),
            ),
            
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: state.filter == 'all',
                    onSelected: () => context.read<MarketBloc>()
                        .add(const FilterCryptoEvent('all')),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Gainers',
                    selected: state.filter == 'gainers',
                    onSelected: () => context.read<MarketBloc>()
                        .add(const FilterCryptoEvent('gainers')),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Losers',
                    selected: state.filter == 'losers',
                    onSelected: () => context.read<MarketBloc>()
                        .add(const FilterCryptoEvent('losers')),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Crypto list
            Expanded(
              child: state.status == MarketStatus.loading
                  ? const Center(child: CircularProgressIndicator())
                  : state.status == MarketStatus.error
                      ? Center(child: Text(state.errorMessage ?? 'Error loading data'))
                      : RefreshIndicator(
                          onRefresh: () async {
                            context.read<MarketBloc>()
                                .add(const RefreshMarketDataEvent());
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: state.filteredCryptos.length,
                            itemBuilder: (context, index) {
                              final crypto = state.filteredCryptos[index];
                              return _CryptoListItem(
                                crypto: crypto,
                                onTap: () => _showCryptoDetails(context, crypto),
                              );
                            },
                          ),
                        ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildForexTab() {
    return const Center(
      child: Text('Forex trading coming soon'),
    );
  }
  
  void _showCryptoDetails(BuildContext context, CryptoCurrency crypto) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CryptoDetailSheet(crypto: crypto),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });
  
  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }
}

class _CryptoListItem extends StatelessWidget {
  final CryptoCurrency crypto;
  final VoidCallback onTap;
  
  const _CryptoListItem({
    required this.crypto,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: crypto.image.isNotEmpty
              ? NetworkImage(crypto.image)
              : null,
          child: crypto.image.isEmpty
              ? Text(crypto.symbol.substring(0, 1))
              : null,
        ),
        title: Text(crypto.name),
        subtitle: Text(crypto.symbol.toUpperCase()),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${_formatPrice(crypto.currentPrice)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '${crypto.priceChangePercentage24h >= 0 ? '+' : ''}'
              '${crypto.priceChangePercentage24h.toStringAsFixed(2)}%',
              style: TextStyle(
                color: crypto.priceChangePercentage24h >= 0
                    ? Colors.green
                    : Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
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
                  '${crypto.priceChangePercentage24h >= 0 ? '+' : ''}'
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
                      onPressed: () {
                        // Add buy logic
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Buy ${'\$'}${crypto.symbol.toUpperCase()} - Coming soon')),
                        );
                      },
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
                      onPressed: () {
                        // Add sell logic
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sell - Coming soon')),
                        );
                      },
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