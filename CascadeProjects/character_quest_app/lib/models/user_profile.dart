import 'package:json_annotation/json_annotation.dart';

part 'user_profile.g.dart';

@JsonSerializable()
class UserProfile {
  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Settings
  final bool notificationEnabled;
  final bool privateProfile;
  
  // Stats
  final int totalHabitsCompleted;
  final int longestStreak;
  final int totalCrystalsEarned;

  const UserProfile({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.bio,
    required this.createdAt,
    required this.updatedAt,
    this.notificationEnabled = true,
    this.privateProfile = false,
    this.totalHabitsCompleted = 0,
    this.longestStreak = 0,
    this.totalCrystalsEarned = 0,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  UserProfile copyWith({
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    bool? notificationEnabled,
    bool? privateProfile,
    int? totalHabitsCompleted,
    int? longestStreak,
    int? totalCrystalsEarned,
  }) {
    return UserProfile(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      privateProfile: privateProfile ?? this.privateProfile,
      totalHabitsCompleted: totalHabitsCompleted ?? this.totalHabitsCompleted,
      longestStreak: longestStreak ?? this.longestStreak,
      totalCrystalsEarned: totalCrystalsEarned ?? this.totalCrystalsEarned,
    );
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, username: $username, displayName: $displayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
