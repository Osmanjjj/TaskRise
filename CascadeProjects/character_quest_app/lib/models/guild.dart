import 'package:json_annotation/json_annotation.dart';
import 'crystal.dart';

part 'guild.g.dart';

enum GuildRole {
  @JsonValue('member')
  member,
  @JsonValue('officer')
  officer,
  @JsonValue('leader')
  leader,
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

enum GuildType {
  @JsonValue('open')
  open,
  @JsonValue('closed')
  closed,
  @JsonValue('invite_only')
  inviteOnly,
}

extension GuildTypeExtension on GuildType {
  String get displayName {
    switch (this) {
      case GuildType.open:
        return 'オープン';
      case GuildType.closed:
        return 'クローズド';
      case GuildType.inviteOnly:
        return '招待制';
    }
  }
}

@JsonSerializable()
class Guild {
  final String id;
  final String name;
  final String description;
  final GuildType type;
  final String leaderId;
  final int maxMembers;
  final int currentMembers;
  final int minLevel;
  final bool isPublic;
  final String? joinPassword;
  final String? imageUrl;
  final bool isActive;
  final int weeklyGoal;
  final int currentProgress;
  final DateTime createdAt;
  final DateTime updatedAt;

  Guild({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.leaderId,
    required this.maxMembers,
    required this.currentMembers,
    this.minLevel = 1,
    this.isPublic = true,
    this.joinPassword,
    this.imageUrl,
    this.isActive = true,
    this.weeklyGoal = 100,
    this.currentProgress = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Guild.fromJson(Map<String, dynamic> json) => _$GuildFromJson(json);
  Map<String, dynamic> toJson() => _$GuildToJson(this);

  double get progressPercentage => weeklyGoal > 0 ? currentProgress / weeklyGoal : 0.0;
  
  bool get isFull => currentMembers >= maxMembers;
  
  bool get hasSpace => currentMembers < maxMembers;
  
  bool get isWeeklyGoalComplete => currentProgress >= weeklyGoal;

  Guild copyWith({
    String? id,
    String? name,
    String? description,
    GuildType? type,
    String? leaderId,
    int? maxMembers,
    int? currentMembers,
    int? minLevel,
    bool? isPublic,
    String? joinPassword,
    String? imageUrl,
    bool? isActive,
    int? weeklyGoal,
    int? currentProgress,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Guild(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      leaderId: leaderId ?? this.leaderId,
      maxMembers: maxMembers ?? this.maxMembers,
      currentMembers: currentMembers ?? this.currentMembers,
      minLevel: minLevel ?? this.minLevel,
      isPublic: isPublic ?? this.isPublic,
      joinPassword: joinPassword ?? this.joinPassword,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
      currentProgress: currentProgress ?? this.currentProgress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class GuildMembership {
  final String id;
  final String guildId;
  final String characterId;
  final GuildRole role;
  final int contributionPoints;
  final DateTime joinedAt;

  GuildMembership({
    required this.id,
    required this.guildId,
    required this.characterId,
    required this.role,
    required this.contributionPoints,
    required this.joinedAt,
  });

  factory GuildMembership.fromJson(Map<String, dynamic> json) {
    return GuildMembership(
      id: json['id'],
      guildId: json['guild_id'],
      characterId: json['character_id'],
      role: GuildRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => GuildRole.member,
      ),
      contributionPoints: json['contribution_points'] ?? 0,
      joinedAt: DateTime.parse(json['joined_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'guild_id': guildId,
      'character_id': characterId,
      'role': role.name,
      'contribution_points': contributionPoints,
      'joined_at': joinedAt.toIso8601String(),
    };
  }
}

class GuildQuest {
  final String id;
  final String guildId;
  final String title;
  final String description;
  final String goalType;
  final int goalValue;
  final int currentProgress;
  final Map<CrystalType, int> rewardCrystals;
  final DateTime startDate;
  final DateTime endDate;
  final QuestStatus status;
  final DateTime createdAt;

  GuildQuest({
    required this.id,
    required this.guildId,
    required this.title,
    required this.description,
    required this.goalType,
    required this.goalValue,
    required this.currentProgress,
    required this.rewardCrystals,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
  });

  factory GuildQuest.fromJson(Map<String, dynamic> json) {
    final rewardCrystalsJson = json['reward_crystals'] as Map<String, dynamic>? ?? {};
    final rewardCrystals = <CrystalType, int>{};
    
    for (final type in CrystalType.values) {
      if (rewardCrystalsJson.containsKey(type.name)) {
        rewardCrystals[type] = rewardCrystalsJson[type.name] as int;
      }
    }

    return GuildQuest(
      id: json['id'],
      guildId: json['guild_id'],
      title: json['title'],
      description: json['description'] ?? '',
      goalType: json['goal_type'],
      goalValue: json['goal_value'],
      currentProgress: json['current_progress'] ?? 0,
      rewardCrystals: rewardCrystals,
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      status: QuestStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => QuestStatus.active,
      ),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    final rewardCrystalsJson = <String, int>{};
    rewardCrystals.forEach((type, count) {
      rewardCrystalsJson[type.name] = count;
    });

    return {
      'id': id,
      'guild_id': guildId,
      'title': title,
      'description': description,
      'goal_type': goalType,
      'goal_value': goalValue,
      'current_progress': currentProgress,
      'reward_crystals': rewardCrystalsJson,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  double get progressPercentage => goalValue > 0 ? currentProgress / goalValue : 0.0;
  
  bool get isActive => status == QuestStatus.active && 
                     DateTime.now().isBefore(endDate) && 
                     DateTime.now().isAfter(startDate);

  bool get isComplete => status == QuestStatus.completed || currentProgress >= goalValue;

  Duration get timeRemaining => endDate.difference(DateTime.now());
  
  // Legacy rewards getter for compatibility
  Map<String, dynamic> get rewards => {
    'experience': 100,
    'contribution_points': 50,
    'crystals': rewardCrystals,
  };
}

enum QuestStatus {
  active,
  completed,
  failed;
}
