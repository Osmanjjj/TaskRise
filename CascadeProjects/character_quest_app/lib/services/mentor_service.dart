import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mentor.dart';
import '../models/character.dart' as char;
import '../config/supabase_config.dart';

class MentorService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Request mentorship
  Future<MentorRelationship?> requestMentorship(String menteeId, String mentorId) async {
    try {
      // Check if mentor is eligible
      final mentorStats = await getMentorStats(mentorId);
      if (mentorStats == null) return null;

      // Check if mentor has capacity
      if (mentorStats.activeMentees >= mentorStats.tier.maxMentees) {
        return null;
      }

      // Check if relationship already exists
      final existing = await _supabase
          .from('mentor_relationships')
          .select()
          .eq('mentor_id', mentorId)
          .eq('mentee_id', menteeId)
          .maybeSingle();

      if (existing != null) {
        return MentorRelationship.fromJson(existing);
      }

      // Create mentorship request
      final response = await _supabase
          .from('mentor_relationships')
          .insert({
            'mentor_id': mentorId,
            'mentee_id': menteeId,
            'status': MentorshipStatus.pending.name,
            'mentor_rewards_earned': 0,
            'mentee_progress_bonus': 1.0,
            'started_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return MentorRelationship.fromJson(response);
    } catch (e) {
      print('Error requesting mentorship: $e');
      return null;
    }
  }

  /// Accept mentorship request
  Future<bool> acceptMentorship(String relationshipId) async {
    try {
      await _supabase
          .from('mentor_relationships')
          .update({
            'status': MentorshipStatus.active.name,
            'mentee_progress_bonus': 1.2, // 20% bonus for mentees
          })
          .eq('id', relationshipId);

      return true;
    } catch (e) {
      print('Error accepting mentorship: $e');
      return false;
    }
  }

  /// Decline mentorship request
  Future<bool> declineMentorship(String relationshipId) async {
    try {
      await _supabase
          .from('mentor_relationships')
          .update({
            'status': MentorshipStatus.cancelled.name,
            'ended_at': DateTime.now().toIso8601String(),
          })
          .eq('id', relationshipId);

      return true;
    } catch (e) {
      print('Error declining mentorship: $e');
      return false;
    }
  }

  /// Complete mentorship
  Future<bool> completeMentorship(String relationshipId, int finalReward) async {
    try {
      // Get relationship details
      final relationship = await _supabase
          .from('mentor_relationships')
          .select()
          .eq('id', relationshipId)
          .single();

      final mentorRelationship = MentorRelationship.fromJson(relationship);

      // Update relationship status
      await _supabase
          .from('mentor_relationships')
          .update({
            'status': MentorshipStatus.completed.name,
            'ended_at': DateTime.now().toIso8601String(),
            'mentor_rewards_earned': mentorRelationship.mentorRewardsEarned + finalReward,
          })
          .eq('id', relationshipId);

      // Give final rewards to mentor
      final mentorData = await _supabase
        .from('characters')
        .select('experience')
        .eq('id', mentorRelationship.mentorId)
        .single();
    
      final currentExp = mentorData['experience'] ?? 0;
      await _supabase
        .from('characters')
        .update({
          'experience': currentExp + finalReward,
        })
        .eq('id', mentorRelationship.mentorId);

      return true;
    } catch (e) {
      print('Error completing mentorship: $e');
      return false;
    }
  }

  /// Get mentor stats
  Future<MentorStats?> getMentorStats(String mentorId) async {
    try {
      // Get mentor statistics
      final stats = await _supabase.rpc('get_mentor_stats', params: {
        'mentor_id_param': mentorId,
      });

      if (stats == null) {
        // Create initial stats if not exists
        return MentorStats(
          mentorId: mentorId,
          totalMentees: 0,
          activeMentees: 0,
          completedMentorships: 0,
          totalRewardsEarned: 0,
          averageMenteeProgress: 0.0,
          mentorRank: 1,
          lastActivityDate: DateTime.now(),
        );
      }

      return MentorStats.fromJson(stats);
    } catch (e) {
      print('Error getting mentor stats: $e');
      return null;
    }
  }

  /// Get available mentors
  Future<List<char.Character>> getAvailableMentors({int limit = 20}) async {
    try {
      // Get characters who can be mentors (level 15+, completed at least 3 mentorships or have good stats)
      final response = await _supabase
          .rpc('get_available_mentors', params: {
            'limit_param': limit,
          });

      return (response as List)
          .map((json) => char.Character.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting available mentors: $e');
      return [];
    }
  }

  /// Get mentorship relationships for character
  Future<List<MentorRelationship>> getCharacterMentorships(String characterId) async {
    try {
      final response = await _supabase
          .from('mentor_relationships')
          .select('''
            *,
            mentor:characters!mentor_id(id, name, level, avatar_url),
            mentee:characters!mentee_id(id, name, level, avatar_url)
          ''')
          .or('mentor_id.eq.$characterId,mentee_id.eq.$characterId')
          .order('started_at', ascending: false);

      return (response as List)
          .map((json) => MentorRelationship.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting character mentorships: $e');
      return [];
    }
  }

  /// Get pending mentorship requests for mentor
  Future<List<MentorRelationship>> getPendingRequests(String mentorId) async {
    try {
      final response = await _supabase
          .from('mentor_relationships')
          .select('''
            *,
            mentee:characters!mentee_id(id, name, level, avatar_url)
          ''')
          .eq('mentor_id', mentorId)
          .eq('status', MentorshipStatus.pending.name)
          .order('started_at', ascending: false);

      return (response as List)
          .map((json) => MentorRelationship.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting pending requests: $e');
      return [];
    }
  }

  /// Update mentee progress and give mentor rewards
  Future<bool> updateMenteeProgress(String menteeId, int progressPoints) async {
    try {
      // Get active mentorship for mentee
      final mentorship = await _supabase
          .from('mentor_relationships')
          .select()
          .eq('mentee_id', menteeId)
          .eq('status', MentorshipStatus.active.name)
          .maybeSingle();

      if (mentorship == null) return false;

      final relationship = MentorRelationship.fromJson(mentorship);

      // Calculate mentor reward (10% of mentee progress)
      final mentorReward = (progressPoints * 0.1).round();

      // Update mentor relationship
      await _supabase
          .from('mentor_relationships')
          .update({
            'mentor_rewards_earned': relationship.mentorRewardsEarned + mentorReward,
          })
          .eq('id', relationship.id);

      // Give reward to mentor
      final mentorData = await _supabase
        .from('characters')
        .select('experience')
        .eq('id', relationship.mentorId)
        .single();
    
      final currentExp = mentorData['experience'] ?? 0;
      await _supabase
        .from('characters')
        .update({
          'experience': currentExp + mentorReward,
        })
        .eq('id', relationship.mentorId);

      return true;
    } catch (e) {
      print('Error updating mentee progress: $e');
      return false;
    }
  }

  /// Get mentor leaderboard
  Future<List<MentorLeaderboardEntry>> getMentorLeaderboard({int limit = 50}) async {
    try {
      final response = await _supabase
          .rpc('get_mentor_leaderboard', params: {
            'limit_param': limit,
          });

      return (response as List)
          .map((json) => MentorLeaderboardEntry.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting mentor leaderboard: $e');
      return [];
    }
  }

  /// Search mentors by criteria
  Future<List<char.Character>> searchMentors({
    MentorTier? tier,
    int? minLevel,
    String? nameQuery,
    int limit = 20,
  }) async {
    try {
      var query = _supabase
          .from('characters')
          .select('''
            *,
            mentor_stats:mentor_relationships!mentor_id(*)
          ''')
          .gte('level', minLevel ?? 15);

      if (nameQuery != null && nameQuery.isNotEmpty) {
        query = query.ilike('name', '%$nameQuery%');
      }

      final response = await query
          .order('level', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => char.Character.fromJson(json))
          .toList();
    } catch (e) {
      print('Error searching mentors: $e');
      return [];
    }
  }

  /// Stream mentorship updates
  Stream<List<MentorRelationship>> watchMentorships(String characterId) {
    return _supabase
        .from('mentor_relationships')
        .stream(primaryKey: ['id'])
        .map((data) => data
            .where((json) => json['mentor_id'] == characterId || json['mentee_id'] == characterId)
            .map((json) => MentorRelationship.fromJson(json))
            .toList());
  }

  /// Stream pending requests
  Stream<List<MentorRelationship>> watchPendingRequests(String mentorId) {
    return _supabase
        .from('mentor_relationships')
        .stream(primaryKey: ['id'])
        .map((data) => data
            .where((json) => json['mentor_id'] == mentorId && json['status'] == MentorshipStatus.pending.name)
            .map((json) => MentorRelationship.fromJson(json))
            .toList());
  }
}

class MentorLeaderboardEntry {
  final String mentorId;
  final String mentorName;
  final String? avatarUrl;
  final int level;
  final int completedMentorships;
  final int totalRewardsEarned;
  final double averageMenteeProgress;
  final MentorTier tier;
  final int rank;

  MentorLeaderboardEntry({
    required this.mentorId,
    required this.mentorName,
    this.avatarUrl,
    required this.level,
    required this.completedMentorships,
    required this.totalRewardsEarned,
    required this.averageMenteeProgress,
    required this.tier,
    required this.rank,
  });

  factory MentorLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return MentorLeaderboardEntry(
      mentorId: json['mentor_id'],
      mentorName: json['mentor_name'],
      avatarUrl: json['avatar_url'],
      level: json['level'],
      completedMentorships: json['completed_mentorships'],
      totalRewardsEarned: json['total_rewards_earned'],
      averageMenteeProgress: (json['average_mentee_progress'] as num?)?.toDouble() ?? 0.0,
      tier: MentorTier.values.firstWhere(
        (t) => t.minMentorships <= json['completed_mentorships'],
        orElse: () => MentorTier.novice,
      ),
      rank: json['rank'] ?? 0,
    );
  }

  String get displayRank => '#$rank';
  String get successRateDisplay => '${(averageMenteeProgress * 100).round()}%';
}
