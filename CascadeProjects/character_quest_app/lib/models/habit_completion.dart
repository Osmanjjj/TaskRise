import 'crystal.dart' show CrystalReward;

class HabitCompletion {
  final String id;
  final String characterId;
  final String taskId;
  final DateTime completedAt;
  final int battlePointsEarned;
  final int staminaEarned;
  final int experienceEarned;
  final List<CrystalReward> crystalsEarned;
  final bool isChainBonus;
  final int chainLength;
  final double difficultyMultiplier;

  HabitCompletion({
    required this.id,
    required this.characterId,
    required this.taskId,
    required this.completedAt,
    required this.battlePointsEarned,
    required this.staminaEarned,
    required this.experienceEarned,
    required this.crystalsEarned,
    this.isChainBonus = false,
    this.chainLength = 1,
    this.difficultyMultiplier = 1.0,
  });

  factory HabitCompletion.fromJson(Map<String, dynamic> json) {
    return HabitCompletion(
      id: json['id'],
      characterId: json['character_id'],
      taskId: json['task_id'],
      completedAt: DateTime.parse(json['completed_at']),
      battlePointsEarned: json['battle_points_earned'] ?? 0,
      staminaEarned: json['stamina_earned'] ?? 0,
      experienceEarned: json['experience_earned'] ?? 0,
      crystalsEarned: json['crystals_earned'] != null
          ? (json['crystals_earned'] as List)
              .map((crystal) => CrystalReward.fromJson(crystal))
              .toList()
          : [],
      isChainBonus: json['is_chain_bonus'] ?? false,
      chainLength: json['chain_length'] ?? 1,
      difficultyMultiplier: (json['difficulty_multiplier'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'character_id': characterId,
      'task_id': taskId,
      'completed_at': completedAt.toIso8601String(),
      'battle_points_earned': battlePointsEarned,
      'stamina_earned': staminaEarned,
      'experience_earned': experienceEarned,
      'crystals_earned': crystalsEarned.map((c) => c.toJson()).toList(),
      'is_chain_bonus': isChainBonus,
      'chain_length': chainLength,
      'difficulty_multiplier': difficultyMultiplier,
    };
  }

  bool get isToday {
    final now = DateTime.now();
    return completedAt.year == now.year &&
           completedAt.month == now.month &&
           completedAt.day == now.day;
  }

  int get totalCrystalValue {
    return crystalsEarned.fold(0, (sum, crystal) => sum + (crystal.amount * crystal.type.value));
  }

  String get rewardsSummary {
    final parts = <String>[];
    if (experienceEarned > 0) parts.add('${experienceEarned}XP');
    if (battlePointsEarned > 0) parts.add('${battlePointsEarned}BP');
    if (staminaEarned > 0) parts.add('${staminaEarned}スタミナ');
    if (crystalsEarned.isNotEmpty) parts.add('結晶${crystalsEarned.length}個');
    return parts.join(' + ');
  }
}


class HabitChain {
  final String characterId;
  final String taskId;
  final int currentChain;
  final int longestChain;
  final DateTime lastCompletedDate;
  final List<DateTime> completionDates;

  HabitChain({
    required this.characterId,
    required this.taskId,
    required this.currentChain,
    required this.longestChain,
    required this.lastCompletedDate,
    required this.completionDates,
  });

  factory HabitChain.fromJson(Map<String, dynamic> json) {
    return HabitChain(
      characterId: json['character_id'],
      taskId: json['task_id'],
      currentChain: json['current_chain'] ?? 0,
      longestChain: json['longest_chain'] ?? 0,
      lastCompletedDate: DateTime.parse(json['last_completed_date']),
      completionDates: json['completion_dates'] != null
          ? (json['completion_dates'] as List)
              .map((date) => DateTime.parse(date))
              .toList()
          : [],
    );
  }

  bool get isActive {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return lastCompletedDate.isAfter(yesterday);
  }

  bool get canCompleteToday {
    final today = DateTime.now();
    return !(lastCompletedDate.year == today.year &&
             lastCompletedDate.month == today.month &&
             lastCompletedDate.day == today.day);
  }

  ChainTier get tier {
    if (currentChain >= 100) return ChainTier.legendary;
    if (currentChain >= 50) return ChainTier.epic;
    if (currentChain >= 30) return ChainTier.advanced;
    if (currentChain >= 14) return ChainTier.strong;
    if (currentChain >= 7) return ChainTier.moderate;
    if (currentChain >= 3) return ChainTier.building;
    return ChainTier.starting;
  }

  double get staminaMultiplier => tier.staminaMultiplier;
  
  double get experienceMultiplier => tier.experienceMultiplier;
  
  String get displayText => '${currentChain}日連続';
  
  String get tierDisplay => tier.displayName;
}

enum ChainTier {
  starting(name: 'starting', displayName: 'スタート', minDays: 0, staminaMultiplier: 1.0, experienceMultiplier: 1.0, color: 0xFF9E9E9E),
  building(name: 'building', displayName: '継続中', minDays: 3, staminaMultiplier: 1.1, experienceMultiplier: 1.1, color: 0xFF4CAF50),
  moderate(name: 'moderate', displayName: '習慣化', minDays: 7, staminaMultiplier: 1.2, experienceMultiplier: 1.2, color: 0xFF2196F3),
  strong(name: 'strong', displayName: '強固', minDays: 14, staminaMultiplier: 1.3, experienceMultiplier: 1.3, color: 0xFF9C27B0),
  advanced(name: 'advanced', displayName: '上級者', minDays: 30, staminaMultiplier: 1.4, experienceMultiplier: 1.4, color: 0xFFFF5722),
  epic(name: 'epic', displayName: 'エピック', minDays: 50, staminaMultiplier: 1.5, experienceMultiplier: 1.5, color: 0xFFE91E63),
  legendary(name: 'legendary', displayName: 'レジェンド', minDays: 100, staminaMultiplier: 2.0, experienceMultiplier: 2.0, color: 0xFFFFD700);

  const ChainTier({
    required this.name,
    required this.displayName,
    required this.minDays,
    required this.staminaMultiplier,
    required this.experienceMultiplier,
    required this.color,
  });

  final String name;
  final String displayName;
  final int minDays;
  final double staminaMultiplier;
  final double experienceMultiplier;
  final int color;
}
