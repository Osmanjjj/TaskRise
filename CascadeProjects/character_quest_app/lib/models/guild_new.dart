import 'package:json_annotation/json_annotation.dart';

part 'guild_new.g.dart';

enum GuildRole {
  @JsonValue('member')
  member,
  @JsonValue('officer')
  officer,
  @JsonValue('leader')
  leader,
}

enum QuestStatus {
  @JsonValue('active')
  active,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
  @JsonValue('expired')
  expired,
}

extension GuildRoleExtension on GuildRole {
  String get displayName {
    switch (this) {
      case GuildRole.member:
        return 'メンバー';
      case GuildRole.officer:
        return '幹部';
      case GuildRole.leader:
        return 'リーダー';
    }
  }

  bool get canInvite {
    return this == GuildRole.leader || this == GuildRole.officer;
  }

  bool get canKick {
    return this == GuildRole.leader || this == GuildRole.officer;
  }

  bool get canManageQuests {
    return this == GuildRole.leader || this == GuildRole.officer;
  }
}

@JsonSerializable()
class Guild {
  final String id;
  final String name;
  final String description;
  final String leaderId;
  final int maxMembers;
  final int currentMembers;
  final int minLevel;
  final bool isPublic;
  final String? joinPassword;
  
  // Guild stats
  final int totalPoints;
  final int weeklyPoints;
  final int guildRank;
  
  // Settings
  final bool chatEnabled;
  final bool questEnabled;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  const Guild({
    required this.id,
    required this.name,
    required this.description,
    required this.leaderId,
    this.maxMembers = 30,
    this.currentMembers = 0,
    this.minLevel = 1,
    this.isPublic = true,
    this.joinPassword,
    this.totalPoints = 0,
    this.weeklyPoints = 0,
    this.guildRank = 0,
    this.chatEnabled = true,
    this.questEnabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Guild.fromJson(Map<String, dynamic> json) => _$GuildFromJson(json);
  Map<String, dynamic> toJson() => _$GuildToJson(this);

  bool get isFull => currentMembers >= maxMembers;
  bool get hasPassword => joinPassword != null && joinPassword!.isNotEmpty;
  double get activityRate => currentMembers > 0 ? weeklyPoints / currentMembers : 0.0;

  Guild copyWith({
    String? name,
    String? description,
    String? leaderId,
    int? maxMembers,
    int? currentMembers,
    int? minLevel,
    bool? isPublic,
    String? joinPassword,
    int? totalPoints,
    int? weeklyPoints,
    int? guildRank,
    bool? chatEnabled,
    bool? questEnabled,
  }) {
    return Guild(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      leaderId: leaderId ?? this.leaderId,
      maxMembers: maxMembers ?? this.maxMembers,
      currentMembers: currentMembers ?? this.currentMembers,
      minLevel: minLevel ?? this.minLevel,
      isPublic: isPublic ?? this.isPublic,
      joinPassword: joinPassword ?? this.joinPassword,
      totalPoints: totalPoints ?? this.totalPoints,
      weeklyPoints: weeklyPoints ?? this.weeklyPoints,
      guildRank: guildRank ?? this.guildRank,
      chatEnabled: chatEnabled ?? this.chatEnabled,
      questEnabled: questEnabled ?? this.questEnabled,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Guild(id: $id, name: $name, members: $currentMembers/$maxMembers, rank: $guildRank)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Guild && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

@JsonSerializable()
class GuildMember {
  final String id;
  final String guildId;
  final String userId;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final GuildRole role;
  final DateTime joinedAt;
  
  // Contribution stats
  final int weeklyContribution;
  final int totalContribution;
  final DateTime lastActiveAt;
  
  // Character info
  final int characterLevel;
  final int characterExperience;

  const GuildMember({
    required this.id,
    required this.guildId,
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.role = GuildRole.member,
    required this.joinedAt,
    this.weeklyContribution = 0,
    this.totalContribution = 0,
    required this.lastActiveAt,
    this.characterLevel = 1,
    this.characterExperience = 0,
  });

  factory GuildMember.fromJson(Map<String, dynamic> json) => _$GuildMemberFromJson(json);
  Map<String, dynamic> toJson() => _$GuildMemberToJson(this);

  String get displayNameOrUsername => displayName ?? username;
  bool get isOnline => DateTime.now().difference(lastActiveAt).inMinutes < 30;
  bool get isActive => DateTime.now().difference(lastActiveAt).inDays < 7;

  GuildMember copyWith({
    GuildRole? role,
    int? weeklyContribution,
    int? totalContribution,
    DateTime? lastActiveAt,
    int? characterLevel,
    int? characterExperience,
  }) {
    return GuildMember(
      id: id,
      guildId: guildId,
      userId: userId,
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
      role: role ?? this.role,
      joinedAt: joinedAt,
      weeklyContribution: weeklyContribution ?? this.weeklyContribution,
      totalContribution: totalContribution ?? this.totalContribution,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      characterLevel: characterLevel ?? this.characterLevel,
      characterExperience: characterExperience ?? this.characterExperience,
    );
  }

  @override
  String toString() {
    return 'GuildMember(id: $id, username: $username, role: $role)';
  }

  @override 
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GuildMember && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

@JsonSerializable()
class GuildQuest {
  final String id;
  final String guildId;
  final String title;
  final String description;
  
  // Quest requirements
  final String targetType; // 'habits_completed', 'total_points', etc.
  final int targetValue;
  final int currentProgress;
  
  // Duration
  final DateTime startDate;
  final DateTime endDate;
  final QuestStatus status;
  
  // Rewards
  final Map<String, dynamic>? rewards;
  final bool rewardsDistributed;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  const GuildQuest({
    required this.id,
    required this.guildId,
    required this.title,
    required this.description,
    required this.targetType,
    required this.targetValue,
    this.currentProgress = 0,
    required this.startDate,
    required this.endDate,
    this.status = QuestStatus.active,
    this.rewards,
    this.rewardsDistributed = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GuildQuest.fromJson(Map<String, dynamic> json) => _$GuildQuestFromJson(json);
  Map<String, dynamic> toJson() => _$GuildQuestToJson(this);

  double get progressPercentage => targetValue > 0 ? (currentProgress / targetValue).clamp(0.0, 1.0) : 0.0;
  bool get isCompleted => currentProgress >= targetValue;
  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isActive => status == QuestStatus.active && !isExpired;
  int get daysRemaining => isActive ? endDate.difference(DateTime.now()).inDays : 0;

  GuildQuest copyWith({
    String? title,
    String? description,
    int? targetValue,
    int? currentProgress,
    DateTime? startDate,
    DateTime? endDate,
    QuestStatus? status,
    Map<String, dynamic>? rewards,
    bool? rewardsDistributed,
  }) {
    return GuildQuest(
      id: id,
      guildId: guildId,
      title: title ?? this.title,
      description: description ?? this.description,
      targetType: targetType,
      targetValue: targetValue ?? this.targetValue,
      currentProgress: currentProgress ?? this.currentProgress,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      rewards: rewards ?? this.rewards,
      rewardsDistributed: rewardsDistributed ?? this.rewardsDistributed,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'GuildQuest(id: $id, title: $title, progress: $currentProgress/$targetValue)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GuildQuest && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
