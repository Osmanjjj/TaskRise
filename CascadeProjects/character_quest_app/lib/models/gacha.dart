import 'package:json_annotation/json_annotation.dart';

part 'gacha.g.dart';

enum GachaType {
  @JsonValue('standard')
  standard,
  @JsonValue('premium')
  premium,
  @JsonValue('limited')
  limited,
  @JsonValue('event')
  event,
}

enum GachaItemType {
  @JsonValue('character')
  character,
  @JsonValue('equipment')
  equipment,
  @JsonValue('crystal')
  crystal,
  @JsonValue('consumable')
  consumable,
}

enum Rarity {
  @JsonValue('common')
  common,
  @JsonValue('rare')
  rare,
  @JsonValue('epic')
  epic,
  @JsonValue('legendary')
  legendary,
  @JsonValue('mythic')
  mythic,
}

extension GachaTypeExtension on GachaType {
  String get displayName {
    switch (this) {
      case GachaType.standard:
        return 'スタンダードガチャ';
      case GachaType.premium:
        return 'プレミアムガチャ';
      case GachaType.limited:
        return '限定ガチャ';
      case GachaType.event:
        return 'イベントガチャ';
    }
  }

  String get description {
    switch (this) {
      case GachaType.standard:
        return '基本的なアイテムが出現するガチャです';
      case GachaType.premium:
        return 'レアアイテムの出現率が高いガチャです';
      case GachaType.limited:
        return '期間限定アイテムが出現するガチャです';
      case GachaType.event:
        return 'イベント限定アイテムが出現するガチャです';
    }
  }

  int get baseCost {
    switch (this) {
      case GachaType.standard:
        return 100;
      case GachaType.premium:
        return 300;
      case GachaType.limited:
        return 500;
      case GachaType.event:
        return 200;
    }
  }
}

extension RarityExtension on Rarity {
  String get displayName {
    switch (this) {
      case Rarity.common:
        return 'コモン';
      case Rarity.rare:
        return 'レア';
      case Rarity.epic:
        return 'エピック';
      case Rarity.legendary:
        return 'レジェンダリー';
      case Rarity.mythic:
        return 'ミシック';
    }
  }

  String get color {
    switch (this) {
      case Rarity.common:
        return '#9E9E9E';
      case Rarity.rare:
        return '#2196F3';
      case Rarity.epic:
        return '#9C27B0';
      case Rarity.legendary:
        return '#FF9800';
      case Rarity.mythic:
        return '#F44336';
    }
  }

  int get stars {
    switch (this) {
      case Rarity.common:
        return 1;
      case Rarity.rare:
        return 2;
      case Rarity.epic:
        return 3;
      case Rarity.legendary:
        return 4;
      case Rarity.mythic:
        return 5;
    }
  }

  double get baseDropRate {
    switch (this) {
      case Rarity.common:
        return 0.60; // 60%
      case Rarity.rare:
        return 0.25; // 25%
      case Rarity.epic:
        return 0.10; // 10%
      case Rarity.legendary:
        return 0.04; // 4%
      case Rarity.mythic:
        return 0.01; // 1%
    }
  }
}

@JsonSerializable()
class GachaBanner {
  final String id;
  final String name;
  final String description;
  final GachaType type;
  final int crystalCost;
  final bool isActive;
  final DateTime? startTime;
  final DateTime? endTime;
  
  // Gacha rates
  final Map<String, double> rarityRates;
  final List<String> featuredItemIds;
  
