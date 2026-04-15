import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ayobami/data/datasources/remote/exchange_service.dart';

class ExchangeSettingsPage extends StatefulWidget {
  const ExchangeSettingsPage({super.key});

  @override
  State<ExchangeSettingsPage> createState() => _ExchangeSettingsPageState();
}

class _ExchangeSettingsPageState extends State<ExchangeSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _secureStorage = const FlutterSecureStorage();
  
  // Binance controllers
  final _binanceApiKey = TextEditingController();
  final _binanceApiSecret = TextEditingController();
  bool _binanceTestnet = false;
  
  // Coinbase controllers
  final _coinbaseApiKey = TextEditingController();
  final _coinbaseApiSecret = TextEditingController();
  final _coinbasePassphrase = TextEditingController();
  
  bool _isBinanceConnected = false;
  bool _isCoinbaseConnected = false;
  bool _isSaving = false;
  bool _isOpenAIConnected = false;
  final _openaiApiKey = TextEditingController();
  
  // Auto-Trade Settings
  bool _autoTradeEnabled = false;
  final _maxPositionSize = TextEditingController(text: '10.0');
  final _stopLossPercent = TextEditingController(text: '5.0');
  final _takeProfitPercent = TextEditingController(text: '10.0');
  bool _executeStrongSignalsOnly = true;
  
  ExchangeType _selectedExchange = ExchangeType.binance;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _binanceApiKey.dispose();
    _binanceApiSecret.dispose();
    _coinbaseApiKey.dispose();
    _coinbaseApiSecret.dispose();
    _coinbasePassphrase.dispose();
    _openaiApiKey.dispose();
    _maxPositionSize.dispose();
    _stopLossPercent.dispose();
    _takeProfitPercent.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final binanceApiKey = await _secureStorage.read(key: 'binance_api_key') ?? '';
    final binanceApiSecret = await _secureStorage.read(key: 'binance_api_secret') ?? '';
    final coinbaseApiKey = await _secureStorage.read(key: 'coinbase_api_key') ?? '';
    final coinbaseApiSecret = await _secureStorage.read(key: 'coinbase_api_secret') ?? '';
    final coinbasePassphrase = await _secureStorage.read(key: 'coinbase_passphrase') ?? '';
    final openaiApiKey = await _secureStorage.read(key: 'openai_api_key') ?? '';

    setState(() {
      _binanceApiKey.text = binanceApiKey;
      _binanceApiSecret.text = binanceApiSecret;
      _binanceTestnet = prefs.getBool('binance_testnet') ?? false;
      _coinbaseApiKey.text = coinbaseApiKey;
      _coinbaseApiSecret.text = coinbaseApiSecret;
      _coinbasePassphrase.text = coinbasePassphrase;
      _isBinanceConnected = _binanceApiKey.text.isNotEmpty;
      _isCoinbaseConnected = _coinbaseApiKey.text.isNotEmpty;
      _openaiApiKey.text = openaiApiKey;
      _isOpenAIConnected = _openaiApiKey.text.isNotEmpty;
      
      // Auto-Trade Settings
      _autoTradeEnabled = prefs.getBool('auto_trade_enabled') ?? false;
      _maxPositionSize.text = (prefs.getDouble('max_position_size') ?? 10.0).toString();
      _stopLossPercent.text = (prefs.getDouble('stop_loss_percent') ?? 5.0).toString();
      _takeProfitPercent.text = (prefs.getDouble('take_profit_percent') ?? 10.0).toString();
      _executeStrongSignalsOnly = prefs.getBool('execute_strong_signals_only') ?? true;
    });
  }

  Future<void> _saveBinanceSettings() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.write(key: 'binance_api_key', value: _binanceApiKey.text);
    await _secureStorage.write(key: 'binance_api_secret', value: _binanceApiSecret.text);
    await prefs.setBool('binance_testnet', _binanceTestnet);
    
    setState(() {
      _isSaving = false;
      _isBinanceConnected = _binanceApiKey.text.isNotEmpty;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Binance settings saved')),
      );
    }
  }

  Future<void> _saveCoinbaseSettings() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    await _secureStorage.write(key: 'coinbase_api_key', value: _coinbaseApiKey.text);
    await _secureStorage.write(key: 'coinbase_api_secret', value: _coinbaseApiSecret.text);
    await _secureStorage.write(key: 'coinbase_passphrase', value: _coinbasePassphrase.text);
    
    setState(() {
      _isSaving = false;
      _isCoinbaseConnected = _coinbaseApiKey.text.isNotEmpty;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coinbase settings saved')),
      );
    }
  }

  Future<void> _saveAutoTradeSettings() async {
    setState(() => _isSaving = true);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_trade_enabled', _autoTradeEnabled);
    await prefs.setDouble('max_position_size', double.tryParse(_maxPositionSize.text) ?? 10.0);
    await prefs.setDouble('stop_loss_percent', double.tryParse(_stopLossPercent.text) ?? 5.0);
    await prefs.setDouble('take_profit_percent', double.tryParse(_takeProfitPercent.text) ?? 10.0);
    await prefs.setBool('execute_strong_signals_only', _executeStrongSignalsOnly);
    
    setState(() => _isSaving = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Auto-Trade settings saved')),
      );
    }
  }

  Future<void> _clearBinanceSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.delete(key: 'binance_api_key');
    await _secureStorage.delete(key: 'binance_api_secret');
    await prefs.remove('binance_testnet');
    
    setState(() {
      _binanceApiKey.clear();
      _binanceApiSecret.clear();
      _binanceTestnet = false;
      _isBinanceConnected = false;
    });
  }

  Future<void> _clearCoinbaseSettings() async {
    await _secureStorage.delete(key: 'coinbase_api_key');
    await _secureStorage.delete(key: 'coinbase_api_secret');
    await _secureStorage.delete(key: 'coinbase_passphrase');
    
    setState(() {
      _coinbaseApiKey.clear();
      _coinbaseApiSecret.clear();
      _coinbasePassphrase.clear();
      _isCoinbaseConnected = false;
    });
  }

  Future<void> _saveOpenAISettings() async {
    if (_openaiApiKey.text.isEmpty) return;
    
    setState(() => _isSaving = true);
    
    await _secureStorage.write(key: 'openai_api_key', value: _openaiApiKey.text);
    
    setState(() {
      _isSaving = false;
      _isOpenAIConnected = _openaiApiKey.text.isNotEmpty;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OpenAI settings saved. AI chat is now enabled!')),
      );
    }
  }

  Future<void> _clearOpenAISettings() async {
    await _secureStorage.delete(key: 'openai_api_key');
    
    setState(() {
      _openaiApiKey.clear();
      _isOpenAIConnected = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Automation'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning card
            _buildWarningCard(),
            const SizedBox(height: 24),
            
            // Auto-Trade Section
            _buildAutoTradeSection(),
            const SizedBox(height: 24),
            
            // Exchange selector
            _buildExchangeSelector(),
            const SizedBox(height: 24),
            
            // Settings form based on selected exchange
            if (_selectedExchange == ExchangeType.binance)
              _buildBinanceForm()
            else
              _buildCoinbaseForm(),
            
            const SizedBox(height: 24),
            
            // Connection status
            _buildConnectionStatus(),
            const SizedBox(height: 24),
            
            // OpenAI Settings
            _buildOpenAIForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningCard() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Security Notice',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your API keys are stored locally. Never share your API secret. Use read-only or trade permissions only.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoTradeSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_fix_high, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Autonomous Trading',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                Switch(
                  value: _autoTradeEnabled,
                  onChanged: (value) {
                    setState(() => _autoTradeEnabled = value);
                    _saveAutoTradeSettings();
                  },
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Risk Management Logic',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _maxPositionSize,
                    decoration: const InputDecoration(
                      labelText: 'Max Position (%)',
                      border: OutlineInputBorder(),
                      suffixText: '%',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _saveAutoTradeSettings(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _stopLossPercent,
                    decoration: const InputDecoration(
                      labelText: 'Stop Loss (%)',
                      border: OutlineInputBorder(),
                      suffixText: '%',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _saveAutoTradeSettings(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _takeProfitPercent,
                    decoration: const InputDecoration(
                      labelText: 'Take Profit (%)',
                      border: OutlineInputBorder(),
                      suffixText: '%',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _saveAutoTradeSettings(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Checkbox(
                        value: _executeStrongSignalsOnly,
                        onChanged: (value) {
                          setState(() => _executeStrongSignalsOnly = value ?? true);
                          _saveAutoTradeSettings();
                        },
                      ),
                      const Expanded(
                        child: Text(
                          'Strong Signals Only',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'When enabled, the app will automatically execute trades based on AI signals using these risk parameters.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExchangeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Exchange',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        SegmentedButton<ExchangeType>(
          segments: const [
            ButtonSegment(
              value: ExchangeType.binance,
              label: Text('Binance'),
              icon: Icon(Icons.currency_exchange),
            ),
            ButtonSegment(
              value: ExchangeType.coinbase,
              label: Text('Coinbase'),
              icon: Icon(Icons.account_balance_wallet),
            ),
          ],
          selected: {_selectedExchange},
          onSelectionChanged: (selection) {
            setState(() => _selectedExchange = selection.first);
          },
        ),
      ],
    );
  }

  Widget _buildBinanceForm() {
    return Form(
      key: _formKey,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Binance API Configuration',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _binanceApiKey,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.key),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'API Key is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _binanceApiSecret,
                decoration: const InputDecoration(
                  labelText: 'API Secret',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'API Secret is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              SwitchListTile(
                title: const Text('Use Testnet (Sandbox)'),
                subtitle: const Text('Highly recommended for testing'),
                value: _binanceTestnet,
                onChanged: (value) => setState(() => _binanceTestnet = value),
              ),
              
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveBinanceSettings,
                      icon: const Icon(Icons.save),
                      label: Text(_isSaving ? 'Saving...' : 'Save Binance Settings'),
                    ),
                  ),
                  if (_isBinanceConnected) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _clearBinanceSettings,
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red,
                      tooltip: 'Clear credentials',
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoinbaseForm() {
    return Form(
      key: _formKey,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Coinbase API Configuration',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _coinbaseApiKey,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.key),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'API Key is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _coinbaseApiSecret,
                decoration: const InputDecoration(
                  labelText: 'API Secret',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'API Secret is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _coinbasePassphrase,
                decoration: const InputDecoration(
                  labelText: 'Passphrase',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.password),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Passphrase is required';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveCoinbaseSettings,
                      icon: const Icon(Icons.save),
                      label: Text(_isSaving ? 'Saving...' : 'Save Coinbase Settings'),
                    ),
                  ),
                  if (_isCoinbaseConnected) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _clearCoinbaseSettings,
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red,
                      tooltip: 'Clear credentials',
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connection Status',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            _buildStatusRow('Binance', _isBinanceConnected),
            const SizedBox(height: 8),
            _buildStatusRow('Coinbase', _isCoinbaseConnected),
            const SizedBox(height: 8),
            _buildStatusRow('OpenAI (AI Engine)', _isOpenAIConnected),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool isConnected) {
    return Row(
      children: [
        Icon(
          isConnected ? Icons.check_circle : Icons.cancel,
          color: isConnected ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 12),
        Text(label),
        const Spacer(),
        Text(
          isConnected ? 'Connected' : 'Disconnected',
          style: TextStyle(
            color: isConnected ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildOpenAIForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.smart_toy, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'AI Chat Settings',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Connect OpenAI to enable true AI-powered chat with real crypto data.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _openaiApiKey,
              decoration: InputDecoration(
                labelText: 'OpenAI API Key',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.key),
                helperText: 'Get your key from platform.openai.com',
                suffixIcon: _isOpenAIConnected
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveOpenAISettings,
                    icon: const Icon(Icons.save),
                    label: Text(_isSaving ? 'Saving...' : 'Enable AI'),
                  ),
                ),
                if (_isOpenAIConnected) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _clearOpenAISettings,
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                    tooltip: 'Remove API key',
                  ),
                ],
              ],
            ),
            if (_isOpenAIConnected) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'AI chat is active!',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
