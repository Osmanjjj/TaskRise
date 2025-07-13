// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gacha.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GachaBanner _$GachaBannerFromJson(Map<String, dynamic> json) => GachaBanner(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  type: $enumDecode(_$GachaTypeEnumMap, json['type']),
  crystalCost: (json['crystalCost'] as num).toInt(),
  isActive: json['isActive'] as bool? ?? true,
  startTime: json['startTime'] == null
      ? null
      : DateTime.parse(json['startTime'] as String),
  endTime: json['endTime'] == null
      ? null
      : DateTime.parse(json['endTime'] as String),
  rarityRates: (json['rarityRates'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, (e as num).toDouble()),
  ),
  featuredItemIds:
      (json['featuredItemIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  bannerImageUrl: json['bannerImageUrl'] as String?,
  iconUrl: json['iconUrl'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$GachaBannerToJson(GachaBanner instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'type': _$GachaTypeEnumMap[instance.type]!,
      'crystalCost': instance.crystalCost,
      'isActive': instance.isActive,
      'startTime': instance.startTime?.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'rarityRates': instance.rarityRates,
      'featuredItemIds': instance.featuredItemIds,
      'bannerImageUrl': instance.bannerImageUrl,
      'iconUrl': instance.iconUrl,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$GachaTypeEnumMap = {
  GachaType.standard: 'standard',
  GachaType.premium: 'premium',
  GachaType.limited: 'limited',
  GachaType.event: 'event',
};

GachaItem _$GachaItemFromJson(Map<String, dynamic> json) => GachaItem(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  itemType: $enumDecode(_$GachaItemTypeEnumMap, json['itemType']),
  rarity: $enumDecode(_$RarityEnumMap, json['rarity']),
  iconUrl: json['iconUrl'] as String?,
  imageUrl: json['imageUrl'] as String?,
  itemData: json['itemData'] as Map<String, dynamic>?,
  isLimited: json['isLimited'] as bool? ?? false,
  availableUntil: json['availableUntil'] == null
      ? null
      : DateTime.parse(json['availableUntil'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$GachaItemToJson(GachaItem instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'itemType': _$GachaItemTypeEnumMap[instance.itemType]!,
  'rarity': _$RarityEnumMap[instance.rarity]!,
  'iconUrl': instance.iconUrl,
  'imageUrl': instance.imageUrl,
  'itemData': instance.itemData,
  'isLimited': instance.isLimited,
  'availableUntil': instance.availableUntil?.toIso8601String(),
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

const _$GachaItemTypeEnumMap = {
  GachaItemType.character: 'character',
  GachaItemType.equipment: 'equipment',
  GachaItemType.crystal: 'crystal',
  GachaItemType.consumable: 'consumable',
};

const _$RarityEnumMap = {
  Rarity.common: 'common',
  Rarity.rare: 'rare',
  Rarity.epic: 'epic',
  Rarity.legendary: 'legendary',
  Rarity.mythic: 'mythic',
};

GachaPull _$GachaPullFromJson(Map<String, dynamic> json) => GachaPull(
  id: json['id'] as String,
  userId: json['userId'] as String,
  bannerId: json['bannerId'] as String,
  crystalsSpent: (json['crystalsSpent'] as num).toInt(),
  pullCount: (json['pullCount'] as num?)?.toInt() ?? 1,
  itemIds: (json['itemIds'] as List<dynamic>).map((e) => e as String).toList(),
  pullData: json['pullData'] as Map<String, dynamic>?,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$GachaPullToJson(GachaPull instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'bannerId': instance.bannerId,
  'crystalsSpent': instance.crystalsSpent,
  'pullCount': instance.pullCount,
  'itemIds': instance.itemIds,
  'pullData': instance.pullData,
  'createdAt': instance.createdAt.toIso8601String(),
};

UserGachaHistory _$UserGachaHistoryFromJson(Map<String, dynamic> json) =>
    UserGachaHistory(
      id: json['id'] as String,
      userId: json['userId'] as String,
      bannerId: json['bannerId'] as String,
      totalPulls: (json['totalPulls'] as num?)?.toInt() ?? 0,
      totalCrystalsSpent: (json['totalCrystalsSpent'] as num?)?.toInt() ?? 0,
      rarityCount:
          (json['rarityCount'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {},
      lastPullAt: json['lastPullAt'] == null
          ? null
          : DateTime.parse(json['lastPullAt'] as String),
      pityCounter: (json['pityCounter'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$UserGachaHistoryToJson(UserGachaHistory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'bannerId': instance.bannerId,
      'totalPulls': instance.totalPulls,
      'totalCrystalsSpent': instance.totalCrystalsSpent,
      'rarityCount': instance.rarityCount,
      'lastPullAt': instance.lastPullAt?.toIso8601String(),
      'pityCounter': instance.pityCounter,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