  // Banner appearance
  final String? bannerImageUrl;
  final String? iconUrl;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  const GachaBanner({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.crystalCost,
    this.isActive = true,
    this.startTime,
    this.endTime,
    required this.rarityRates,
    this.featuredItemIds = const [],
    this.bannerImageUrl,
    this.iconUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GachaBanner.fromJson(Map<String, dynamic> json) => _$GachaBannerFromJson(json);
  Map<String, dynamic> toJson() => _$GachaBannerToJson(this);

  bool get isLimited => startTime != null && endTime != null;
  bool get isExpired => endTime != null && DateTime.now().isAfter(endTime!);
  bool get isUpcoming => startTime != null && DateTime.now().isBefore(startTime!);
  bool get isCurrentlyActive => isActive && !isExpired && !isUpcoming;
  
  Duration? get timeRemaining {
    if (endTime == null) return null;
    final now = DateTime.now();
    if (now.isAfter(endTime!)) return Duration.zero;
    return endTime!.difference(now);
  }

  Duration? get timeUntilStart {
    if (startTime == null) return null;
    final now = DateTime.now();
    if (now.isAfter(startTime!)) return Duration.zero;
    return startTime!.difference(now);
  }

  GachaBanner copyWith({
    String? name,
    String? description,
    int? crystalCost,
    bool? isActive,
    DateTime? startTime,
    DateTime? endTime,
    Map<String, double>? rarityRates,
    List<String>? featuredItemIds,
    String? bannerImageUrl,
    String? iconUrl,
  }) {
    return GachaBanner(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type,
      crystalCost: crystalCost ?? this.crystalCost,
      isActive: isActive ?? this.isActive,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      rarityRates: rarityRates ?? this.rarityRates,
      featuredItemIds: featuredItemIds ?? this.featuredItemIds,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      iconUrl: iconUrl ?? this.iconUrl,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'GachaBanner(id: $id, name: $name, type: $type, cost: $crystalCost)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GachaBanner && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

@JsonSerializable()
class GachaItem {
  final String id;
  final String name;
  final String description;
  final GachaItemType itemType;
  final Rarity rarity;
  final String? iconUrl;
  final String? imageUrl;
  
  // Item stats/properties
  final Map<String, dynamic>? itemData;
  final bool isLimited;
  final DateTime? availableUntil;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  const GachaItem({
    required this.id,
    required this.name,
    required this.description,
    required this.itemType,
    required this.rarity,
    this.iconUrl,
    this.imageUrl,
    this.itemData,
    this.isLimited = false,
    this.availableUntil,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GachaItem.fromJson(Map<String, dynamic> json) => _$GachaItemFromJson(json);
  Map<String, dynamic> toJson() => _$GachaItemToJson(this);

  bool get isExpired => availableUntil != null && DateTime.now().isAfter(availableUntil!);
  bool get isAvailable => !isExpired;
  
  String get rarityDisplayName => rarity.displayName;
  String get rarityColor => rarity.color;
  int get rarityStars => rarity.stars;

  GachaItem copyWith({
    String? name,
    String? description,
    String? iconUrl,
    String? imageUrl,
    Map<String, dynamic>? itemData,
    bool? isLimited,
    DateTime? availableUntil,
  }) {
    return GachaItem(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      itemType: itemType,
      rarity: rarity,
      iconUrl: iconUrl ?? this.iconUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      itemData: itemData ?? this.itemData,
      isLimited: isLimited ?? this.isLimited,
      availableUntil: availableUntil ?? this.availableUntil,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'GachaItem(id: $id, name: $name, rarity: $rarity, type: $itemType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GachaItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

@JsonSerializable()
class GachaPull {
  final String id;
  final String userId;
  final String bannerId;
  final int crystalsSpent;
  final int pullCount;
  final List<String> itemIds;
  final Map<String, dynamic>? pullData;
  final DateTime createdAt;

  const GachaPull({
    required this.id,
    required this.userId,
    required this.bannerId,
    required this.crystalsSpent,
    this.pullCount = 1,
    required this.itemIds,
    this.pullData,
    required this.createdAt,
  });

  factory GachaPull.fromJson(Map<String, dynamic> json) => _$GachaPullFromJson(json);
  Map<String, dynamic> toJson() => _$GachaPullToJson(this);

  bool get isMultiPull => pullCount > 1;
  int get itemCount => itemIds.length;

  @override
  String toString() {
    return 'GachaPull(id: $id, userId: $userId, pulls: $pullCount, items: ${itemIds.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GachaPull && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

@JsonSerializable()
class UserGachaHistory {
  final String id;
  final String userId;
  final String bannerId;
  final int totalPulls;
  final int totalCrystalsSpent;
  final Map<String, int> rarityCount;
  final DateTime? lastPullAt;
  final int pityCounter;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserGachaHistory({
    required this.id,
    required this.userId,
    required this.bannerId,
    this.totalPulls = 0,
    this.totalCrystalsSpent = 0,
    this.rarityCount = const {},
    this.lastPullAt,
    this.pityCounter = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserGachaHistory.fromJson(Map<String, dynamic> json) => _$UserGachaHistoryFromJson(json);
  Map<String, dynamic> toJson() => _$UserGachaHistoryToJson(this);

  double get averageCostPerPull => totalPulls > 0 ? totalCrystalsSpent / totalPulls : 0.0;
  bool get hasRecentActivity => lastPullAt != null && DateTime.now().difference(lastPullAt!).inDays < 7;
  bool get isPityActive => pityCounter > 0;

  UserGachaHistory copyWith({
    int? totalPulls,
    int? totalCrystalsSpent,
    Map<String, int>? rarityCount,
    DateTime? lastPullAt,
    int? pityCounter,
  }) {
    return UserGachaHistory(
      id: id,
      userId: userId,
      bannerId: bannerId,
      totalPulls: totalPulls ?? this.totalPulls,
      totalCrystalsSpent: totalCrystalsSpent ?? this.totalCrystalsSpent,
      rarityCount: rarityCount ?? this.rarityCount,
      lastPullAt: lastPullAt ?? this.lastPullAt,
      pityCounter: pityCounter ?? this.pityCounter,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'UserGachaHistory(id: $id, userId: $userId, pulls: $totalPulls, pity: $pityCounter)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserGachaHistory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
