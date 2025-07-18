import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/crystal.dart';

class CrystalService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get crystal inventory for a character
  Future<CrystalInventory?> getCrystalInventory(String characterId) async {
    try {
      final response = await _supabase
          .from('crystal_inventory')
          .select()
          .eq('character_id', characterId)
          .maybeSingle();

      if (response == null) {
        // Create new inventory if it doesn't exist
        await _supabase
            .from('crystal_inventory')
            .insert({'character_id': characterId});
        
        final newInventory = await _supabase
            .from('crystal_inventory')
            .select()
            .eq('character_id', characterId)
            .single();
        
        return CrystalInventory.fromJson(newInventory);
      }

      return CrystalInventory.fromJson(response);
    } catch (e) {
      print('Error getting crystal inventory: $e');
      return null;
    }
  }

  // Award crystals to a character
  Future<Map<String, dynamic>> awardCrystals({
    required String characterId,
    required CrystalType crystalType,
    required int amount,
    required String source,
    String? sourceId,
    String? description,
  }) async {
    try {
      final result = await _supabase.rpc('award_crystals', params: {
        'p_character_id': characterId,
        'p_crystal_type': crystalType.toString().split('.').last,
        'p_amount': amount,
        'p_source': source,
        'p_source_id': sourceId,
        'p_description': description,
      });

      return result as Map<String, dynamic>;
    } catch (e) {
      print('Error awarding crystals: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Check and award streak milestone crystals
  Future<Map<String, dynamic>> checkStreakMilestones({
    required String characterId,
    required int streakCount,
    required String taskId,
  }) async {
    try {
      final result = await _supabase.rpc('check_streak_milestone_crystals', params: {
        'p_character_id': characterId,
        'p_streak_count': streakCount,
        'p_task_id': taskId,
      });

      return result as Map<String, dynamic>;
    } catch (e) {
      print('Error checking streak milestones: $e');
      return {
        'milestone_reached': false,
        'error': e.toString(),
      };
    }
  }

  // Get crystal transaction history
  Future<List<CrystalTransaction>> getCrystalTransactions(String characterId, {int limit = 50}) async {
    try {
      final response = await _supabase
          .from('crystal_transactions')
          .select()
          .eq('character_id', characterId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => CrystalTransaction.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting crystal transactions: $e');
      return [];
    }
  }

  // Spend crystals (for gacha or other features)
  Future<bool> spendCrystals({
    required String characterId,
    required CrystalType crystalType,
    required int amount,
    required String purpose,
  }) async {
    try {
      final inventory = await getCrystalInventory(characterId);
      if (inventory == null) return false;

      // Check if player has enough crystals
      if (inventory.getCrystalCount(crystalType) < amount) {
        return false;
      }

      // Update inventory
      final updateData = <String, dynamic>{};
      switch (crystalType) {
        case CrystalType.blue:
          updateData['blue_crystals'] = inventory.blueCrystals - amount;
          break;
        case CrystalType.green:
          updateData['green_crystals'] = inventory.greenCrystals - amount;
          break;
        case CrystalType.gold:
          updateData['gold_crystals'] = inventory.goldCrystals - amount;
          break;
        case CrystalType.rainbow:
          updateData['rainbow_crystals'] = inventory.rainbowCrystals - amount;
          break;
      }
      updateData['updated_at'] = DateTime.now().toIso8601String();

      await _supabase
          .from('crystal_inventory')
          .update(updateData)
          .eq('character_id', characterId);

      // Log transaction
      await _supabase.from('crystal_transactions').insert({
        'character_id': characterId,
        'crystal_type': crystalType.toString().split('.').last,
        'amount': -amount,
        'transaction_type': 'spent',
        'source': purpose,
      });

      return true;
    } catch (e) {
      print('Error spending crystals: $e');
      return false;
    }
  }

  // Convert crystals (with conversion rate bonus)
  Future<bool> convertCrystals({
    required String characterId,
    required CrystalType fromType,
    required CrystalType toType,
    required int amount,
  }) async {
    try {
      final inventory = await getCrystalInventory(characterId);
      if (inventory == null) return false;

      // Define conversion rates (can be adjusted)
      final conversionRates = {
        'blue_to_green': 5.0,   // 5 blue = 1 green
        'green_to_gold': 5.0,   // 5 green = 1 gold
        'gold_to_rainbow': 5.0, // 5 gold = 1 rainbow
      };

      // Calculate converted amount with bonus
      final baseRate = _getConversionRate(fromType, toType, conversionRates);
      if (baseRate == 0) return false;

      final effectiveRate = baseRate / inventory.conversionRateBonus;
      final convertedAmount = (amount / effectiveRate).floor();

      if (convertedAmount == 0) return false;

      // Check if player has enough crystals
      if (inventory.getCrystalCount(fromType) < amount) {
        return false;
      }

      // Perform conversion
      final spendSuccess = await spendCrystals(
        characterId: characterId,
        crystalType: fromType,
        amount: amount,
        purpose: 'conversion',
      );

      if (!spendSuccess) return false;

      final awardResult = await awardCrystals(
        characterId: characterId,
        crystalType: toType,
        amount: convertedAmount,
        source: 'conversion',
        description: '${fromType.name} → ${toType.name}',
      );

      return awardResult['success'] == true;
    } catch (e) {
      print('Error converting crystals: $e');
      return false;
    }
  }

  double _getConversionRate(CrystalType from, CrystalType to, Map<String, double> rates) {
    final key = '${from.toString().split('.').last}_to_${to.toString().split('.').last}';
    return rates[key] ?? 0;
  }

  /// Stream crystal inventory changes
  Stream<CrystalInventory?> watchCrystalInventory(String characterId) {
    return _supabase
        .from('crystal_inventory')
        .stream(primaryKey: ['id'])
        .eq('character_id', characterId)
        .map((data) {
          if (data.isEmpty) return null;
          return CrystalInventory.fromJson(data.first);
        });
  }
}