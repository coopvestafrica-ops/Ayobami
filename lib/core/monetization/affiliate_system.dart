/// Affiliate & Referral Commission System
class AffiliateSystem {
  /// Generate unique referral link for user
  String generateReferralLink(String userId) {
    return 'https://ayobami.com/ref/\${userId.substring(0, 8)}';
  }
  
  /// Track referral signup
  Future<bool> trackReferral({
    required String referrerId,
    required String newUserId,
  }) async {
    // Save to database
    return true;
  }
  
  /// Calculate affiliate commissions
  AffiliateCommission calculateCommission({
    required String affiliateId,
    required double referredUserSpending,
    required int referralCount,
  }) {
    const tieredRates = {
      1: 0.10, // 10% for 1-5 referrals
      6: 0.15, // 15% for 6-20 referrals
      21: 0.20, // 20% for 21+ referrals
    };
    
    double rate = 0.10;
    for (final entry in tieredRates.entries) {
      if (referralCount >= entry.key) rate = entry.value;
    }
    
    final commission = referredUserSpending * rate;
    
    return AffiliateCommission(
      affiliateId: affiliateId,
      referralCount: referralCount,
      totalReferred: referredUserSpending,
      commissionRate: rate,
      totalCommission: commission,
      pendingPayout: commission * 0.8, // 80% pending (20% held)
    );
  }
  
  /// Generate affiliate dashboard report
  Future<Map<String, dynamic>> getAffiliateStats(String userId) async {
    return {
      'totalReferrals': 45,
      'activeReferrals': 38,
      'totalReferred': 15400,
      'totalEarnings': 2750,
      'pendingPayout': 2200,
      'topEarningReferral': 'User#12345',
    };
  }
}

class AffiliateCommission {
  final String affiliateId;
  final int referralCount;
  final double totalReferred;
  final double commissionRate;
  final double totalCommission;
  final double pendingPayout;
  
  AffiliateCommission({
    required this.affiliateId,
    required this.referralCount,
    required this.totalReferred,
    required this.commissionRate,
    required this.totalCommission,
    required this.pendingPayout,
  });
}
