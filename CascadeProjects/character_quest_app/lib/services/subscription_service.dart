import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subscription.dart';
import '../config/supabase_config.dart';

class SubscriptionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get character's active subscriptions
  Future<List<Subscription>> getActiveSubscriptions(String characterId) async {
    try {
      final response = await _supabase
          .from('subscriptions')
          .select()
          .eq('character_id', characterId)
          .eq('status', SubscriptionStatus.active.name)
          .gte('end_date', DateTime.now().toIso8601String());

      return (response as List)
          .map((json) => Subscription.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting active subscriptions: $e');
      return [];
    }
  }

  /// Get subscription benefits for character
  Future<SubscriptionBenefits> getSubscriptionBenefits(String characterId) async {
    try {
      final activeSubscriptions = await getActiveSubscriptions(characterId);
      final subscriptionTypes = activeSubscriptions.map((s) => s.type).toList();

      return SubscriptionBenefits(
        activeSubscriptions: subscriptionTypes,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      print('Error getting subscription benefits: $e');
      return SubscriptionBenefits(activeSubscriptions: []);
    }
  }

  /// Create new subscription
  Future<Subscription?> createSubscription({
    required String characterId,
    required SubscriptionType type,
    required int durationMonths,
    bool autoRenew = true,
  }) async {
    try {
      final startDate = DateTime.now();
      final endDate = DateTime(
        startDate.year,
        startDate.month + durationMonths,
        startDate.day,
      );

      final response = await _supabase
          .from('subscriptions')
          .insert({
            'character_id': characterId,
            'subscription_type': type.name,
            'price_jpy': type.monthlyPrice * durationMonths,
            'start_date': startDate.toIso8601String(),
            'end_date': endDate.toIso8601String(),
            'auto_renew': autoRenew,
            'status': SubscriptionStatus.active.name,
          })
          .select()
          .single();

      return Subscription.fromJson(response);
    } catch (e) {
      print('Error creating subscription: $e');
      return null;
    }
  }

  /// Cancel subscription
  Future<bool> cancelSubscription(String subscriptionId) async {
    try {
      await _supabase
          .from('subscriptions')
          .update({
            'status': SubscriptionStatus.cancelled.name,
            'auto_renew': false,
          })
          .eq('id', subscriptionId);

      return true;
    } catch (e) {
      print('Error cancelling subscription: $e');
      return false;
    }
  }

  /// Renew subscription
  Future<Subscription?> renewSubscription(String subscriptionId, int durationMonths) async {
    try {
      // Get current subscription
      final current = await _supabase
          .from('subscriptions')
          .select()
          .eq('id', subscriptionId)
          .single();

      final currentSub = Subscription.fromJson(current);

      // Create new subscription starting from end of current one
      final startDate = currentSub.endDate;
      final endDate = DateTime(
        startDate.year,
        startDate.month + durationMonths,
        startDate.day,
      );

      final response = await _supabase
          .from('subscriptions')
          .insert({
            'character_id': currentSub.characterId,
            'subscription_type': currentSub.type.name,
            'price_jpy': currentSub.type.monthlyPrice * durationMonths,
            'start_date': startDate.toIso8601String(),
            'end_date': endDate.toIso8601String(),
            'auto_renew': currentSub.autoRenew,
            'status': SubscriptionStatus.active.name,
          })
          .select()
          .single();

      return Subscription.fromJson(response);
    } catch (e) {
      print('Error renewing subscription: $e');
      return null;
    }
  }

  /// Get subscription history
  Future<List<Subscription>> getSubscriptionHistory(String characterId) async {
    try {
      final response = await _supabase
          .from('subscriptions')
          .select()
          .eq('character_id', characterId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Subscription.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting subscription history: $e');
      return [];
    }
  }

  /// Check if character has specific subscription
  Future<bool> hasActiveSubscription(String characterId, SubscriptionType type) async {
    try {
      final response = await _supabase
          .from('subscriptions')
          .select()
          .eq('character_id', characterId)
          .eq('subscription_type', type.name)
          .eq('status', SubscriptionStatus.active.name)
          .gte('end_date', DateTime.now().toIso8601String())
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking subscription: $e');
      return false;
    }
  }

  /// Get expiring subscriptions (within 7 days)
  Future<List<Subscription>> getExpiringSubscriptions(String characterId) async {
    try {
      final sevenDaysFromNow = DateTime.now().add(const Duration(days: 7));
      
      final response = await _supabase
          .from('subscriptions')
          .select()
          .eq('character_id', characterId)
          .eq('status', SubscriptionStatus.active.name)
          .lte('end_date', sevenDaysFromNow.toIso8601String())
          .gte('end_date', DateTime.now().toIso8601String());

      return (response as List)
          .map((json) => Subscription.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting expiring subscriptions: $e');
      return [];
    }
  }

  /// Calculate total subscription cost
  Future<int> calculateTotalMonthlyCost(String characterId) async {
    try {
      final activeSubscriptions = await getActiveSubscriptions(characterId);
      return activeSubscriptions.fold<int>(0, (sum, sub) => sum + sub.type.monthlyPrice);
    } catch (e) {
      print('Error calculating total cost: $e');
      return 0;
    }
  }

  /// Process subscription auto-renewals (background task)
  Future<void> processAutoRenewals() async {
    try {
      // Get subscriptions expiring today with auto-renew enabled
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final expiringSubscriptions = await _supabase
          .from('subscriptions')
          .select()
          .eq('status', SubscriptionStatus.active.name)
          .eq('auto_renew', true)
          .like('end_date', '$todayStr%');

      for (final subJson in expiringSubscriptions) {
        final subscription = Subscription.fromJson(subJson);
        
        // Create renewed subscription
        await renewSubscription(subscription.id, 1); // Renew for 1 month
        
        // TODO: Process payment here
        print('Auto-renewed subscription ${subscription.id} for character ${subscription.characterId}');
      }
    } catch (e) {
      print('Error processing auto-renewals: $e');
    }
  }

  /// Update subscription status (for payment processing)
  Future<bool> updateSubscriptionStatus(String subscriptionId, SubscriptionStatus status) async {
    try {
      await _supabase
          .from('subscriptions')
          .update({'status': status.name})
          .eq('id', subscriptionId);

      return true;
    } catch (e) {
      print('Error updating subscription status: $e');
      return false;
    }
  }

  /// Get revenue analytics (admin function)
  Future<RevenueAnalytics> getRevenueAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      startDate ??= DateTime.now().subtract(const Duration(days: 30));
      endDate ??= DateTime.now();

      final response = await _supabase
          .rpc('get_revenue_analytics', params: {
            'start_date': startDate.toIso8601String(),
            'end_date': endDate.toIso8601String(),
          });

      return RevenueAnalytics.fromJson(response);
    } catch (e) {
      print('Error getting revenue analytics: $e');
      return RevenueAnalytics.empty();
    }
  }

  /// Stream subscription updates
  Stream<List<Subscription>> watchSubscriptions(String characterId) {
    return _supabase
        .from('subscriptions')
        .stream(primaryKey: ['id'])
        .eq('character_id', characterId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Subscription.fromJson(json)).toList());
  }

  /// Check premium features availability
  Future<PremiumFeatures> getPremiumFeatures(String characterId) async {
    final benefits = await getSubscriptionBenefits(characterId);
    
    return PremiumFeatures(
      adsRemoved: benefits.isAdsRemoved,
      detailedStats: benefits.hasDetailedStats,
      crystalBonus: benefits.totalCrystalBonus,
      canCreateFixedGuild: benefits.canCreateFixedGuild,
      eventPriority: benefits.hasEventPriority,
      apiAccess: benefits.hasApiAccess,
      backupEnabled: benefits.hasBasic,
      customQuests: benefits.hasGuild || benefits.hasEnterprise,
      premiumSkins: benefits.hasGuild || benefits.hasBattlePass,
      exclusiveCharacters: benefits.hasBattlePass,
      teamManagement: benefits.hasEnterprise,
    );
  }
}

