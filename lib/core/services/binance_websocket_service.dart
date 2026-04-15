import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class BinanceWebSocketService {
  WebSocketChannel? _channel;
  
  Stream<dynamic> get stream => _channel?.stream ?? const Stream.empty();

  void connect(List<String> symbols) {
    if (_channel != null) disconnect();
    
    final streams = symbols.map((s) => '${s.toLowerCase()}@ticker').join('/');
    final url = 'wss://stream.binance.com:9443/stream?streams=$streams';
    
    _channel = WebSocketChannel.connect(Uri.parse(url));
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
