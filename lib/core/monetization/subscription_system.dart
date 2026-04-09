import 'package:http/http.dart' as http;
import 'dart:convert';

/// Subscription & Payment System
class SubscriptionService {
  final String stripeApiKey;
  final String stripePublishableKey;
  
  SubscriptionService({
    required this.stripeApiKey,
    required this.stripePublishableKey,
  });
  
  /// Get available subscription tiers
  List<SubscriptionTier> getTiers() {
    return [
      SubscriptionTier(
        name: 'FREE',
        price: 0,
        features: ['Basic signals', 'Market data', '5 alerts/day'],
      ),
      SubscriptionTier(
        name: 'PRO',
        price: 49,
        features: ['All signals', 'Whale alerts', 'Unlimited alerts', 'Discord bot'],
      ),
      SubscriptionTier(
        name: 'ELITE',
        price: 199,
        features: ['Copy trading', 'NFT sniping', 'Arbitrage alerts', 'API access', 'Priority support'],
      ),
      SubscriptionTier(
        name: 'ENTERPRISE',
        price: 999,
        features: ['Everything', 'Custom API', 'White-label', 'Dedicated manager'],
      ),
    ];
  }
  
  /// Create subscription via Stripe
  Future<String?> createSubscription({
    required String userId,
    required String tierId,
    required String paymentMethodId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/subscriptions'),
        headers: {
          'Authorization': 'Bearer \$stripeApiKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'customer': userId,
          'items[0][price]': tierId,
          'payment_method': paymentMethodId,
          'off_session': 'true',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['id'];
      }
    } catch (e) {
      print('Subscription Error: \$e');
    }
    return null;
  }
  
  /// Check user tier
  Future<String> getUserTier(String userId) async {
    // Query database for active subscription
    return 'PRO'; // Example
  }
}

class SubscriptionTier {
  final String name;
  final double price;
  final List<String> features;
  
  SubscriptionTier({
    required this.name,
    required this.price,
    required this.features,
  });
}
