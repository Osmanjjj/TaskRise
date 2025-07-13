class DailyStats {
  final String id;
  final String characterId;
  final DateTime date;
  final int habitsCompleted;
  final int battlePointsEarned;
  final int staminaGenerated;
  final int experienceGained;
  final int crystalsEarned;
  final int longestChain;
  final bool raidParticipated;
  final bool guildQuestParticipated;
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyStats({
    required this.id,
    required this.characterId,
    required this.date,
    required this.habitsCompleted,
    required this.battlePointsEarned,
    required this.staminaGenerated,
    required this.experienceGained,
    required this.crystalsEarned,
    required this.longestChain,
    required this.raidParticipated,
    required this.guildQuestParticipated,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyStats.fromJson(Map<String, dynamic> json) {
    return DailyStats(
      id: json['id'],
      characterId: json['character_id'],
      date: DateTime.parse(json['date']),
      habitsCompleted: json['habits_completed'] ?? 0,
      battlePointsEarned: json['battle_points_earned'] ?? 0,
      staminaGenerated: json['stamina_generated'] ?? 0,
      experienceGained: json['experience_gained'] ?? 0,
      crystalsEarned: json['crystals_earned'] ?? 0,
      longestChain: json['longest_chain'] ?? 0,
      raidParticipated: json['raid_participated'] ?? false,
      guildQuestParticipated: json['guild_quest_participated'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'character_id': characterId,
      'date': date.toIso8601String(),
      'habits_completed': habitsCompleted,
      'battle_points_earned': battlePointsEarned,
      'stamina_generated': staminaGenerated,
      'experience_gained': experienceGained,
      'crystals_earned': crystalsEarned,
      'longest_chain': longestChain,
      'raid_participated': raidParticipated,
      'guild_quest_participated': guildQuestParticipated,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  DailyStats copyWith({
    String? id,
    String? characterId,
    DateTime? date,
    int? habitsCompleted,
    int? battlePointsEarned,
    int? staminaGenerated,
    int? experienceGained,
    int? crystalsEarned,
    int? longestChain,
    bool? raidParticipated,
    bool? guildQuestParticipated,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyStats(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      date: date ?? this.date,
      habitsCompleted: habitsCompleted ?? this.habitsCompleted,
      battlePointsEarned: battlePointsEarned ?? this.battlePointsEarned,
      staminaGenerated: staminaGenerated ?? this.staminaGenerated,
      experienceGained: experienceGained ?? this.experienceGained,
      crystalsEarned: crystalsEarned ?? this.crystalsEarned,
      longestChain: longestChain ?? this.longestChain,
      raidParticipated: raidParticipated ?? this.raidParticipated,
      guildQuestParticipated: guildQuestParticipated ?? this.guildQuestParticipated,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get completionRate {
    final totalActivities = habitsCompleted + (raidParticipated ? 1 : 0) + (guildQuestParticipated ? 1 : 0);
    return totalActivities > 0 ? totalActivities / 10.0 : 0.0; // Assuming 10 activities is the target
  }

  int get totalRewards => battlePointsEarned + staminaGenerated + experienceGained + crystalsEarned;

  bool get isActiveDay => habitsCompleted > 0 || raidParticipated || guildQuestParticipated;
}