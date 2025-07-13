// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'raid.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RaidBoss _$RaidBossFromJson(Map<String, dynamic> json) => RaidBoss(
  id: json['id'] as String,
  eventId: json['eventId'] as String,
  name: json['name'] as String,
  type: $enumDecodeNullable(_$BossTypeEnumMap, json['type']) ?? BossType.normal,
  difficulty:
      $enumDecodeNullable(_$BossDifficultyEnumMap, json['difficulty']) ??
      BossDifficulty.normal,
  maxHealth: (json['maxHealth'] as num).toInt(),
  currentHealth: (json['currentHealth'] as num).toInt(),
  defense: (json['defense'] as num?)?.toInt() ?? 0,
  specialAbilities: json['specialAbilities'] as Map<String, dynamic>?,
  weaknessTypes: json['weaknessTypes'] as Map<String, dynamic>?,
  rewards: json['rewards'] as Map<String, dynamic>?,
  endTime: json['endTime'] == null
      ? null
      : DateTime.parse(json['endTime'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$RaidBossToJson(RaidBoss instance) => <String, dynamic>{
  'id': instance.id,
  'eventId': instance.eventId,
  'name': instance.name,
  'type': _$BossTypeEnumMap[instance.type]!,
  'difficulty': _$BossDifficultyEnumMap[instance.difficulty]!,
  'maxHealth': instance.maxHealth,
  'currentHealth': instance.currentHealth,
  'defense': instance.defense,
  'specialAbilities': instance.specialAbilities,
  'weaknessTypes': instance.weaknessTypes,
  'rewards': instance.rewards,
  'endTime': instance.endTime?.toIso8601String(),
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

const _$BossTypeEnumMap = {
  BossType.normal: 'normal',
  BossType.elite: 'elite',
  BossType.legendary: 'legendary',
};

const _$BossDifficultyEnumMap = {
  BossDifficulty.easy: 'easy',
  BossDifficulty.normal: 'normal',
  BossDifficulty.hard: 'hard',
  BossDifficulty.extreme: 'extreme',
};

RaidParticipation _$RaidParticipationFromJson(Map<String, dynamic> json) =>
    RaidParticipation(
      id: json['id'] as String,
      raidBossId: json['raidBossId'] as String,
      userId: json['userId'] as String,
      characterId: json['characterId'] as String,
      damageDealt: (json['damageDealt'] as num?)?.toInt() ?? 0,
      battlePointsSpent: (json['battlePointsSpent'] as num?)?.toInt() ?? 0,
      attacksCount: (json['attacksCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$RaidParticipationToJson(RaidParticipation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'raidBossId': instance.raidBossId,
      'userId': instance.userId,
      'characterId': instance.characterId,
      'damageDealt': instance.damageDealt,
      'battlePointsSpent': instance.battlePointsSpent,
      'attacksCount': instance.attacksCount,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
