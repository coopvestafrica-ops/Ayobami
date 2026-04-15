/// Social Trading - Leaderboards, Contests & Community
class SocialTradingHub {
  /// Get global leaderboard
  Future<List<TraderRanking>> getLeaderboard({
    required String period, // 'day', 'week', 'month', 'all'
    int limit = 50,
  }) async {
    return [
      TraderRanking(
        rank: 1,
        userId: 'trader_elite_001',
        username: 'CryptoGuru',
        winRate: 0.75,
        totalTrades: 234,
        roi: 245.5,
        followers: 5234,
        badges: ['verified', 'top_trader', 'profitable'],
      ),
      TraderRanking(
        rank: 2,
        userId: 'trader_pro_002',
        username: 'LunaTrader',
        winRate: 0.68,
        totalTrades: 189,
        roi: 189.2,
        followers: 3421,
        badges: ['verified', 'consistent'],
      ),
    ];
  }
  
  /// Follow trader for copy trading
  Future<bool> followTrader({
    required String userId,
    required String traderId,
    required double investmentAmount,
  }) async {
    return true;
  }
  
  /// Create trading contest
  Future<String> createContest({
    required String name,
    required double prizePool,
    required DateTime endDate,
    required String symbol,
  }) async {
    return 'contest_id_12345';
  }
  
  /// Get user's trading stats
  Future<TraderProfile> getTraderProfile(String userId) async {
    return TraderProfile(
      userId: userId,
      username: 'YourUsername',
      joinDate: DateTime(2023, 6, 1),
      totalTrades: 567,
      winRate: 0.58,
      roi: 125.3,
      followers: 234,
      following: 45,
      totalFollowerAssets: 450000,
      earnings: 3250,
      avgTradeProfit: 85,
    );
  }
}

class TraderRanking {
  final int rank;
  final String userId;
  final String username;
  final double winRate;
  final int totalTrades;
  final double roi;
  final int followers;
  final List<String> badges;
  
  TraderRanking({
    required this.rank,
    required this.userId,
    required this.username,
    required this.winRate,
    required this.totalTrades,
    required this.roi,
    required this.followers,
    required this.badges,
  });
}

class TraderProfile {
  final String userId;
  final String username;
  final DateTime joinDate;
  final int totalTrades;
  final double winRate;
  final double roi;
  final int followers;
  final int following;
  final double totalFollowerAssets;
  final double earnings;
  final double avgTradeProfit;
  
  TraderProfile({
    required this.userId,
    required this.username,
    required this.joinDate,
    required this.totalTrades,
    required this.winRate,
    required this.roi,
    required this.followers,
    required this.following,
    required this.totalFollowerAssets,
    required this.earnings,
    required this.avgTradeProfit,
  });
}