class RevenueAnalytics {
  final int totalRevenue;
  final int totalSubscriptions;
  final Map<String, int> revenueByType;
  final Map<String, int> subscriptionsByType;
  final int newSubscriptions;
  final int cancelledSubscriptions;
  final double churnRate;

  RevenueAnalytics({
    required this.totalRevenue,
    required this.totalSubscriptions,
    required this.revenueByType,
    required this.subscriptionsByType,
    required this.newSubscriptions,
    required this.cancelledSubscriptions,
    required this.churnRate,
  });

  factory RevenueAnalytics.fromJson(Map<String, dynamic> json) {
    return RevenueAnalytics(
      totalRevenue: json['total_revenue'] ?? 0,
      totalSubscriptions: json['total_subscriptions'] ?? 0,
      revenueByType: Map<String, int>.from(json['revenue_by_type'] ?? {}),
      subscriptionsByType: Map<String, int>.from(json['subscriptions_by_type'] ?? {}),
      newSubscriptions: json['new_subscriptions'] ?? 0,
      cancelledSubscriptions: json['cancelled_subscriptions'] ?? 0,
      churnRate: (json['churn_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory RevenueAnalytics.empty() {
    return RevenueAnalytics(
      totalRevenue: 0,
      totalSubscriptions: 0,
      revenueByType: {},
      subscriptionsByType: {},
      newSubscriptions: 0,
      cancelledSubscriptions: 0,
      churnRate: 0.0,
    );
  }

  String get totalRevenueDisplay => '¥${totalRevenue.toStringAsFixed(0)}';
  String get churnRateDisplay => '${(churnRate * 100).toStringAsFixed(1)}%';
}

class PremiumFeatures {
  final bool adsRemoved;
  final bool detailedStats;
  final double crystalBonus;
  final bool canCreateFixedGuild;
  final bool eventPriority;
  final bool apiAccess;
  final bool backupEnabled;
  final bool customQuests;
  final bool premiumSkins;
  final bool exclusiveCharacters;
  final bool teamManagement;

  PremiumFeatures({
    required this.adsRemoved,
    required this.detailedStats,
    required this.crystalBonus,
    required this.canCreateFixedGuild,
    required this.eventPriority,
    required this.apiAccess,
    required this.backupEnabled,
    required this.customQuests,
    required this.premiumSkins,
    required this.exclusiveCharacters,
    required this.teamManagement,
  });

  List<String> get enabledFeatures {
    final features = <String>[];
    if (adsRemoved) features.add('広告削除');
    if (detailedStats) features.add('詳細統計');
    if (crystalBonus > 0) features.add('結晶変換率UP (${(crystalBonus * 100).round()}%)');
    if (canCreateFixedGuild) features.add('固定ギルド作成');
    if (eventPriority) features.add('イベント優先参加');
    if (apiAccess) features.add('API アクセス');
    if (backupEnabled) features.add('バックアップ機能');
    if (customQuests) features.add('カスタムクエスト');
    if (premiumSkins) features.add('プレミアムスキン');
    if (exclusiveCharacters) features.add('限定キャラ');
    if (teamManagement) features.add('チーム管理');
    return features;
  }

  bool get hasPremiumFeatures => 
      adsRemoved || detailedStats || crystalBonus > 0 || canCreateFixedGuild ||
      eventPriority || apiAccess || backupEnabled || customQuests ||
      premiumSkins || exclusiveCharacters || teamManagement;
}
