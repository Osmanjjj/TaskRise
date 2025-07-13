import 'package:json_annotation/json_annotation.dart';

part 'subscription.g.dart';

@JsonSerializable()
class Subscription {
  final String id;
  final String characterId;
  final SubscriptionType type;
  final int priceJpy;
  final DateTime startDate;
  final DateTime endDate;
  final bool autoRenew;
  final SubscriptionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Subscription({
    required this.id,
    required this.characterId,
    required this.type,
    required this.priceJpy,
    required this.startDate,
    required this.endDate,
    this.autoRenew = true,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) => _$SubscriptionFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionToJson(this);

  bool get isActive => status == SubscriptionStatus.active && DateTime.now().isBefore(endDate);
  
  bool get isExpired => DateTime.now().isAfter(endDate);
  
  bool get isExpiringSoon {
    final daysUntilExpiry = endDate.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 7 && daysUntilExpiry >= 0;
  }

  Duration get timeRemaining => isActive ? endDate.difference(DateTime.now()) : Duration.zero;
  
  int get daysRemaining => timeRemaining.inDays;

  String get displayName => type.displayName;
  
  String get priceDisplay => '¥${priceJpy.toStringAsFixed(0)}';

  Subscription copyWith({
    String? id,
    String? characterId,
    SubscriptionType? type,
    int? priceJpy,
    DateTime? startDate,
    DateTime? endDate,
    bool? autoRenew,
    SubscriptionStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subscription(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      type: type ?? this.type,
      priceJpy: priceJpy ?? this.priceJpy,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      autoRenew: autoRenew ?? this.autoRenew,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum SubscriptionType {
  basic(
    name: 'basic',
    displayName: 'ベーシックプレミアム',
    monthlyPrice: 500,
    features: [
      '広告削除',
      '詳細統計',
      '結晶変換率UP（120%）',
      'バックアップ機能',
    ],
    crystalConversionBonus: 0.2,
  ),
  guild(
    name: 'guild',
    displayName: 'ギルドプレミアム',
    monthlyPrice: 300,
    features: [
      '固定ギルド作成',
      'カスタムクエスト',
      'ギルド専用スキン',
      'メンバー管理機能',
    ],
    crystalConversionBonus: 0.0,
  ),
  battlePass(
    name: 'battle_pass',
    displayName: 'バトルパス',
    monthlyPrice: 800,
    features: [
      '限定キャラ確定',
      '特別なスキル',
      'イベント優先参加',
      'レイドボス追加報酬',
      '結晶変換率UP（150%）',
    ],
    crystalConversionBonus: 0.5,
  ),
  enterprise(
    name: 'enterprise',
    displayName: '企業プラン',
    monthlyPrice: 1000,
    features: [
      '社内ギルド機能',
      '健康データ分析',
      'カスタムレイドボス',
      'チーム統計ダッシュボード',
      '管理者ツール',
      'API アクセス',
    ],
    crystalConversionBonus: 0.3,
  );

  const SubscriptionType({
    required this.name,
    required this.displayName,
    required this.monthlyPrice,
    required this.features,
    required this.crystalConversionBonus,
  });

  final String name;
  final String displayName;
  final int monthlyPrice;
  final List<String> features;
  final double crystalConversionBonus; // Percentage bonus (0.2 = 20% bonus)

  String get priceDisplay => '¥${monthlyPrice.toStringAsFixed(0)}/月';
  
  bool get isPopular => this == SubscriptionType.basic;
  
  bool get isBestValue => this == SubscriptionType.battlePass;
}

enum SubscriptionStatus {
  active(name: 'active', displayName: 'アクティブ', color: 0xFF4CAF50),
  cancelled(name: 'cancelled', displayName: 'キャンセル済み', color: 0xFFFF9800),
  expired(name: 'expired', displayName: '期限切れ', color: 0xFFF44336);

  const SubscriptionStatus({
    required this.name,
    required this.displayName,
    required this.color,
  });

  final String name;
  final String displayName;
  final int color;
}

class SubscriptionBenefits {
  final List<SubscriptionType> activeSubscriptions;
  final DateTime? lastUpdated;

  SubscriptionBenefits({
    required this.activeSubscriptions,
    this.lastUpdated,
  });

  bool hasSubscription(SubscriptionType type) => activeSubscriptions.contains(type);
  
  bool get hasAnySubscription => activeSubscriptions.isNotEmpty;
  
  bool get isPremium => hasAnySubscription;
  
  bool get hasBasic => hasSubscription(SubscriptionType.basic);
  
  bool get hasGuild => hasSubscription(SubscriptionType.guild);
  
  bool get hasBattlePass => hasSubscription(SubscriptionType.battlePass);
  
  bool get hasEnterprise => hasSubscription(SubscriptionType.enterprise);

  double get totalCrystalBonus {
    double bonus = 0.0;
    for (final sub in activeSubscriptions) {
      bonus += sub.crystalConversionBonus;
    }
    return bonus;
  }

  int get totalMonthlyPrice {
    return activeSubscriptions.fold(0, (sum, sub) => sum + sub.monthlyPrice);
  }

  List<String> get allFeatures {
    final features = <String>[];
    for (final sub in activeSubscriptions) {
      features.addAll(sub.features);
    }
    return features.toSet().toList(); // Remove duplicates
  }

  bool get isAdsRemoved => hasBasic || hasBattlePass;
  
  bool get canCreateFixedGuild => hasGuild || hasEnterprise;
  
  bool get hasDetailedStats => hasBasic || hasBattlePass || hasEnterprise;
  
  bool get hasEventPriority => hasBattlePass;
  
  bool get hasApiAccess => hasEnterprise;

  String get statusDisplay {
    if (activeSubscriptions.isEmpty) return '無料プラン';
    if (activeSubscriptions.length == 1) return activeSubscriptions.first.displayName;
    return '複数のプラン（${activeSubscriptions.length}個）';
  }
}
