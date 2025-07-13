// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guild_new.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Guild _$GuildFromJson(Map<String, dynamic> json) => Guild(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  leaderId: json['leaderId'] as String,
  maxMembers: (json['maxMembers'] as num?)?.toInt() ?? 30,
  currentMembers: (json['currentMembers'] as num?)?.toInt() ?? 0,
  minLevel: (json['minLevel'] as num?)?.toInt() ?? 1,
  isPublic: json['isPublic'] as bool? ?? true,
  joinPassword: json['joinPassword'] as String?,
  totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
  weeklyPoints: (json['weeklyPoints'] as num?)?.toInt() ?? 0,
  guildRank: (json['guildRank'] as num?)?.toInt() ?? 0,
  chatEnabled: json['chatEnabled'] as bool? ?? true,
  questEnabled: json['questEnabled'] as bool? ?? true,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$GuildToJson(Guild instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'leaderId': instance.leaderId,
  'maxMembers': instance.maxMembers,
  'currentMembers': instance.currentMembers,
  'minLevel': instance.minLevel,
  'isPublic': instance.isPublic,
  'joinPassword': instance.joinPassword,
  'totalPoints': instance.totalPoints,
  'weeklyPoints': instance.weeklyPoints,
  'guildRank': instance.guildRank,
  'chatEnabled': instance.chatEnabled,
  'questEnabled': instance.questEnabled,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

GuildMember _$GuildMemberFromJson(Map<String, dynamic> json) => GuildMember(
  id: json['id'] as String,
  guildId: json['guildId'] as String,
  userId: json['userId'] as String,
  username: json['username'] as String,
  displayName: json['displayName'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
  role:
      $enumDecodeNullable(_$GuildRoleEnumMap, json['role']) ?? GuildRole.member,
  joinedAt: DateTime.parse(json['joinedAt'] as String),
  weeklyContribution: (json['weeklyContribution'] as num?)?.toInt() ?? 0,
  totalContribution: (json['totalContribution'] as num?)?.toInt() ?? 0,
  lastActiveAt: DateTime.parse(json['lastActiveAt'] as String),
  characterLevel: (json['characterLevel'] as num?)?.toInt() ?? 1,
  characterExperience: (json['characterExperience'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$GuildMemberToJson(GuildMember instance) =>
    <String, dynamic>{
      'id': instance.id,
      'guildId': instance.guildId,
      'userId': instance.userId,
      'username': instance.username,
      'displayName': instance.displayName,
      'avatarUrl': instance.avatarUrl,
      'role': _$GuildRoleEnumMap[instance.role]!,
      'joinedAt': instance.joinedAt.toIso8601String(),
      'weeklyContribution': instance.weeklyContribution,
      'totalContribution': instance.totalContribution,
      'lastActiveAt': instance.lastActiveAt.toIso8601String(),
      'characterLevel': instance.characterLevel,
      'characterExperience': instance.characterExperience,
    };

const _$GuildRoleEnumMap = {
  GuildRole.member: 'member',
  GuildRole.officer: 'officer',
  GuildRole.leader: 'leader',
};

GuildQuest _$GuildQuestFromJson(Map<String, dynamic> json) => GuildQuest(
  id: json['id'] as String,
  guildId: json['guildId'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  targetType: json['targetType'] as String,
  targetValue: (json['targetValue'] as num).toInt(),
  currentProgress: (json['currentProgress'] as num?)?.toInt() ?? 0,
  startDate: DateTime.parse(json['startDate'] as String),
  endDate: DateTime.parse(json['endDate'] as String),
  status:
      $enumDecodeNullable(_$QuestStatusEnumMap, json['status']) ??
      QuestStatus.active,
  rewards: json['rewards'] as Map<String, dynamic>?,
  rewardsDistributed: json['rewardsDistributed'] as bool? ?? false,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$GuildQuestToJson(GuildQuest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'guildId': instance.guildId,
      'title': instance.title,
      'description': instance.description,
      'targetType': instance.targetType,
      'targetValue': instance.targetValue,
      'currentProgress': instance.currentProgress,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'status': _$QuestStatusEnumMap[instance.status]!,
      'rewards': instance.rewards,
      'rewardsDistributed': instance.rewardsDistributed,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$QuestStatusEnumMap = {
  QuestStatus.active: 'active',
  QuestStatus.completed: 'completed',
  QuestStatus.failed: 'failed',
  QuestStatus.expired: 'expired',
};
