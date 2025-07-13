// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Habit _$HabitFromJson(Map<String, dynamic> json) => Habit(
  id: json['id'] as String,
  userId: json['userId'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  category: $enumDecode(_$HabitCategoryEnumMap, json['category']),
  difficulty:
      $enumDecodeNullable(_$HabitDifficultyEnumMap, json['difficulty']) ??
      HabitDifficulty.normal,
  frequency:
      $enumDecodeNullable(_$HabitFrequencyEnumMap, json['frequency']) ??
      HabitFrequency.daily,
  weeklyTarget: (json['weeklyTarget'] as num?)?.toInt(),
  customWeekdays: (json['customWeekdays'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  reminderEnabled: json['reminderEnabled'] as bool? ?? false,
  reminderTime: json['reminderTime'] == null
      ? null
      : TimeOfDay.fromJson(json['reminderTime'] as Map<String, dynamic>),
  basePoints: (json['basePoints'] as num?)?.toInt() ?? 10,
  crystalReward: (json['crystalReward'] as num?)?.toInt() ?? 1,
  isActive: json['isActive'] as bool? ?? true,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$HabitToJson(Habit instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'title': instance.title,
  'description': instance.description,
  'category': _$HabitCategoryEnumMap[instance.category]!,
  'difficulty': _$HabitDifficultyEnumMap[instance.difficulty]!,
  'frequency': _$HabitFrequencyEnumMap[instance.frequency]!,
  'weeklyTarget': instance.weeklyTarget,
  'customWeekdays': instance.customWeekdays,
  'reminderEnabled': instance.reminderEnabled,
  'reminderTime': instance.reminderTime,
  'basePoints': instance.basePoints,
  'crystalReward': instance.crystalReward,
  'isActive': instance.isActive,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

const _$HabitCategoryEnumMap = {
  HabitCategory.exercise: 'exercise',
  HabitCategory.study: 'study',
  HabitCategory.health: 'health',
  HabitCategory.work: 'work',
  HabitCategory.hobby: 'hobby',
  HabitCategory.lifestyle: 'lifestyle',
};

const _$HabitDifficultyEnumMap = {
  HabitDifficulty.easy: 'easy',
  HabitDifficulty.normal: 'normal',
  HabitDifficulty.hard: 'hard',
};

const _$HabitFrequencyEnumMap = {
  HabitFrequency.daily: 'daily',
  HabitFrequency.weekly: 'weekly',
  HabitFrequency.custom: 'custom',
};

TimeOfDay _$TimeOfDayFromJson(Map<String, dynamic> json) => TimeOfDay(
  hour: (json['hour'] as num).toInt(),
  minute: (json['minute'] as num).toInt(),
);

Map<String, dynamic> _$TimeOfDayToJson(TimeOfDay instance) => <String, dynamic>{
  'hour': instance.hour,
  'minute': instance.minute,
};

HabitCompletion _$HabitCompletionFromJson(Map<String, dynamic> json) =>
    HabitCompletion(
      id: json['id'] as String,
      habitId: json['habitId'] as String,
      userId: json['userId'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      pointsEarned: (json['pointsEarned'] as num?)?.toInt() ?? 0,
      experienceEarned: (json['experienceEarned'] as num?)?.toInt() ?? 0,
      crystalsEarned: (json['crystalsEarned'] as num?)?.toInt() ?? 0,
      streakBonus: (json['streakBonus'] as num?)?.toDouble() ?? 1.0,
      timeBonus: (json['timeBonus'] as num?)?.toDouble() ?? 1.0,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$HabitCompletionToJson(HabitCompletion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'habitId': instance.habitId,
      'userId': instance.userId,
      'completedAt': instance.completedAt.toIso8601String(),
      'pointsEarned': instance.pointsEarned,
      'experienceEarned': instance.experienceEarned,
      'crystalsEarned': instance.crystalsEarned,
      'streakBonus': instance.streakBonus,
      'timeBonus': instance.timeBonus,
      'note': instance.note,
      'createdAt': instance.createdAt.toIso8601String(),
    };
