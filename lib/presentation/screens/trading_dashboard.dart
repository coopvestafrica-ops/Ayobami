import 'package:flutter/material.dart';

class ProfessionalTradingDashboard extends StatefulWidget {
  const ProfessionalTradingDashboard({Key? key}) : super(key: key);

  @override
  State<ProfessionalTradingDashboard> createState() => _DashboardState();
}

class _DashboardState extends State<ProfessionalTradingDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text('Autonomous Trading Dashboard', style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildPortfolioHeader(),
            const SizedBox(height: 20),
            _buildMetrics(),
            const SizedBox(height: 20),
            _buildActivePositions(),
            const SizedBox(height: 20),
            _buildAutonomousStatus(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPortfolioHeader() {
    return Container(
      color: const Color(0xFF1A1F3A),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Portfolio Value', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 8),
          const Text('\$125,450', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
            child: const Text('↑ +12.5% this month', style: TextStyle(color: Colors.green, fontSize: 12)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetrics() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          _metricCard('Win Rate', '68%', Colors.green),
          _metricCard('P&L', '+\$15,650', Colors.green),
          _metricCard('Trades', '28', Colors.blue),
          _metricCard('Sharpe', '1.85', Colors.blue),
          _metricCard('Drawdown', '-8.2%', Colors.red),
          _metricCard('Ratio', '2.4:1', Colors.orange),
        ],
      ),
    );
  }
  
  Widget _metricCard(String title, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  
  Widget _buildActivePositions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F3A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Active Positions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            _positionRow('BTC', '0.45', '45,123', '48,200', '+6.8%', Colors.green),
            _positionRow('ETH', '5.2', '2,850', '3,100', '+8.7%', Colors.green),
            _positionRow('SOL', '125', '145', '158', '+9.0%', Colors.green),
          ],
        ),
      ),
    );
  }
  
  Widget _positionRow(String symbol, String qty, String entry, String current, String pnl, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(symbol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(qty, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(current, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              Text(pnl, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildAutonomousStatus() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F3A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green),
                ),
                const SizedBox(width: 8),
                const Text('Autonomous Trading ACTIVE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Risk Level: Medium', style: TextStyle(color: Colors.white54, fontSize: 11)),
                Text('Active Positions: 3/5', style: TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
