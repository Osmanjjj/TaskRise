// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
  id: json['id'] as String,
  username: json['username'] as String,
  displayName: json['displayName'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
  bio: json['bio'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  notificationEnabled: json['notificationEnabled'] as bool? ?? true,
  privateProfile: json['privateProfile'] as bool? ?? false,
  totalHabitsCompleted: (json['totalHabitsCompleted'] as num?)?.toInt() ?? 0,
  longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
  totalCrystalsEarned: (json['totalCrystalsEarned'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'displayName': instance.displayName,
      'avatarUrl': instance.avatarUrl,
      'bio': instance.bio,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'notificationEnabled': instance.notificationEnabled,
      'privateProfile': instance.privateProfile,
      'totalHabitsCompleted': instance.totalHabitsCompleted,
      'longestStreak': instance.longestStreak,
      'totalCrystalsEarned': instance.totalCrystalsEarned,
    };
