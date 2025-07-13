import 'package:json_annotation/json_annotation.dart';

part 'habit.g.dart';

enum HabitCategory {
  @JsonValue('exercise')
  exercise,
  @JsonValue('study')
  study,
  @JsonValue('health')
  health,
  @JsonValue('work')
  work,
  @JsonValue('hobby')
  hobby,
  @JsonValue('lifestyle')
  lifestyle,
}

enum HabitFrequency {
  @JsonValue('daily')
  daily,
  @JsonValue('weekly')
  weekly,
  @JsonValue('custom')
  custom,
}

enum HabitDifficulty {
  @JsonValue('easy')
  easy,
  @JsonValue('normal')
  normal,
  @JsonValue('hard')
  hard,
}

extension HabitCategoryExtension on HabitCategory {
  String get displayName {
    switch (this) {
      case HabitCategory.exercise:
        return '運動';
      case HabitCategory.study:
        return '学習';
      case HabitCategory.health:
        return '健康';
      case HabitCategory.work:
        return '仕事';
      case HabitCategory.hobby:
        return '趣味';
      case HabitCategory.lifestyle:
        return 'ライフスタイル';
    }
  }

  String get icon {
    switch (this) {
      case HabitCategory.exercise:
        return '🏃‍♂️';
      case HabitCategory.study:
        return '📚';
      case HabitCategory.health:
        return '🏥';
      case HabitCategory.work:
        return '💼';
      case HabitCategory.hobby:
        return '🎨';
      case HabitCategory.lifestyle:
        return '🌟';
    }
  }
}

extension HabitDifficultyExtension on HabitDifficulty {
  String get displayName {
    switch (this) {
      case HabitDifficulty.easy:
        return '簡単';
      case HabitDifficulty.normal:
        return '普通';
      case HabitDifficulty.hard:
        return '難しい';
    }
  }

  int get basePoints {
    switch (this) {
      case HabitDifficulty.easy:
        return 8;
      case HabitDifficulty.normal:
        return 10;
      case HabitDifficulty.hard:
        return 15;
    }
  }

  double get multiplier {
    switch (this) {
      case HabitDifficulty.easy:
        return 0.8;
      case HabitDifficulty.normal:
        return 1.0;
      case HabitDifficulty.hard:
        return 1.5;
    }
  }

  int get staminaCost {
    switch (this) {
      case HabitDifficulty.easy:
        return 5;
      case HabitDifficulty.normal:
        return 10;
      case HabitDifficulty.hard:
        return 15;
    }
  }
}

@JsonSerializable()
class Habit {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final HabitCategory category;
  final HabitDifficulty difficulty;
  final HabitFrequency frequency;
  
  // For weekly frequency
  final int? weeklyTarget;
  
  // For custom frequency (0=Sunday, 6=Saturday)
  final List<int>? customWeekdays;
  
  // Reminder settings
  final bool reminderEnabled;
  final TimeOfDay? reminderTime;
  
  // Rewards
  final int basePoints;
  final int crystalReward;
  
  // Status
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Computed properties
  int get currentStreak => 0; // Will be calculated from completions
  bool get isCompletedToday => false; // Will be calculated from completions

  const Habit({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.category,
    this.difficulty = HabitDifficulty.normal,
    this.frequency = HabitFrequency.daily,
    this.weeklyTarget,
    this.customWeekdays,
    this.reminderEnabled = false,
    this.reminderTime,
    this.basePoints = 10,
    this.crystalReward = 1,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Habit.fromJson(Map<String, dynamic> json) => _$HabitFromJson(json);
  Map<String, dynamic> toJson() => _$HabitToJson(this);

  Habit copyWith({
    String? title,
    String? description,
    HabitCategory? category,
    HabitDifficulty? difficulty,
    HabitFrequency? frequency,
    int? weeklyTarget,
    List<int>? customWeekdays,
    bool? reminderEnabled,
    TimeOfDay? reminderTime,
    int? basePoints,
    int? crystalReward,
    bool? isActive,
  }) {
    return Habit(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      frequency: frequency ?? this.frequency,
      weeklyTarget: weeklyTarget ?? this.weeklyTarget,
      customWeekdays: customWeekdays ?? this.customWeekdays,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      basePoints: basePoints ?? this.basePoints,
      crystalReward: crystalReward ?? this.crystalReward,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Habit(id: $id, title: $title, category: $category, difficulty: $difficulty)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Habit && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

@JsonSerializable()
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  factory TimeOfDay.fromJson(Map<String, dynamic> json) => _$TimeOfDayFromJson(json);
  Map<String, dynamic> toJson() => _$TimeOfDayToJson(this);

  @override
  String toString() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeOfDay && other.hour == hour && other.minute == minute;
  }

  @override
  int get hashCode => hour.hashCode ^ minute.hashCode;
}

@JsonSerializable()
class HabitCompletion {
  final String id;
  final String habitId;
  final String userId;
  final DateTime completedAt;
  
  // Rewards earned
  final int pointsEarned;
  final int experienceEarned;
  final int crystalsEarned;
  
  // Bonus multipliers
  final double streakBonus;
  final double timeBonus;
  
  // Note
  final String? note;
  final DateTime createdAt;

  const HabitCompletion({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.completedAt,
    this.pointsEarned = 0,
    this.experienceEarned = 0,
    this.crystalsEarned = 0,
    this.streakBonus = 1.0,
    this.timeBonus = 1.0,
    this.note,
    required this.createdAt,
  });

  factory HabitCompletion.fromJson(Map<String, dynamic> json) => _$HabitCompletionFromJson(json);
  Map<String, dynamic> toJson() => _$HabitCompletionToJson(this);

  @override
  String toString() {
    return 'HabitCompletion(id: $id, habitId: $habitId, pointsEarned: $pointsEarned)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HabitCompletion && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
