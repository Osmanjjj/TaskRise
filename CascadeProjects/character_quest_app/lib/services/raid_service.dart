import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/raid.dart';
import '../models/character.dart';
import '../models/crystal.dart';
import 'crystal_service.dart';
import '../config/supabase_config.dart';

class RaidService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get active raid boss
  Future<RaidBoss?> getActiveRaidBoss() async {
    try {
      final response = await _supabase
          .from('raid_bosses')
          .select()
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return RaidBoss.fromJson(response);
    } catch (e) {
      print('Error getting active raid boss: $e');
      return null;
    }
  }

  /// Get upcoming raid boss
  Future<RaidBoss?> getUpcomingRaidBoss() async {
    try {
      final response = await _supabase
          .from('raid_bosses')
          .select()
          .eq('status', 'waiting')
          .order('battle_start_time', ascending: true)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return RaidBoss.fromJson(response);
    } catch (e) {
      print('Error getting upcoming raid boss: $e');
      return null;
    }
  }

  /// Get raid boss history
  Future<List<RaidBoss>> getRaidBossHistory({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('raid_bosses')
          .select()
          .inFilter('status', ['defeated', 'failed'])
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => RaidBoss.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting raid boss history: $e');
      return [];
    }
  }

  /// Join raid battle
  Future<RaidParticipation?> joinRaid(String characterId, String raidBossId) async {
    try {
      // Check if character can participate (has battle points)
      final character = await _getCharacter(characterId);
      if (character == null || !character.canParticipateInRaid) {
        return null;
      }

      // Check if already joined
      final existingParticipation = await _supabase
          .from('raid_participations')
          .select()
          .eq('character_id', characterId)
          .eq('raid_boss_id', raidBossId)
          .maybeSingle();

      if (existingParticipation != null) {
        return RaidParticipation.fromJson(existingParticipation);
      }

      // Create participation record
      final response = await _supabase
          .from('raid_participations')
          .insert({
            'character_id': characterId,
            'raid_boss_id': raidBossId,
            'damage_dealt': 0,
            'battle_points_used': character.battlePoints,
            'joined_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      // Reset character's battle points
      await _supabase
          .from('characters')
          .update({'battle_points': 0})
          .eq('id', characterId);

      return RaidParticipation.fromJson(response);
    } catch (e) {
      print('Error joining raid: $e');
      return null;
    }
  }

  /// Attack raid boss
  Future<RaidAttackResult?> attackRaidBoss(String characterId, String raidBossId) async {
    try {
      // Get character and participation
      final character = await _getCharacter(characterId);
      final participation = await _getRaidParticipation(characterId, raidBossId);
      
      if (character == null || participation == null) return null;

      // Calculate damage based on character stats and battle points used
      final baseDamage = character.attack + (character.level * 2);
      final battlePointsBonus = participation.battlePointsSpent * 10;
      final totalDamage = baseDamage + battlePointsBonus;

      // Update participation with damage
      final newTotalDamage = participation.damageDealt + totalDamage;
      await _supabase
          .from('raid_participations')
          .update({
            'damage_dealt': newTotalDamage,
            'last_attack_time': DateTime.now().toIso8601String(),
          })
          .eq('character_id', characterId)
          .eq('raid_boss_id', raidBossId);

      // Get updated raid boss to check if defeated
      final raidBoss = await getRaidBossById(raidBossId);
      if (raidBoss == null) return null;

      // Calculate total damage from all participants
      final totalDamageDealt = await _getTotalRaidDamage(raidBossId);
      
      bool isDefeated = false;
      if (totalDamageDealt >= raidBoss.maxHealth) {
        // Raid boss defeated!
        await _supabase
            .from('raid_bosses')
            .update({'status': 'defeated'})
            .eq('id', raidBossId);
        
        isDefeated = true;
        
        // Distribute rewards to all participants
        await _distributeRaidRewards(raidBossId);
      }

      return RaidAttackResult(
        damageDealt: totalDamage,
        totalDamageDealt: totalDamageDealt,
        raidBossDefeated: isDefeated,
        personalDamage: newTotalDamage,
      );
    } catch (e) {
      print('Error attacking raid boss: $e');
      return null;
    }
  }

  /// Get raid boss by ID
  Future<RaidBoss?> getRaidBossById(String raidBossId) async {
    try {
      final response = await _supabase
          .from('raid_bosses')
          .select()
          .eq('id', raidBossId)
          .single();

      return RaidBoss.fromJson(response);
    } catch (e) {
      print('Error getting raid boss: $e');
      return null;
    }
  }

  /// Get raid participation for character
  Future<RaidParticipation?> _getRaidParticipation(String characterId, String raidBossId) async {
    try {
      final response = await _supabase
          .from('raid_participations')
          .select()
          .eq('character_id', characterId)
          .eq('raid_boss_id', raidBossId)
          .single();

      return RaidParticipation.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Get character data
  Future<Character?> _getCharacter(String characterId) async {
    try {
      final response = await _supabase
          .from('characters')
          .select()
          .eq('id', characterId)
          .single();

      return Character.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Get total damage dealt to raid boss
  Future<int> _getTotalRaidDamage(String raidBossId) async {
    try {
      final response = await _supabase
          .from('raid_participations')
          .select('damage_dealt')
          .eq('raid_boss_id', raidBossId);

      return (response as List).fold<int>(0, (sum, p) => sum + (p['damage_dealt'] as int));
    } catch (e) {
      return 0;
    }
  }

  /// Distribute rewards to raid participants
  Future<void> _distributeRaidRewards(String raidBossId) async {
    try {
      // Get raid boss rewards
      final raidBoss = await getRaidBossById(raidBossId);
      if (raidBoss == null) return;

      // Get all participants
      final participants = await _supabase
          .from('raid_participations')
          .select()
          .eq('raid_boss_id', raidBossId);

      for (final participantJson in participants) {
        final participation = RaidParticipation.fromJson(participantJson);
        
        // Calculate reward multiplier based on damage contribution
        final totalDamage = await _getTotalRaidDamage(raidBossId);
        final contributionRatio = totalDamage > 0 ? participation.damageDealt / totalDamage : 0.0;
        
        // Base rewards + contribution bonus
        final baseExperience = raidBoss.rewards?['experience'] ?? 100;
        final baseCrystals = raidBoss.rewards?['crystals'] ?? {};
        
        final experienceReward = (baseExperience * (0.5 + contributionRatio * 0.5)).round();
        
        // Give rewards to character
        // Get current character experience
        final charData = await _supabase
            .from('characters')
            .select('experience')
            .eq('id', participation.characterId)
            .single();
        
        final currentExp = charData['experience'] ?? 0;
        await _supabase
            .from('characters')
            .update({
              'experience': currentExp + experienceReward,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', participation.characterId);

        // Give crystal rewards
        if (baseCrystals.isNotEmpty) {
          final crystalService = CrystalService();
          final crystalRewards = <CrystalType, int>{};
          
          for (final entry in baseCrystals.entries) {
            final crystalType = CrystalType.values.firstWhere(
              (t) => t.name == entry.key,
              orElse: () => CrystalType.blue,
            );
            final amount = ((entry.value as int) * (0.5 + contributionRatio * 0.5)).round();
            crystalRewards[crystalType] = amount;
          }
          
          await crystalService.addCrystals(participation.characterId, crystalRewards);
        }

        // Mark participation as rewarded
        await _supabase
            .from('raid_participations')
            .update({'rewards_received': true})
            .eq('id', participation.id);
      }
    } catch (e) {
      print('Error distributing raid rewards: $e');
    }
  }

  /// Get raid leaderboard
  Future<List<RaidParticipation>> getRaidLeaderboard(String raidBossId) async {
    try {
      final response = await _supabase
          .from('raid_participations')
          .select('''
            *,
            character:characters(name, level, avatar_url)
          ''')
          .eq('raid_boss_id', raidBossId)
          .order('damage_dealt', ascending: false);

      return (response as List)
          .map((json) => RaidParticipation.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting raid leaderboard: $e');
      return [];
    }
  }

  /// Stream active raid boss updates
  Stream<RaidBoss?> watchActiveRaidBoss() {
    return _supabase
        .from('raid_bosses')
        .stream(primaryKey: ['id'])
        .eq('status', 'active')
        .map((data) {
          if (data.isEmpty) return null;
          return RaidBoss.fromJson(data.first);
        });
  }

  /// Stream raid participation updates
  Stream<List<RaidParticipation>> watchRaidParticipations(String raidBossId) {
    return _supabase
        .from('raid_participations')
        .stream(primaryKey: ['id'])
        .eq('raid_boss_id', raidBossId)
        .order('damage_dealt', ascending: false)
        .map((data) => data.map((json) => RaidParticipation.fromJson(json)).toList());
  }

  /// Create new raid boss (admin function)
  Future<RaidBoss?> createRaidBoss({
    required String name,
    required String description,
    required int totalHealth,
    required DateTime battleStartTime,
    required DateTime battleEndTime,
    required Map<String, dynamic> rewards,
    String? imageUrl,
  }) async {
    try {
      final response = await _supabase
          .from('raid_bosses')
          .insert({
            'name': name,
            'description': description,
            'total_health': totalHealth,
            'battle_start_time': battleStartTime.toIso8601String(),
            'battle_end_time': battleEndTime.toIso8601String(),
            'rewards': rewards,
            'status': 'waiting',
            'image_url': imageUrl,
          })
          .select()
          .single();

      return RaidBoss.fromJson(response);
    } catch (e) {
      print('Error creating raid boss: $e');
      return null;
    }
  }
}

class RaidAttackResult {
  final int damageDealt;
  final int totalDamageDealt;
  final bool raidBossDefeated;
  final int personalDamage;

  RaidAttackResult({
    required this.damageDealt,
    required this.totalDamageDealt,
    required this.raidBossDefeated,
    required this.personalDamage,
  });
}

// CrystalService is available from crystal_service.dart
