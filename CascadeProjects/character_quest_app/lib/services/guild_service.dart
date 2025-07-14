import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/guild.dart';
import '../models/character.dart';

class GuildService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create a new guild
  Future<Guild?> createGuild({
    required String name,
    required String description,
    required GuildType type,
    required String creatorId,
    int maxMembers = 50,
    String? imageUrl,
  }) async {
    try {
      final response = await _supabase
          .from('guilds')
          .insert({
            'name': name,
            'description': description,
            'guild_type': type.name,
            'creator_id': creatorId,
            'max_members': maxMembers,
            'current_members': 1,
            'image_url': imageUrl,
          })
          .select()
          .single();

      final guild = Guild.fromJson(response);

      // Add creator as leader
      await _supabase
          .from('guild_memberships')
          .insert({
            'guild_id': guild.id,
            'character_id': creatorId,
            'role': GuildRole.leader.name,
            'contribution_points': 0,
          });

      return guild;
    } catch (e) {
      print('Error creating guild: $e');
      return null;
    }
  }

  /// Get guild by ID
  Future<Guild?> getGuildById(String guildId) async {
    try {
      final response = await _supabase
          .from('guilds')
          .select()
          .eq('id', guildId)
          .single();

      return Guild.fromJson(response);
    } catch (e) {
      print('Error getting guild: $e');
      return null;
    }
  }

  /// Get all public guilds
  Future<List<Guild>> getPublicGuilds({int limit = 20}) async {
    try {
      final response = await _supabase
          .from('guilds')
          .select()
          .eq('guild_type', 'free_weekly')
          .eq('is_active', true)
          .order('current_members', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => Guild.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting public guilds: $e');
      return [];
    }
  }

  /// Search guilds by name
  Future<List<Guild>> searchGuilds(String query) async {
    try {
      final response = await _supabase
          .from('guilds')
          .select()
          .ilike('name', '%$query%')
          .eq('is_active', true)
          .limit(20);

      return (response as List)
          .map((json) => Guild.fromJson(json))
          .toList();
    } catch (e) {
      print('Error searching guilds: $e');
      return [];
    }
  }

  /// Join a guild
  Future<GuildMembership?> joinGuild(String guildId, String characterId) async {
    try {
      // Check if guild exists and has space
      final guild = await getGuildById(guildId);
      if (guild == null || !guild.hasSpace) {
        return null;
      }

      // Check if already a member
      final existingMembership = await _supabase
          .from('guild_memberships')
          .select()
          .eq('guild_id', guildId)
          .eq('character_id', characterId)
          .maybeSingle();

      if (existingMembership != null) {
        return GuildMembership.fromJson(existingMembership);
      }

      // Create membership
      final response = await _supabase
          .from('guild_memberships')
          .insert({
            'guild_id': guildId,
            'character_id': characterId,
            'role': GuildRole.member.name,
            'contribution_points': 0,
          })
          .select()
          .single();

      // Update guild member count
      final guildData = await _supabase
          .from('guilds')
          .select('current_members')
          .eq('id', guildId)
          .single();
      
      await _supabase
          .from('guilds')
          .update({
            'current_members': (guildData['current_members'] ?? 0) + 1,
          })
          .eq('id', guildId);

      return GuildMembership.fromJson(response);
    } catch (e) {
      print('Error joining guild: $e');
      return null;
    }
  }

  /// Leave a guild
  Future<bool> leaveGuild(String guildId, String characterId) async {
    try {
      // Get membership
      final membership = await _supabase
          .from('guild_memberships')
          .select()
          .eq('guild_id', guildId)
          .eq('character_id', characterId)
          .single();

      final membershipObj = GuildMembership.fromJson(membership);

      // Don't allow leader to leave if there are other members
      if (membershipObj.role == GuildRole.leader) {
        final memberCount = await _getGuildMemberCount(guildId);
        if (memberCount > 1) {
          return false; // Need to transfer leadership first
        }
      }

      // Remove membership
      await _supabase
          .from('guild_memberships')
          .delete()
          .eq('guild_id', guildId)
          .eq('character_id', characterId);

      // Update guild member count
      final newMemberCount = await _getGuildMemberCount(guildId);
      await _supabase
          .from('guilds')
          .update({
            'current_members': newMemberCount,
          })
          .eq('id', guildId);

      return true;
    } catch (e) {
      print('Error leaving guild: $e');
      return false;
    }
  }

  /// Get guild members
  Future<List<GuildMembership>> getGuildMembers(String guildId) async {
    try {
      final response = await _supabase
          .from('guild_memberships')
          .select('''
            *,
            character:characters(id, name, level, avatar_url)
          ''')
          .eq('guild_id', guildId)
          .order('contribution_points', ascending: false);

      return (response as List)
          .map((json) => GuildMembership.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting guild members: $e');
      return [];
    }
  }

  /// Get character's guild membership
  Future<GuildMembership?> getCharacterGuild(String characterId) async {
    try {
      final response = await _supabase
          .from('guild_memberships')
          .select('''
            *,
            guild:guilds(*)
          ''')
          .eq('character_id', characterId)
          .maybeSingle();

      if (response == null) return null;
      return GuildMembership.fromJson(response);
    } catch (e) {
      print('Error getting character guild: $e');
      return null;
    }
  }

  /// Create guild quest
  Future<GuildQuest?> createGuildQuest({
    required String guildId,
    required String name,
    required String description,
    required Map<String, dynamic> requirements,
    required Map<String, dynamic> rewards,
    required DateTime deadline,
  }) async {
    try {
      final response = await _supabase
          .from('guild_quests')
          .insert({
            'guild_id': guildId,
            'name': name,
            'description': description,
            'requirements': requirements,
            'rewards': rewards,
            'deadline': deadline.toIso8601String(),
            'status': QuestStatus.active.name,
            'progress': 0.0,
          })
          .select()
          .single();

      return GuildQuest.fromJson(response);
    } catch (e) {
      print('Error creating guild quest: $e');
      return null;
    }
  }

  /// Get guild quests
  Future<List<GuildQuest>> getGuildQuests(String guildId) async {
    try {
      final response = await _supabase
          .from('guild_quests')
          .select()
          .eq('guild_id', guildId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => GuildQuest.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting guild quests: $e');
      return [];
    }
  }

  /// Update guild quest progress
  Future<bool> updateQuestProgress(String questId, double progress) async {
    try {
      await _supabase
          .from('guild_quests')
          .update({'progress': progress})
          .eq('id', questId);

      // Check if quest is completed
      if (progress >= 1.0) {
        await _supabase
            .from('guild_quests')
            .update({'status': QuestStatus.completed.name})
            .eq('id', questId);

        // TODO: Distribute rewards to guild members
        await _distributeQuestRewards(questId);
      }

      return true;
    } catch (e) {
      print('Error updating quest progress: $e');
      return false;
    }
  }

  /// Distribute quest rewards to guild members
  Future<void> _distributeQuestRewards(String questId) async {
    try {
      // Get quest details
      final questResponse = await _supabase
          .from('guild_quests')
          .select()
          .eq('id', questId)
          .single();

      final quest = GuildQuest.fromJson(questResponse);

      // Get guild members
      final members = await getGuildMembers(quest.guildId);

      // Distribute rewards
      for (final member in members) {
        final rewards = quest.rewards;
        
        // Give experience
        if (rewards['experience'] != null) {
          final charData = await _supabase
              .from('characters')
              .select('experience')
              .eq('id', member.characterId)
              .single();
          
          final currentExp = charData['experience'] ?? 0;
          await _supabase
              .from('characters')
              .update({
                'experience': currentExp + (rewards['experience'] as int),
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', member.characterId);
        }

        // Give contribution points
        final contributionPoints = rewards['contribution_points'] ?? 50;
        final membershipData = await _supabase
            .from('guild_memberships')
            .select('contribution_points')
            .eq('id', member.id)
            .single();
        
        final currentPoints = membershipData['contribution_points'] ?? 0;
        await _supabase
            .from('guild_memberships')
            .update({
              'contribution_points': currentPoints + contributionPoints,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', member.id);
      }
    } catch (e) {
      print('Error distributing quest rewards: $e');
    }
  }

  /// Promote/demote guild member
  Future<bool> updateMemberRole(String membershipId, GuildRole newRole) async {
    try {
      await _supabase
          .from('guild_memberships')
          .update({'role': newRole.name})
          .eq('id', membershipId);

      return true;
    } catch (e) {
      print('Error updating member role: $e');
      return false;
    }
  }

  /// Kick member from guild
  Future<bool> kickMember(String guildId, String characterId) async {
    try {
      await _supabase
          .from('guild_memberships')
          .delete()
          .eq('guild_id', guildId)
          .eq('character_id', characterId);

      // Update guild member count
      final newMemberCount = await _getGuildMemberCount(guildId);
      await _supabase
          .from('guilds')
          .update({
            'current_members': newMemberCount,
          })
          .eq('id', guildId);

      return true;
    } catch (e) {
      print('Error kicking member: $e');
      return false;
    }
  }

  /// Get guild member count
  Future<int> _getGuildMemberCount(String guildId) async {
    try {
      final response = await _supabase
          .from('guild_memberships')
          .select()
          .eq('guild_id', guildId);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Stream guild updates
  Stream<Guild?> watchGuild(String guildId) {
    return _supabase
        .from('guilds')
        .stream(primaryKey: ['id'])
        .eq('id', guildId)
        .map((data) {
          if (data.isEmpty) return null;
          return Guild.fromJson(data.first);
        });
  }

  /// Stream guild members
  Stream<List<GuildMembership>> watchGuildMembers(String guildId) {
    return _supabase
        .from('guild_memberships')
        .stream(primaryKey: ['id'])
        .eq('guild_id', guildId)
        .order('contribution_points', ascending: false)
        .map((data) => data.map((json) => GuildMembership.fromJson(json)).toList());
  }

  /// Stream guild quests
  Stream<List<GuildQuest>> watchGuildQuests(String guildId) {
    return _supabase
        .from('guild_quests')
        .stream(primaryKey: ['id'])
        .eq('guild_id', guildId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => GuildQuest.fromJson(json)).toList());
  }
}
