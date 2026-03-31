import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// TradingView Advanced Chart Widget
/// Embeds the TradingView widget for professional charting
class TradingViewChart extends StatefulWidget {
  final String symbol;
  final bool isForex;

  const TradingViewChart({
    super.key,
    required this.symbol,
    this.isForex = false,
  });

  @override
  State<TradingViewChart> createState() => _TradingViewChartState();
}

class _TradingViewChartState extends State<TradingViewChart> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadHtmlString(_generateChartHtml());
  }

  /// Generate HTML for TradingView Advanced Chart widget
  String _generateChartHtml() {
    final symbol = _getTradingViewSymbol();
    final theme = 'dark'; // Can be 'light' or 'dark'
    final locale = 'en';

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    html, body {
      width: 100%;
      height: 100%;
      background-color: #131722;
      overflow: hidden;
    }
    #tradingview_chart {
      width: 100%;
      height: 100%;
    }
    .loading {
      position: absolute;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      color: #d1d4dc;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      font-size: 14px;
    }
  </style>
</head>
<body>
  <div id="tradingview_chart"></div>
  <div class="loading">Loading chart...</div>
  
  <script type="text/javascript" src="https://s3.tradingview.com/tv.js"></script>
  <script type="text/javascript">
    window.addEventListener('DOMContentLoaded', function() {
      document.querySelector('.loading').style.display = 'none';
      
      new TradingView.widget({
        "width": "100%",
        "height": "100%",
        "symbol": "$symbol",
        "interval": "D",
        "timezone": "Etc/UTC",
        "theme": "$theme",
        "style": "1",
        "locale": "$locale",
        "toolbar_bg": "#1e222d",
        "enable_publishing": false,
        "hide_side_toolbar": false,
        "allow_symbol_change": true,
        "container_id": "tradingview_chart",
        "hide_volume": false,
        " studies": [
          "MASimple@tv-basicstudies",
          "RSI@tv-basicstudies",
          "Volume@tv-basicstudies"
        ],
        "overrides": {
          "paneProperties.background": "#131722",
          "paneProperties.backgroundType": "solid",
          "scalesProperties.backgroundColor": "#131722",
          "scalesProperties.lineColor": "#363a45",
          "scalesProperties.textColor": "#d1d4dc",
          "mainSeriesProperties.candleStyle.upColor": "#26a69a",
          "mainSeriesProperties.candleStyle.downColor": "#ef5350",
          "mainSeriesProperties.candleStyle.borderUpColor": "#26a69a",
          "mainSeriesProperties.candleStyle.borderDownColor": "#ef5350",
          "mainSeriesProperties.candleStyle.wickUpColor": "#26a69a",
          "mainSeriesProperties.candleStyle.wickDownColor": "#ef5350"
        },
        "studies_overrides": {
          "volume.paneProperties.visible": true
        }
      });
    });
  </script>
</body>
</html>
''';
  }

  /// Convert symbol to TradingView format
  String _getTradingViewSymbol() {
    final symbol = widget.symbol.toUpperCase();

    if (widget.isForex) {
      // Forex pairs like EURUSD
      return symbol;
    }

    // Crypto pairs - TradingView uses BINANCE:SYMBOL format
    // Remove common suffixes
    String tvSymbol = symbol;
    if (tvSymbol.endsWith('USDT')) {
      tvSymbol = tvSymbol.replaceAll('USDT', '');
      return 'BINANCE:${tvSymbol}USD';
    } else if (tvSymbol.endsWith('USD')) {
      tvSymbol = tvSymbol.replaceAll('USD', '');
      return 'BINANCE:${tvSymbol}USD';
    } else if (tvSymbol.endsWith('BTC')) {
      tvSymbol = tvSymbol.replaceAll('BTC', '');
      return 'BINANCE:${tvSymbol}BTC';
    }

    // Default: treat as BINANCE:SYMBOL
    return 'BINANCE:$symbol';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: const Color(0xFF131722),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

/// TradingView Mini Chart Widget for list items
class TradingViewMiniChart extends StatelessWidget {
  final String symbol;
  final double priceChange;
  final double width;
  final double height;

  const TradingViewMiniChart({
    super.key,
    required this.symbol,
    required this.priceChange,
    this.width = 100,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    // Simple visual indicator based on price change
    final isPositive = priceChange >= 0;
    final color = isPositive ? Colors.green : Colors.red;
    final icon = isPositive ? Icons.trending_up : Icons.trending_down;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Icon(
          icon,
          color: color,
          size: height * 0.6,
        ),
      ),
    );
  }
}

/// Quick ticker widget showing sparkline-style mini chart
class TradingViewTickerWidget extends StatelessWidget {
  final String symbol;
  final double price;
  final double change;

  const TradingViewTickerWidget({
    super.key,
    required this.symbol,
    required this.price,
    required this.change,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = change >= 0;
    final changeColor = isPositive ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            symbol,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '\$${_formatPrice(price)}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: changeColor,
              ),
              Text(
                '${isPositive ? '+' : ''}${change.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: changeColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
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
