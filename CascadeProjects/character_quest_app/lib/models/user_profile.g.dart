// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
  id: json['id'] as String,
  username: json['username'] as String,
  displayName: json['display_name'] as String?,
  avatarUrl: json['avatar_url'] as String?,
  bio: json['bio'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  notificationEnabled: json['notification_enabled'] as bool? ?? true,
  privateProfile: json['private_profile'] as bool? ?? false,
  totalHabitsCompleted: (json['total_habits_completed'] as num?)?.toInt() ?? 0,
  longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
  totalCrystalsEarned: (json['total_crystals_earned'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'display_name': instance.displayName,
      'avatar_url': instance.avatarUrl,
      'bio': instance.bio,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'notification_enabled': instance.notificationEnabled,
      'private_profile': instance.privateProfile,
      'total_habits_completed': instance.totalHabitsCompleted,
      'longest_streak': instance.longestStreak,
      'total_crystals_earned': instance.totalCrystalsEarned,
    };
