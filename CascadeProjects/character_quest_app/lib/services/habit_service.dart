import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/habit_completion.dart';
import '../models/crystal.dart';
import '../models/character.dart';
import '../models/daily_stats.dart';
import 'crystal_service.dart';
import 'mentor_service.dart';

class HabitService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CrystalService _crystalService = CrystalService();
  final MentorService _mentorService = MentorService();

  /// Complete a habit/task
  Future<HabitCompletion?> completeHabit({
    required String characterId,
    required String taskId,
    required String difficulty,
  }) async {
    try {
      // Get character info
      final character = await _getCharacter(characterId);
      if (character == null) return null;

      // Get task info
      final task = await _getTask(taskId);
      if (task == null) return null;

      // Calculate rewards based on difficulty and character level
      final rewards = _calculateRewards(difficulty, character.level, character.consecutiveDays);
      
      // Get habit chain info
      final chain = await getHabitChain(characterId, taskId);
      final newChainLength = chain?.currentChain ?? 0 + 1;
      final isChainBonus = newChainLength >= 3;

      // Apply chain multipliers
      final finalRewards = _applyChainMultipliers(rewards, chain?.tier ?? ChainTier.starting);

      // Create habit completion record
      final completion = await _createHabitCompletion(
        characterId: characterId,
        taskId: taskId,
        rewards: finalRewards,
        chainLength: newChainLength,
        isChainBonus: isChainBonus,
        difficulty: difficulty,
      );

      if (completion == null) return null;

      // Update character stats
      await _updateCharacterStats(
        characterId: characterId,
        experienceGain: finalRewards.experienceEarned,
        battlePointsGain: finalRewards.battlePointsEarned,
        staminaGain: finalRewards.staminaEarned,
      );

      // Add crystals to inventory
      if (finalRewards.crystalsEarned.isNotEmpty) {
        final crystalMap = <CrystalType, int>{};
        for (final crystal in finalRewards.crystalsEarned) {
          crystalMap[crystal.type] = (crystalMap[crystal.type] ?? 0) + crystal.amount;
        }
        await _crystalService.addCrystals(characterId, crystalMap);
      }

      // Update habit chain
      await _updateHabitChain(characterId, taskId, newChainLength);

      // Update daily stats
      await _updateDailyStats(characterId, finalRewards);

      // Update mentee progress (if has mentor)
      await _mentorService.updateMenteeProgress(
        characterId, 
        finalRewards.experienceEarned + finalRewards.battlePointsEarned,
      );

      return completion;
    } catch (e) {
      print('Error completing habit: $e');
      return null;
    }
  }

  /// Get habit completion history
  Future<List<HabitCompletion>> getHabitHistory(String characterId, {int limit = 50}) async {
    try {
      final response = await _supabase
          .from('habit_completions')
          .select()
          .eq('character_id', characterId)
          .order('completed_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => HabitCompletion.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting habit history: $e');
      return [];
    }
  }

  /// Get today's completions
  Future<List<HabitCompletion>> getTodayCompletions(String characterId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('habit_completions')
          .select()
          .eq('character_id', characterId)
          .gte('completed_at', startOfDay.toIso8601String())
          .lt('completed_at', endOfDay.toIso8601String())
          .order('completed_at', ascending: false);

      return (response as List)
          .map((json) => HabitCompletion.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting today\'s completions: $e');
      return [];
    }
  }

  /// Get habit chain for specific task
  Future<HabitChain?> getHabitChain(String characterId, String taskId) async {
    try {
      // Calculate chain from completion history
      final completions = await _supabase
          .from('habit_completions')
          .select('completed_at')
          .eq('character_id', characterId)
          .eq('task_id', taskId)
          .order('completed_at', ascending: false)
          .limit(100);

      if (completions.isEmpty) {
        return HabitChain(
          characterId: characterId,
          taskId: taskId,
          currentChain: 0,
          longestChain: 0,
          lastCompletedDate: DateTime.now(),
          completionDates: [],
        );
      }

      final dates = (completions as List)
          .map((c) => DateTime.parse(c['completed_at']))
          .toList();

      final currentChain = _calculateCurrentChain(dates);
      final longestChain = _calculateLongestChain(dates);

      return HabitChain(
        characterId: characterId,
        taskId: taskId,
        currentChain: currentChain,
        longestChain: longestChain,
        lastCompletedDate: dates.first,
        completionDates: dates,
      );
    } catch (e) {
      print('Error getting habit chain: $e');
      return null;
    }
  }

  /// Get daily stats for character
  Future<DailyStats?> getDailyStats(String characterId, DateTime date) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      final response = await _supabase
          .from('daily_stats')
          .select()
          .eq('character_id', characterId)
          .eq('date', dateStr)
          .maybeSingle();

      if (response == null) return null;
      return DailyStats.fromJson(response);
    } catch (e) {
      print('Error getting daily stats: $e');
      return null;
    }
  }

  /// Get weekly stats
  Future<List<DailyStats>> getWeeklyStats(String characterId) async {
    try {
      final today = DateTime.now();
      final weekAgo = today.subtract(const Duration(days: 7));

      final response = await _supabase
          .from('daily_stats')
          .select()
          .eq('character_id', characterId)
          .gte('date', '${weekAgo.year}-${weekAgo.month.toString().padLeft(2, '0')}-${weekAgo.day.toString().padLeft(2, '0')}')
          .order('date', ascending: true);

      return (response as List)
          .map((json) => DailyStats.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting weekly stats: $e');
      return [];
    }
  }

  /// Calculate rewards based on difficulty and level
  HabitRewards _calculateRewards(String difficulty, int level, int consecutiveDays) {
    int baseExperience = 10;
    int baseBattlePoints = 1;
    int baseStamina = 5;

    // Difficulty multipliers
    switch (difficulty.toLowerCase()) {
      case 'easy':
        baseExperience = 10;
        baseBattlePoints = 1;
        baseStamina = 5;
        break;
      case 'normal':
        baseExperience = 20;
        baseBattlePoints = 2;
        baseStamina = 8;
        break;
      case 'hard':
        baseExperience = 40;
        baseBattlePoints = 4;
        baseStamina = 12;
        break;
    }

    // Level scaling
    baseExperience += (level ~/ 5) * 5;
    
    // Consecutive days bonus
    final consecutiveBonus = 1.0 + (consecutiveDays * 0.02); // 2% per consecutive day

    // Generate crystals (random chance)
    final crystals = _generateCrystalRewards(difficulty, consecutiveDays);

    return HabitRewards(
      experienceEarned: (baseExperience * consecutiveBonus).round(),
      battlePointsEarned: (baseBattlePoints * consecutiveBonus).round(),
      staminaEarned: (baseStamina * consecutiveBonus).round(),
      crystalsEarned: crystals,
    );
  }

  /// Generate crystal rewards based on difficulty and streak
  List<CrystalReward> _generateCrystalRewards(String difficulty, int consecutiveDays) {
    final crystals = <CrystalReward>[];
    final random = DateTime.now().millisecondsSinceEpoch % 100;

    // Base crystal chance based on difficulty
    double blueCrystalChance = 0.3; // 30%
    double greenCrystalChance = 0.1; // 10%
    double goldCrystalChance = 0.02; // 2%
    double rainbowCrystalChance = 0.005; // 0.5%

    switch (difficulty.toLowerCase()) {
      case 'normal':
        blueCrystalChance = 0.4;
        greenCrystalChance = 0.15;
        goldCrystalChance = 0.03;
        rainbowCrystalChance = 0.01;
        break;
      case 'hard':
        blueCrystalChance = 0.6;
        greenCrystalChance = 0.25;
        goldCrystalChance = 0.05;
        rainbowCrystalChance = 0.02;
        break;
    }

    // Consecutive days bonus
    final streakMultiplier = 1.0 + (consecutiveDays * 0.01);
    blueCrystalChance *= streakMultiplier;
    greenCrystalChance *= streakMultiplier;
    goldCrystalChance *= streakMultiplier;
    rainbowCrystalChance *= streakMultiplier;

    // Check for crystal drops
    if (random < (rainbowCrystalChance * 100)) {
      crystals.add(CrystalReward(type: CrystalType.rainbow, amount: 1));
    } else if (random < (goldCrystalChance * 100)) {
      crystals.add(CrystalReward(type: CrystalType.gold, amount: 1));
    } else if (random < (greenCrystalChance * 100)) {
      crystals.add(CrystalReward(type: CrystalType.green, amount: 1));
    } else if (random < (blueCrystalChance * 100)) {
      crystals.add(CrystalReward(type: CrystalType.blue, amount: 1));
    }

    return crystals;
  }

  /// Apply chain multipliers to rewards
  HabitRewards _applyChainMultipliers(HabitRewards rewards, ChainTier tier) {
    return HabitRewards(
      experienceEarned: (rewards.experienceEarned * tier.experienceMultiplier).round(),
      battlePointsEarned: rewards.battlePointsEarned, // Battle points not affected by chain
      staminaEarned: (rewards.staminaEarned * tier.staminaMultiplier).round(),
      crystalsEarned: rewards.crystalsEarned,
    );
  }

  /// Create habit completion record
  Future<HabitCompletion?> _createHabitCompletion({
    required String characterId,
    required String taskId,
    required HabitRewards rewards,
    required int chainLength,
    required bool isChainBonus,
    required String difficulty,
  }) async {
    try {
      final response = await _supabase
          .from('habit_completions')
          .insert({
            'character_id': characterId,
            'task_id': taskId,
            'completed_at': DateTime.now().toIso8601String(),
            'battle_points_earned': rewards.battlePointsEarned,
            'stamina_earned': rewards.staminaEarned,
            'experience_earned': rewards.experienceEarned,
            'crystals_earned': rewards.crystalsEarned.map((c) => c.toJson()).toList(),
            'is_chain_bonus': isChainBonus,
            'chain_length': chainLength,
            'difficulty_multiplier': _getDifficultyMultiplier(difficulty),
          })
          .select()
          .single();

      return HabitCompletion.fromJson(response);
    } catch (e) {
      print('Error creating habit completion: $e');
      return null;
    }
  }

  /// Update character stats
  Future<void> _updateCharacterStats({
    required String characterId,
    required int experienceGain,
    required int battlePointsGain,
    required int staminaGain,
  }) async {
    try {
      // Get current character stats
      final charData = await _supabase
          .from('characters')
          .select('experience, battle_points, stamina, max_stamina')
          .eq('id', characterId)
          .single();
      
      final currentExp = charData['experience'] ?? 0;
      final currentBattlePoints = charData['battle_points'] ?? 0;
      final currentStamina = charData['stamina'] ?? 0;
      final maxStamina = charData['max_stamina'] ?? 100;
      
      // Calculate new values
      final newStamina = (currentStamina + staminaGain).clamp(0, maxStamina);
      
      await _supabase
          .from('characters')
          .update({
            'experience': currentExp + experienceGain,
            'battle_points': currentBattlePoints + battlePointsGain,
            'stamina': newStamina,
            'last_activity_date': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', characterId);
    } catch (e) {
      print('Error updating character stats: $e');
    }
  }

  /// Update habit chain
  Future<void> _updateHabitChain(String characterId, String taskId, int newChainLength) async {
    // Chain is calculated dynamically from completions, so no separate update needed
    // This could be optimized with a separate table if needed for performance
  }

  /// Update daily stats
  Future<void> _updateDailyStats(String characterId, HabitRewards rewards) async {
    try {
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Check if daily stats exist
      final existing = await _supabase
          .from('daily_stats')
          .select()
          .eq('character_id', characterId)
          .eq('date', dateStr)
          .maybeSingle();

      if (existing != null) {
        // Update existing stats
        final currentHabits = existing['habits_completed'] ?? 0;
        final currentBattlePoints = existing['battle_points_earned'] ?? 0;
        final currentStamina = existing['stamina_generated'] ?? 0;
        final currentExp = existing['experience_gained'] ?? 0;
        final currentCrystals = existing['crystals_earned'] ?? 0;
        
        await _supabase
            .from('daily_stats')
            .update({
              'habits_completed': currentHabits + 1,
              'battle_points_earned': currentBattlePoints + rewards.battlePointsEarned,
              'stamina_generated': currentStamina + rewards.staminaEarned,
              'experience_gained': currentExp + rewards.experienceEarned,
              'crystals_earned': currentCrystals + rewards.crystalsEarned.length,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('character_id', characterId)
            .eq('date', dateStr);
      } else {
        // Create new daily stats
        await _supabase
            .from('daily_stats')
            .insert({
              'character_id': characterId,
              'date': dateStr,
              'habits_completed': 1,
              'battle_points_earned': rewards.battlePointsEarned,
              'stamina_generated': rewards.staminaEarned,
              'experience_gained': rewards.experienceEarned,
              'crystals_earned': rewards.crystalsEarned.length,
              'longest_chain': 1,
              'raid_participated': false,
              'guild_quest_participated': false,
            });
      }
    } catch (e) {
      print('Error updating daily stats: $e');
    }
  }

  /// Helper methods
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

  Future<Map<String, dynamic>?> _getTask(String taskId) async {
    try {
      final response = await _supabase
          .from('tasks')
          .select()
          .eq('id', taskId)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  double _getDifficultyMultiplier(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy': return 1.0;
      case 'normal': return 1.5;
      case 'hard': return 2.0;
      default: return 1.0;
    }
  }

  int _calculateCurrentChain(List<DateTime> dates) {
    if (dates.isEmpty) return 0;

    int chain = 1;
    for (int i = 1; i < dates.length; i++) {
      final daysDiff = dates[i-1].difference(dates[i]).inDays;
      if (daysDiff == 1) {
        chain++;
      } else {
        break;
      }
    }
    return chain;
  }

  int _calculateLongestChain(List<DateTime> dates) {
    if (dates.isEmpty) return 0;

    int longestChain = 1;
    int currentChain = 1;

    for (int i = 1; i < dates.length; i++) {
      final daysDiff = dates[i-1].difference(dates[i]).inDays;
      if (daysDiff == 1) {
        currentChain++;
        longestChain = longestChain > currentChain ? longestChain : currentChain;
      } else {
        currentChain = 1;
      }
    }
    return longestChain;
  }

  /// Stream habit completions
  Stream<List<HabitCompletion>> watchHabitCompletions(String characterId) {
    return _supabase
        .from('habit_completions')
        .stream(primaryKey: ['id'])
        .eq('character_id', characterId)
        .order('completed_at', ascending: false)
        .map((data) => data.map((json) => HabitCompletion.fromJson(json)).toList());
  }
}

class HabitRewards {
  final int experienceEarned;
  final int battlePointsEarned;
  final int staminaEarned;
  final List<CrystalReward> crystalsEarned;

  HabitRewards({
    required this.experienceEarned,
    required this.battlePointsEarned,
    required this.staminaEarned,
    required this.crystalsEarned,
  });
}
