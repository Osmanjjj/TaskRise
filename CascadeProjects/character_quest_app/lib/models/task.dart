enum TaskStatus { pending, completed, failed }

enum TaskDifficulty {
  easy(displayName: '簡単', color: 0xFF4CAF50, staminaCost: 1, icon: 'easy_icon'),
  normal(displayName: '普通', color: 0xFFFF9800, staminaCost: 2, icon: 'normal_icon'),
  hard(displayName: '難しい', color: 0xFFF44336, staminaCost: 3, icon: 'hard_icon');

  const TaskDifficulty({
    required this.displayName,
    required this.color,
    required this.staminaCost,
    required this.icon,
  });

  final String displayName;
  final int color;
  final int staminaCost;
  final String icon;
}

enum TaskCategory {
  health('健康'),
  learning('学習'),
  work('仕事'),
  hobby('趣味'),
  other('その他');
  
  final String displayName;
  const TaskCategory(this.displayName);
  
  static TaskCategory fromString(String value) {
    return TaskCategory.values.firstWhere(
      (category) => category.displayName == value,
      orElse: () => TaskCategory.other,
    );
  }
}

class Task {
  final String id;
  final String title;
  final String? description;
  final TaskDifficulty difficulty;
  final TaskStatus status;
  final TaskCategory category;
  final int experienceReward;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? characterId;
  
  // Habit-related properties for compatibility
  final int chainLength;
  final bool isCompleted;
  
  // Streak tracking properties
  final bool isHabit;
  final int streakCount;
  final DateTime? lastCompletedDate;
  final double streakBonusMultiplier;
  final int maxStreak;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.difficulty = TaskDifficulty.normal,
    this.status = TaskStatus.pending,
    this.category = TaskCategory.other,
    required this.experienceReward,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.characterId,
    this.chainLength = 0,
    bool? isCompleted,
    this.isHabit = false,
    this.streakCount = 0,
    this.lastCompletedDate,
    this.streakBonusMultiplier = 1.0,
    this.maxStreak = 0,
  }) : isCompleted = isCompleted ?? (status == TaskStatus.completed);

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      difficulty: TaskDifficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => TaskDifficulty.normal,
      ),
      status: TaskStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TaskStatus.pending,
      ),
      category: json['category'] != null 
        ? TaskCategory.fromString(json['category'])
        : TaskCategory.other,
      experienceReward: json['experience_reward'] ?? 0,
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      characterId: json['character_id'],
      chainLength: json['chain_length'] ?? 0,
      isHabit: json['is_habit'] ?? false,
      streakCount: json['streak_count'] ?? 0,
      lastCompletedDate: json['last_completed_date'] != null 
        ? DateTime.parse(json['last_completed_date']) 
        : null,
      streakBonusMultiplier: json['streak_bonus_multiplier'] != null 
        ? (json['streak_bonus_multiplier'] is String 
          ? double.parse(json['streak_bonus_multiplier']) 
          : (json['streak_bonus_multiplier'] as num).toDouble())
        : 1.0,
      maxStreak: json['max_streak'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'difficulty': difficulty.name,
      'status': status.name,
      'category': category.displayName,
      'experience_reward': experienceReward,
      'due_date': dueDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'character_id': characterId,
      'chain_length': chainLength,
      'is_habit': isHabit,
      'streak_count': streakCount,
      'last_completed_date': lastCompletedDate?.toIso8601String(),
      'streak_bonus_multiplier': streakBonusMultiplier,
      'max_streak': maxStreak,
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskDifficulty? difficulty,
    TaskStatus? status,
    TaskCategory? category,
    int? experienceReward,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? characterId,
    int? chainLength,
    bool? isCompleted,
    bool? isHabit,
    int? streakCount,
    DateTime? lastCompletedDate,
    double? streakBonusMultiplier,
    int? maxStreak,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      status: status ?? this.status,
      category: category ?? this.category,
      experienceReward: experienceReward ?? this.experienceReward,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      characterId: characterId ?? this.characterId,
      chainLength: chainLength ?? this.chainLength,
      isCompleted: isCompleted,
      isHabit: isHabit ?? this.isHabit,
      streakCount: streakCount ?? this.streakCount,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      streakBonusMultiplier: streakBonusMultiplier ?? this.streakBonusMultiplier,
      maxStreak: maxStreak ?? this.maxStreak,
    );
  }

  // Get experience reward based on difficulty
  static int getExperienceForDifficulty(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return 10;
      case TaskDifficulty.normal:
        return 25;
      case TaskDifficulty.hard:
        return 50;
    }
  }

  // Get color for difficulty
  static String getDifficultyColor(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return '#4CAF50'; // Green
      case TaskDifficulty.normal:
        return '#FF9800'; // Orange
      case TaskDifficulty.hard:
        return '#F44336'; // Red
    }
  }
  
  // Calculate experience with streak bonus
  int get experienceWithBonus {
    return (experienceReward * streakBonusMultiplier).round();
  }
  
  // Get streak bonus percentage for display
  int get streakBonusPercentage {
    return ((streakBonusMultiplier - 1.0) * 100).round();
  }
  
  // Calculate streak multiplier based on days
  static double calculateStreakMultiplier(int streakDays) {
    if (streakDays <= 0) return 1.0;
    
    // Base multiplier: 1.0
    // Every 3 days: +0.1x (3日毎に10%ボーナス)
    // Every 7 days: additional +0.1x (1週間毎に追加10%ボーナス)
    // Every 30 days: additional +0.2x (30日毎に追加20%ボーナス)
    
    double baseMultiplier = 1.0;
    double threeDayBonus = (streakDays ~/ 3) * 0.1;
    double weeklyBonus = (streakDays ~/ 7) * 0.1;
    double monthlyBonus = (streakDays ~/ 30) * 0.2;
    
    double totalMultiplier = baseMultiplier + threeDayBonus + weeklyBonus + monthlyBonus;
    
    // Cap at 2.0x (最大2倍)
    return totalMultiplier > 2.0 ? 2.0 : totalMultiplier;
  }
}
