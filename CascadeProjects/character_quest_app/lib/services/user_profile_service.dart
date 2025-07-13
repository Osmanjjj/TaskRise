import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class UserProfileService {
  final _supabase = Supabase.instance.client;

  // Get current user profile
  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) return null;

      return UserProfile.fromJson(response);
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Create user profile (called after successful registration)
  Future<UserProfile?> createUserProfile({
    required String userId,
    required String username,
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      final profileData = {
        'id': userId,
        'username': username,
        'display_name': displayName,
        'bio': bio,
        'avatar_url': avatarUrl,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('user_profiles')
          .insert(profileData)
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      print('Error creating user profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<UserProfile?> updateUserProfile({
    String? username,
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (username != null) updateData['username'] = username;
      if (displayName != null) updateData['display_name'] = displayName;
      if (bio != null) updateData['bio'] = bio;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;

      final response = await _supabase
          .from('user_profiles')
          .update(updateData)
          .eq('id', user.id)
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      print('Error updating user profile: $e');
      return null;
    }
  }

  // Search users by username
  Future<List<UserProfile>> searchUsersByUsername(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final response = await _supabase
          .from('user_profiles')
          .select()
          .or('username.ilike.%$query%,display_name.ilike.%$query%')
          .limit(50);

      return (response as List)
          .map((json) => UserProfile.fromJson(json))
          .toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // Get user profile by ID
  Future<UserProfile?> getUserProfileById(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;

      return UserProfile.fromJson(response);
    } catch (e) {
      print('Error getting user profile by ID: $e');
      return null;
    }
  }

  // Generate and get user QR code
  Future<String?> getUserQRCode() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final profile = await getCurrentUserProfile();
      if (profile == null) return null;

      // Generate QR code data with user ID and username
      final qrData = 'character_quest_user:${user.id}:${profile.username}';
      return qrData;
    } catch (e) {
      print('Error generating QR code: $e');
      return null;
    }
  }

  // Get user stats with character info
  Future<Map<String, dynamic>?> getUserStats() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      // Get user profile
      final profile = await getCurrentUserProfile();
      if (profile == null) return null;

      // Get character stats
      final characterResponse = await _supabase
          .from('characters')
          .select('level, experience, total_habits_completed, current_streak')
          .eq('user_id', user.id)
          .maybeSingle();

      // Get habit stats
      final habitStatsResponse = await _supabase
          .from('habit_completions')
          .select('habit_id')
          .eq('user_id', user.id);

      final totalHabitsCompleted = (habitStatsResponse as List).length;

      // Get social stats
      final friendsResponse = await _supabase
          .from('friendships')
          .select('id')
          .eq('user_id', user.id)
          .eq('status', 'accepted');

      final totalFriends = (friendsResponse as List).length;

      return {
        'profile': profile.toJson(),
        'character': characterResponse ?? {},
        'total_habits_completed': totalHabitsCompleted,
        'total_friends': totalFriends,
        'join_date': profile.createdAt.toIso8601String(),
      };
    } catch (e) {
      print('Error getting user stats: $e');
      return null;
    }
  }

  // Check username availability
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('id')
          .eq('username', username.toLowerCase())
          .maybeSingle();

      return response == null;
    } catch (e) {
      print('Error checking username availability: $e');
      return false;
    }
  }

  // Delete user profile (for account deletion)
  Future<bool> deleteUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase
          .from('user_profiles')
          .delete()
          .eq('id', user.id);

      return true;
    } catch (e) {
      print('Error deleting user profile: $e');
      return false;
    }
  }

  // Upload avatar image
  Future<String?> uploadAvatar(String filePath, List<int> fileBytes) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final fileName = 'avatar_${user.id}_${DateTime.now().millisecondsSinceEpoch}';
      
      final response = await _supabase.storage
          .from('avatars')
          .uploadBinary(fileName, Uint8List.fromList(fileBytes));

      if (response.isEmpty) return null;

      final publicUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      print('Error uploading avatar: $e');
      return null;
    }
  }

  // Get leaderboard data
  Future<List<Map<String, dynamic>>> getLeaderboard({
    String sortBy = 'level',
    int limit = 50,
  }) async {
    try {
      String orderColumn;
      switch (sortBy) {
        case 'level':
          orderColumn = 'level';
          break;
        case 'experience':
          orderColumn = 'experience';
          break;
        case 'streak':
          orderColumn = 'current_streak';
          break;
        case 'habits':
          orderColumn = 'total_habits_completed';
          break;
        default:
          orderColumn = 'level';
      }

      final response = await _supabase
          .from('characters')
          .select('''
            user_id,
            level,
            experience,
            current_streak,
            total_habits_completed,
            user_profiles!inner(username, display_name, avatar_url)
          ''')
          .order(orderColumn, ascending: false)
          .limit(limit);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error getting leaderboard: $e');
      return [];
    }
  }
}
