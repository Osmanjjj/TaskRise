// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guild.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Guild _$GuildFromJson(Map<String, dynamic> json) => Guild(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  type: $enumDecode(_$GuildTypeEnumMap, json['type']),
  leaderId: json['leaderId'] as String,
  maxMembers: (json['maxMembers'] as num).toInt(),
  currentMembers: (json['currentMembers'] as num).toInt(),
  minLevel: (json['minLevel'] as num?)?.toInt() ?? 1,
  isPublic: json['isPublic'] as bool? ?? true,
  joinPassword: json['joinPassword'] as String?,
  imageUrl: json['imageUrl'] as String?,
  isActive: json['isActive'] as bool? ?? true,
  weeklyGoal: (json['weeklyGoal'] as num?)?.toInt() ?? 100,
  currentProgress: (json['currentProgress'] as num?)?.toInt() ?? 0,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$GuildToJson(Guild instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'type': _$GuildTypeEnumMap[instance.type]!,
  'leaderId': instance.leaderId,
  'maxMembers': instance.maxMembers,
  'currentMembers': instance.currentMembers,
  'minLevel': instance.minLevel,
  'isPublic': instance.isPublic,
  'joinPassword': instance.joinPassword,
  'imageUrl': instance.imageUrl,
  'isActive': instance.isActive,
  'weeklyGoal': instance.weeklyGoal,
  'currentProgress': instance.currentProgress,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

const _$GuildTypeEnumMap = {
  GuildType.open: 'open',
  GuildType.closed: 'closed',
  GuildType.inviteOnly: 'invite_only',
};
