import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/gacha_result.dart';
import '../models/gacha_pool.dart';
import '../models/inventory_item.dart';
import '../models/item.dart';

class GachaService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all active gacha pools
  Future<List<GachaPool>> getGachaPools() async {
    try {
      final response = await _supabase
          .from('gacha_pools')
          .select()
          .eq('is_active', true)
          .order('crystal_cost');

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => GachaPool.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching gacha pools: $e');
      return [];
    }
  }

  // Perform gacha
  Future<GachaResult?> performGacha(String characterId, String poolId) async {
    try {
      final response = await _supabase.rpc(
        'perform_gacha',
        params: {
          'p_character_id': characterId,
          'p_pool_id': poolId,
        },
      );

      if (response == null) return null;
      
      return GachaResult.fromJson(response);
    } catch (e) {
      print('Error performing gacha: $e');
      return GachaResult(
        success: false,
        error: 'ガチャの実行に失敗しました',
        items: [],
        crystalSpent: 0,
        crystalType: '',
      );
    }
  }

  // Get character's inventory
  Future<List<InventoryItem>> getCharacterInventory(String characterId) async {
    try {
      final response = await _supabase
          .from('character_inventory')
          .select('*, item:items(*)')
          .eq('character_id', characterId)
          .order('obtained_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => InventoryItem.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching inventory: $e');
      return [];
    }
  }

  // Get character's collection (owned and unowned items)
  Future<Map<String, dynamic>> getCharacterCollection(
    String characterId, {
    ItemType? itemType,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_character_collection',
        params: {
          'p_character_id': characterId,
          if (itemType != null)
            'p_item_type': itemType.toString().split('.').last,
        },
      );

      if (response == null) {
        return {
          'owned_items': [],
          'all_items': [],
        };
      }

      return response;
    } catch (e) {
      print('Error fetching collection: $e');
      return {
        'owned_items': [],
        'all_items': [],
      };
    }
  }

  // Mark items as viewed (not new)
  Future<void> markItemsAsViewed(String characterId, List<String> itemIds) async {
    try {
      await _supabase
          .from('character_inventory')
          .update({'is_new': false})
          .eq('character_id', characterId)
          .inFilter('item_id', itemIds);
    } catch (e) {
      print('Error marking items as viewed: $e');
    }
  }

  // Equip/unequip item
  Future<bool> toggleItemEquipped(
    String characterId,
    String itemId,
    bool equip,
  ) async {
    try {
      await _supabase
          .from('character_inventory')
          .update({'is_equipped': equip})
          .eq('character_id', characterId)
          .eq('item_id', itemId);
      
      return true;
    } catch (e) {
      print('Error toggling item equipped status: $e');
      return false;
    }
  }

  // Get gacha history
  Future<List<Map<String, dynamic>>> getGachaHistory(
    String characterId, {
    int limit = 50,
  }) async {
    try {
      final response = await _supabase
          .from('gacha_history')
          .select('*, pool:gacha_pools(name), item:items(*)')
          .eq('character_id', characterId)
          .order('pulled_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching gacha history: $e');
      return [];
    }
  }

  // Stream new items count for badge
  Stream<int> streamNewItemsCount(String characterId) {
    return _supabase
        .from('character_inventory')
        .stream(primaryKey: ['id'])
        .eq('character_id', characterId)
        .map((data) => 
            data.where((item) => item['is_new'] == true).length
        );
  }
}