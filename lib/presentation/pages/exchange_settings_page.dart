import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ayobami/data/datasources/remote/exchange_service.dart';

class ExchangeSettingsPage extends StatefulWidget {
  const ExchangeSettingsPage({super.key});

  @override
  State<ExchangeSettingsPage> createState() => _ExchangeSettingsPageState();
}

class _ExchangeSettingsPageState extends State<ExchangeSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Binance controllers
  final _binanceApiKey = TextEditingController();
  final _binanceApiSecret = TextEditingController();
  bool _binanceTestnet = false;
  
  // Coinbase controllers
  final _coinbaseApiKey = TextEditingController();
  final _coinbaseApiSecret = TextEditingController();
  final _coinbasePassphrase = TextEditingController();
  
  // OpenAI controller
  final _openaiApiKey = TextEditingController();
  
  bool _isBinanceConnected = false;
  bool _isCoinbaseConnected = false;
  bool _isOpenAIConnected = false;
  bool _isSaving = false;
  
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
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _binanceApiKey.text = prefs.getString('binance_api_key') ?? '';
      _binanceApiSecret.text = prefs.getString('binance_api_secret') ?? '';
      _binanceTestnet = prefs.getBool('binance_testnet') ?? false;
      _coinbaseApiKey.text = prefs.getString('coinbase_api_key') ?? '';
      _coinbaseApiSecret.text = prefs.getString('coinbase_api_secret') ?? '';
      _coinbasePassphrase.text = prefs.getString('coinbase_passphrase') ?? '';
      _openaiApiKey.text = prefs.getString('openai_api_key') ?? '';
      _isBinanceConnected = _binanceApiKey.text.isNotEmpty;
      _isCoinbaseConnected = _coinbaseApiKey.text.isNotEmpty;
      _isOpenAIConnected = _openaiApiKey.text.isNotEmpty;
    });
  }

  Future<void> _saveBinanceSettings() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('binance_api_key', _binanceApiKey.text);
    await prefs.setString('binance_api_secret', _binanceApiSecret.text);
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
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('coinbase_api_key', _coinbaseApiKey.text);
    await prefs.setString('coinbase_api_secret', _coinbaseApiSecret.text);
    await prefs.setString('coinbase_passphrase', _coinbasePassphrase.text);
    
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

  Future<void> _clearBinanceSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('binance_api_key');
    await prefs.remove('binance_api_secret');
    await prefs.remove('binance_testnet');
    
    setState(() {
      _binanceApiKey.clear();
      _binanceApiSecret.clear();
      _binanceTestnet = false;
      _isBinanceConnected = false;
    });
  }

  Future<void> _clearCoinbaseSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('coinbase_api_key');
    await prefs.remove('coinbase_api_secret');
    await prefs.remove('coinbase_passphrase');
    
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
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('openai_api_key', _openaiApiKey.text);
    
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('openai_api_key');
    
    setState(() {
      _openaiApiKey.clear();
      _isOpenAIConnected = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exchange Settings'),
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
                title: const Text('Use Testnet'),
                subtitle: const Text('For testing without real funds'),
                value: _binanceTestnet,
                onChanged: (value) {
                  setState(() => _binanceTestnet = value);
                },
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveBinanceSettings,
                      icon: const Icon(Icons.save),
                      label: Text(_isSaving ? 'Saving...' : 'Save'),
                    ),
                  ),
                  if (_isBinanceConnected) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _clearBinanceSettings,
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red,
                      tooltip: 'Remove credentials',
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
                      label: Text(_isSaving ? 'Saving...' : 'Save'),
                    ),
                  ),
                  if (_isCoinbaseConnected) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _clearCoinbaseSettings,
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red,
                      tooltip: 'Remove credentials',
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
            const Divider(),
            _buildStatusRow('Coinbase', _isCoinbaseConnected),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String exchange, bool connected) {
    return ListTile(
      leading: Icon(
        connected ? Icons.check_circle : Icons.cancel,
        color: connected ? Colors.green : Colors.grey,
      ),
      title: Text(exchange),
      subtitle: Text(connected ? 'Connected' : 'Not configured'),
      trailing: connected
          ? TextButton(
              onPressed: exchange == 'Binance'
                  ? _clearBinanceSettings
                  : _clearCoinbaseSettings,
              child: const Text('Disconnect'),
            )
          : null,
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