import 'package:flutter/material.dart';
import 'package:ayobami/data/datasources/local/price_alerts_service.dart';
import 'package:ayobami/domain/entities/crypto_currency.dart';

class PriceAlertsPage extends StatefulWidget {
  final List<CryptoCurrency> cryptos;
  
  const PriceAlertsPage({
    super.key,
    required this.cryptos,
  });

  @override
  State<PriceAlertsPage> createState() => _PriceAlertsPageState();
}

class _PriceAlertsPageState extends State<PriceAlertsPage> {
  final PriceAlertsService _alertsService = PriceAlertsService();
  List<PriceAlert> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);
    final alerts = await _alertsService.getAlerts();
    setState(() {
      _alerts = alerts;
      _isLoading = false;
    });
  }

  Future<void> _addAlert(String cryptoId, String symbol, double price, AlertCondition condition) async {
    final alert = PriceAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cryptoId: cryptoId,
      symbol: symbol,
      targetPrice: price,
      condition: condition,
      createdAt: DateTime.now(),
    );
    await _alertsService.addAlert(alert);
    await _loadAlerts();
  }

  Future<void> _deleteAlert(String id) async {
    await _alertsService.removeAlert(id);
    await _loadAlerts();
  }

  Future<void> _toggleAlert(String id) async {
    await _alertsService.toggleAlert(id);
    await _loadAlerts();
  }

  void _showAddAlertDialog() {
    String? selectedCrypto;
    double targetPrice = 0;
    AlertCondition condition = AlertCondition.above;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Price Alert'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Crypto',
                  border: OutlineInputBorder(),
                ),
                items: widget.cryptos.map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Text('${c.name} (${c.symbol.toUpperCase()})'),
                )).toList(),
                onChanged: (value) {
                  setDialogState(() => selectedCrypto = value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Target Price (\$)',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  targetPrice = double.tryParse(value) ?? 0;
                },
              ),
              const SizedBox(height: 16),
              SegmentedButton<AlertCondition>(
                segments: const [
                  ButtonSegment(
                    value: AlertCondition.above,
                    label: Text('Above'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                  ButtonSegment(
                    value: AlertCondition.below,
                    label: Text('Below'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                ],
                selected: {condition},
                onSelectionChanged: (selection) {
                  setDialogState(() => condition = selection.first);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedCrypto != null && targetPrice > 0) {
                  final crypto = widget.cryptos.firstWhere((c) => c.id == selectedCrypto);
                  _addAlert(crypto.id, crypto.symbol, targetPrice, condition);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add Alert'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Price Alerts'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAlerts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alerts.isEmpty
              ? _buildEmptyState()
              : _buildAlertsList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAlertDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Alert'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No price alerts',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap + to create an alert',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _alerts.length,
      itemBuilder: (context, index) {
        final alert = _alerts[index];
        return _AlertCard(
          alert: alert,
          onToggle: () => _toggleAlert(alert.id),
          onDelete: () => _deleteAlert(alert.id),
        );
      },
    );
  }
}

class _AlertCard extends StatelessWidget {
  final PriceAlert alert;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _AlertCard({
    required this.alert,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getConditionColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            alert.condition == AlertCondition.above
                ? Icons.arrow_upward
                : Icons.arrow_downward,
            color: _getConditionColor(),
          ),
        ),
        title: Text(
          alert.symbol.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${alert.condition.name.toUpperCase()} \$${alert.targetPrice.toStringAsFixed(2)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: alert.isEnabled,
              onChanged: (_) => onToggle(),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Colors.red,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  Color _getConditionColor() {
    return alert.condition == AlertCondition.above ? Colors.green : Colors.red;
  }
}