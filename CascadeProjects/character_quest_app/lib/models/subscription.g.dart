// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Subscription _$SubscriptionFromJson(Map<String, dynamic> json) => Subscription(
  id: json['id'] as String,
  characterId: json['characterId'] as String,
  type: $enumDecode(_$SubscriptionTypeEnumMap, json['type']),
  priceJpy: (json['priceJpy'] as num).toInt(),
  startDate: DateTime.parse(json['startDate'] as String),
  endDate: DateTime.parse(json['endDate'] as String),
  autoRenew: json['autoRenew'] as bool? ?? true,
  status: $enumDecode(_$SubscriptionStatusEnumMap, json['status']),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$SubscriptionToJson(Subscription instance) =>
    <String, dynamic>{
      'id': instance.id,
      'characterId': instance.characterId,
      'type': _$SubscriptionTypeEnumMap[instance.type]!,
      'priceJpy': instance.priceJpy,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'autoRenew': instance.autoRenew,
      'status': _$SubscriptionStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$SubscriptionTypeEnumMap = {
  SubscriptionType.basic: 'basic',
  SubscriptionType.guild: 'guild',
  SubscriptionType.battlePass: 'battlePass',
  SubscriptionType.enterprise: 'enterprise',
};

const _$SubscriptionStatusEnumMap = {
  SubscriptionStatus.active: 'active',
  SubscriptionStatus.cancelled: 'cancelled',
  SubscriptionStatus.expired: 'expired',
};
