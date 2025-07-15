import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/character.dart';

/// Service for managing character data and operations
class CharacterService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get user's current character
  Future<Character?> getUserCharacter(String userId) async {
    try {
      // 複数のキャラクターが存在する場合は最新のものを取得
      final response = await _supabase
          .from('characters')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      return Character(
        id: response['id'],
        name: response['name'] ?? 'Unknown',
        level: response['level'] ?? 1,
        experience: response['experience'] ?? 0,
        health: response['health'] ?? 100,
        attack: response['attack'] ?? 10,
        defense: response['defense'] ?? 10,
        avatarUrl: response['avatar_url'],
        createdAt: DateTime.parse(response['created_at']),
        updatedAt: DateTime.parse(response['updated_at']),
        battlePoints: response['battle_points'] ?? 0,
        stamina: response['stamina'] ?? 100,
        maxStamina: response['max_stamina'] ?? 100,
        guildId: response['guild_id'],
        mentorId: response['mentor_id'],
        totalCrystalsEarned: response['total_crystals_earned'] ?? 0,
        consecutiveDays: response['consecutive_days'] ?? 0,
        lastActivityDate: response['last_activity_date'] != null
            ? DateTime.parse(response['last_activity_date'])
            : DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user character: $e');
      }
      return null;
    }
  }

  /// Get character by ID
  Future<Character?> getCharacterById(String characterId) async {
    try {
      final response = await _supabase
          .from('characters')
          .select('*')
          .eq('id', characterId)
          .maybeSingle();

      if (response == null) return null;

      return Character(
        id: response['id'],
        name: response['name'] ?? 'Unknown',
        level: response['level'] ?? 1,
        experience: response['experience'] ?? 0,
        health: response['health'] ?? 100,
        attack: response['attack'] ?? 10,
        defense: response['defense'] ?? 10,
        avatarUrl: response['avatar_url'],
        createdAt: DateTime.parse(response['created_at']),
        updatedAt: DateTime.parse(response['updated_at']),
        battlePoints: response['battle_points'] ?? 0,
        stamina: response['stamina'] ?? 100,
        maxStamina: response['max_stamina'] ?? 100,
        guildId: response['guild_id'],
        mentorId: response['mentor_id'],
        totalCrystalsEarned: response['total_crystals_earned'] ?? 0,
        consecutiveDays: response['consecutive_days'] ?? 0,
        lastActivityDate: response['last_activity_date'] != null
            ? DateTime.parse(response['last_activity_date'])
            : DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting character by ID: $e');
      }
      return null;
    }
  }

  /// Update character stats
  Future<bool> updateCharacterStats(String userId, {
    int? level,
    int? experience,
    int? health,
    int? attack,
    int? defense,
    int? stamina,
    int? maxStamina,
    int? battlePoints,
    int? totalCrystalsEarned,
    int? consecutiveDays,
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (level != null) updates['level'] = level;
      if (experience != null) updates['experience'] = experience;
      if (health != null) updates['health'] = health;
      if (attack != null) updates['attack'] = attack;
      if (defense != null) updates['defense'] = defense;
      if (stamina != null) updates['stamina'] = stamina;
      if (maxStamina != null) updates['max_stamina'] = maxStamina;
      if (battlePoints != null) updates['battle_points'] = battlePoints;
      if (totalCrystalsEarned != null) updates['total_crystals_earned'] = totalCrystalsEarned;
      if (consecutiveDays != null) updates['consecutive_days'] = consecutiveDays;

      if (updates.isEmpty) return true;

      updates['updated_at'] = DateTime.now().toIso8601String();

      // Get character ID from user ID
      final character = await getUserCharacter(userId);
      if (character == null) return false;
      
      await _supabase
          .from('characters')
          .update(updates)
          .eq('id', character.id);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating character stats: $e');
      }
      return false;
    }
  }

  /// Add experience to character and handle level ups
  Future<Map<String, dynamic>> addExperience(String userId, int expGain) async {
    try {
      final character = await getUserCharacter(userId);
      if (character == null) {
        return {'success': false, 'error': 'Character not found'};
      }

      int totalExp = character.experience + expGain;
      int oldLevel = character.level;
      int newLevel = (totalExp / 100).floor() + 1;
      bool leveledUp = newLevel > oldLevel;
      
      // Calculate stat increases on level up
      int attackIncrease = 0;
      int defenseIncrease = 0;
      int healthIncrease = 0;
      int maxStaminaIncrease = 0;
      
      if (leveledUp) {
        final levelDiff = newLevel - oldLevel;
        attackIncrease = levelDiff * 2;  // +2 attack per level
        defenseIncrease = levelDiff * 2;  // +2 defense per level
        healthIncrease = levelDiff * 10;  // +10 HP per level
        maxStaminaIncrease = levelDiff * 5;  // +5 max stamina per level
      }

      // Update character with new stats
      final success = await updateCharacterStats(
        userId,
        level: newLevel,
        experience: totalExp,
        attack: character.attack + attackIncrease,
        defense: character.defense + defenseIncrease,
        health: character.health + healthIncrease,
        maxStamina: character.maxStamina + maxStaminaIncrease,
        stamina: character.stamina + maxStaminaIncrease, // Also restore stamina on level up
      );

      if (!success) {
        return {'success': false, 'error': 'Failed to update character'};
      }

      return {
        'success': true,
        'leveledUp': leveledUp,
        'oldLevel': oldLevel,
        'newLevel': newLevel,
        'totalExperience': totalExp,
        'expGained': expGain,
        'statIncreases': leveledUp ? {
          'attack': attackIncrease,
          'defense': defenseIncrease,
          'health': healthIncrease,
          'maxStamina': maxStaminaIncrease,
        } : null,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error adding experience: $e');
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get character's equipment
  Future<List<Map<String, dynamic>>> getCharacterEquipment(String userId) async {
    try {
      final response = await _supabase
          .from('user_equipment')
          .select('*, equipment:equipment_id(*)')
          .eq('user_id', userId)
          .eq('equipped', true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting character equipment: $e');
      }
      return [];
    }
  }

  /// Equip an item
  Future<bool> equipItem(String userId, String equipmentId) async {
    try {
      // First, unequip any item of the same type
      final equipment = await _supabase
          .from('equipment')
          .select('equipment_type')
          .eq('id', equipmentId)
          .single();

      await _supabase
          .from('user_equipment')
          .update({'equipped': false})
          .eq('user_id', userId)
          .eq('equipment_type', equipment['equipment_type']);

      // Then equip the new item
      await _supabase
          .from('user_equipment')
          .update({'equipped': true})
          .eq('user_id', userId)
          .eq('equipment_id', equipmentId);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error equipping item: $e');
      }
      return false;
    }
  }

  /// Get character's skills
  Future<List<Map<String, dynamic>>> getCharacterSkills(String userId) async {
    try {
      final response = await _supabase
          .from('user_skills')
          .select('*, skill:skill_id(*)')
          .eq('user_id', userId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting character skills: $e');
      }
      return [];
    }
  }

  /// Upgrade a skill
  Future<bool> upgradeSkill(String userId, String skillId) async {
    try {
      final userSkill = await _supabase
          .from('user_skills')
          .select('level')
          .eq('user_id', userId)
          .eq('skill_id', skillId)
          .maybeSingle();

      if (userSkill == null) {
        // Learn new skill
        await _supabase.from('user_skills').insert({
          'user_id': userId,
          'skill_id': skillId,
          'level': 1,
          'learned_at': DateTime.now().toIso8601String(),
        });
      } else {
        // Upgrade existing skill
        await _supabase
            .from('user_skills')
            .update({
              'level': userSkill['level'] + 1,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('skill_id', skillId);
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error upgrading skill: $e');
      }
      return false;
    }
  }

  /// Get character statistics
  Future<Map<String, dynamic>> getCharacterStats(String userId) async {
    try {
      final character = await getUserCharacter(userId);
      if (character == null) return {};

      final equipment = await getCharacterEquipment(userId);
      final skills = await getCharacterSkills(userId);

      // Calculate total stats including equipment bonuses
      int totalAttack = character.attack;
      int totalDefense = character.defense;
      int totalHealth = character.health;

      for (final item in equipment) {
        final equipmentData = item['equipment'];
        if (equipmentData != null) {
          totalAttack += (equipmentData['attack_bonus'] ?? 0) as int;
          totalDefense += (equipmentData['defense_bonus'] ?? 0) as int;
          totalHealth += (equipmentData['health_bonus'] ?? 0) as int;
        }
      }

      return {
        'character': character.toJson(),
        'totalStats': {
          'attack': totalAttack,
          'defense': totalDefense,
          'health': totalHealth,
        },
        'equipment': equipment,
        'skills': skills,
        'skillCount': skills.length,
        'equipmentCount': equipment.length,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting character stats: $e');
      }
      return {};
    }
  }
}
