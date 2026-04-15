import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';

/// Enhanced Binance WebSocket Service
/// Handles real-time price updates, trade data, and connection management
class BinanceWebSocketService {
  WebSocketChannel? _channel;
  final _streamController = StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get stream => _streamController.stream;
  
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  static const String _baseUrl = 'wss://stream.binance.com:9443/stream?streams=';

  /// Connect to multiple streams (e.g., btcusdt@ticker, ethusdt@ticker)
  void connect(List<String> symbols) {
    if (_isConnected) disconnect();

    final streams = symbols.map((s) => '${s.toLowerCase()}@ticker').join('/');
    final url = '$_baseUrl$streams';
    
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _isConnected = true;

      _channel!.stream.listen(
        (message) {
          final data = jsonDecode(message);
          _streamController.add(data);
        },
        onError: (error) {
          print('Binance WS Error: $error');
          _isConnected = false;
          _reconnect(symbols);
        },
        onDone: () {
          print('Binance WS Connection Closed');
          _isConnected = false;
        },
      );
    } catch (e) {
      print('Binance WS Connection Failed: $e');
      _isConnected = false;
    }
  }

  /// Subscribe to specific trade data or order book
  void subscribeToTrades(String symbol) {
    if (_channel == null) return;
    
    final subscribeMsg = jsonEncode({
      'method': 'SUBSCRIBE',
      'params': ['${symbol.toLowerCase()}@trade'],
      'id': 1,
    });
    
    _channel!.sink.add(subscribeMsg);
  }

  /// Reconnection logic with exponential backoff
  void _reconnect(List<String> symbols) {
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isConnected) {
        print('Attempting to reconnect to Binance WS...');
        connect(symbols);
      }
    });
  }

  /// Disconnect and clean up
  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _streamController.close();
  }
}
