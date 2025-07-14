import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/gacha.dart';

class GachaService {
  final _supabase = Supabase.instance.client;

  // Get all active gacha banners
  Future<List<GachaBanner>> getActiveBanners() async {
    try {
      final response = await _supabase
          .from('gacha_banners')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => GachaBanner.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting active banners: $e');
      return [];
    }
  }

  // Get banner by ID with featured items
  Future<GachaBanner?> getBannerWithItems(String bannerId) async {
    try {
      final bannerResponse = await _supabase
          .from('gacha_banners')
          .select()
          .eq('id', bannerId)
          .maybeSingle();

      if (bannerResponse == null) return null;

      return GachaBanner.fromJson(bannerResponse);
    } catch (e) {
      print('Error getting banner with items: $e');
      return null;
    }
  }

  // Get gacha items for a banner
  Future<List<GachaItem>> getBannerItems(String bannerId) async {
    try {
      final response = await _supabase
          .from('gacha_items')
          .select()
          .eq('banner_id', bannerId)
          .eq('is_available', true)
          .order('rarity', ascending: false);

      return (response as List)
          .map((json) => GachaItem.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting banner items: $e');
      return [];
    }
  }

  // Perform a single gacha pull
  Future<GachaPull?> performSinglePull(String bannerId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      // Get banner details
      final banner = await getBannerWithItems(bannerId);
      if (banner == null || !banner.isActive) return null;

      // Check if user has enough crystals
      final character = await _supabase
          .from('characters')
          .select('crystals')
          .eq('user_id', user.id)
          .maybeSingle();

      if (character == null) return null;

      final currentCrystals = character['crystals'] ?? 0;
      if (currentCrystals < banner.crystalCost) {
        throw Exception('Insufficient crystals');
      }

      // Get available items for this banner
      final items = await getBannerItems(bannerId);
      if (items.isEmpty) return null;

      // Simulate gacha pull based on rarity rates
      final pulledItem = _simulateGachaPull(items);

      // Create pull record
      final pullData = {
        'user_id': user.id,
        'banner_id': bannerId,
        'item_id': pulledItem.id,
        'crystals_spent': banner.crystalCost,
        'created_at': DateTime.now().toIso8601String(),
      };

      final pullResponse = await _supabase
          .from('gacha_pulls')
          .insert(pullData)
          .select()
          .single();

      // Deduct crystals
      await _supabase
          .from('characters')
          .update({
            'crystals': currentCrystals - banner.crystalCost,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', user.id);

      // Add item to user inventory if applicable
      await _addItemToInventory(user.id, pulledItem);

      return GachaPull.fromJson(pullResponse);
    } catch (e) {
      print('Error performing gacha pull: $e');
      return null;
    }
  }

  // Perform multiple gacha pulls (10-pull with guaranteed SR+)
  Future<List<GachaPull>> performMultiPull(String bannerId, {int count = 10}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      // Get banner details
      final banner = await getBannerWithItems(bannerId);
      if (banner == null || !banner.isActive) return [];

      // Check if user has enough crystals
      final character = await _supabase
          .from('characters')
          .select('crystals')
          .eq('user_id', user.id)
          .maybeSingle();

      if (character == null) return [];

      final currentCrystals = character['crystals'] ?? 0;
      final totalCost = banner.crystalCost * count;
      
      if (currentCrystals < totalCost) {
        throw Exception('Insufficient crystals');
      }

      // Get available items
      final items = await getBannerItems(bannerId);
      if (items.isEmpty) return [];

      final pulls = <GachaPull>[];
      bool guaranteedSRUsed = false;

      for (int i = 0; i < count; i++) {
        GachaItem pulledItem;
        
        // Guarantee SR+ on last pull if no SR+ pulled yet
        if (i == count - 1 && !guaranteedSRUsed) {
          final srItems = items.where((item) => 
              item.rarity == Rarity.epic || item.rarity == Rarity.legendary || item.rarity == Rarity.mythic).toList();
          if (srItems.isNotEmpty) {
            pulledItem = _simulateGachaPull(srItems, forcePityPull: true);
          } else {
            pulledItem = _simulateGachaPull(items);
          }
        } else {
          pulledItem = _simulateGachaPull(items);
          if (pulledItem.rarity == Rarity.epic || pulledItem.rarity == Rarity.legendary || pulledItem.rarity == Rarity.mythic) {
            guaranteedSRUsed = true;
          }
        }

        // Create pull record
        final pullData = {
          'user_id': user.id,
          'banner_id': bannerId,
          'item_id': pulledItem.id,
          'crystals_spent': banner.crystalCost,
          'created_at': DateTime.now().toIso8601String(),
        };

        final pullResponse = await _supabase
            .from('gacha_pulls')
            .insert(pullData)
            .select()
            .single();

        pulls.add(GachaPull.fromJson(pullResponse));

        // Add item to inventory
        await _addItemToInventory(user.id, pulledItem);
      }

      // Deduct total crystals
      await _supabase
          .from('characters')
          .update({
            'crystals': currentCrystals - totalCost,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', user.id);

      return pulls;
    } catch (e) {
      print('Error performing multi pull: $e');
      return [];
    }
  }

  // Get user's gacha history
  Future<UserGachaHistory?> getUserGachaHistory() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('user_gacha_history')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) {
        // Create initial history record
        final historyData = {
          'user_id': user.id,
          'total_pulls': 0,
          'total_crystals_spent': 0,
          'ssr_count': 0,
          'sr_count': 0,
          'r_count': 0,
          'pity_counter': 0,
          'last_ssr_pull': null,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        final newHistoryResponse = await _supabase
            .from('user_gacha_history')
            .insert(historyData)
            .select()
            .single();

        return UserGachaHistory.fromJson(newHistoryResponse);
      }

      return UserGachaHistory.fromJson(response);
    } catch (e) {
      print('Error getting user gacha history: $e');
      return null;
    }
  }

  // Get user's recent pulls
  Future<List<GachaPull>> getUserRecentPulls({int limit = 50}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('gacha_pulls')
          .select('''
            *,
            gacha_items!inner(name, rarity, item_type, image_url),
            gacha_banners!inner(name)
          ''')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => GachaPull.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting user recent pulls: $e');
      return [];
    }
  }

  // Simulate gacha pull based on rarity rates
  GachaItem _simulateGachaPull(List<GachaItem> items, {bool forcePityPull = false}) {
    if (forcePityPull) {
      // Return SR+ item for pity
      final rareItems = items.where((item) => 
          item.rarity == Rarity.epic || item.rarity == Rarity.legendary || item.rarity == Rarity.mythic).toList();
      if (rareItems.isNotEmpty) {
        return rareItems[DateTime.now().millisecond % rareItems.length];
      }
    }

    // Calculate cumulative probabilities
    final random = DateTime.now().millisecond / 1000.0;
    double cumulative = 0.0;

    // Group items by rarity
    final rarityGroups = <Rarity, List<GachaItem>>{};
    for (final item in items) {
      rarityGroups.putIfAbsent(item.rarity, () => []).add(item);
    }

    // Check each rarity tier
    for (final rarity in Rarity.values.reversed) { // Start from highest rarity
      if (rarityGroups.containsKey(rarity)) {
        cumulative += _getDropRate(rarity);
        if (random <= cumulative) {
          final rarityItems = rarityGroups[rarity]!;
          return rarityItems[DateTime.now().microsecond % rarityItems.length];
        }
      }
    }

    // Fallback to common item
    final commonItems = rarityGroups[Rarity.common] ?? items;
    return commonItems[DateTime.now().microsecond % commonItems.length];
  }

  // Get drop rate for rarity
  double _getDropRate(Rarity rarity) {
    switch (rarity) {
      case Rarity.common:
        return 0.60; // 60%
      case Rarity.rare:
        return 0.30; // 30%
      case Rarity.epic:
        return 0.08; // 8%
      case Rarity.legendary:
        return 0.015; // 1.5%
      case Rarity.mythic:
        return 0.005; // 0.5%
    }
  }

  // Add item to user inventory
  Future<void> _addItemToInventory(String userId, GachaItem item) async {
    try {
      switch (item.itemType) {
        case GachaItemType.character:
          // Add character or character shards
          await _addCharacterToInventory(userId, item);
          break;
        case GachaItemType.equipment:
          // Add equipment
          await _addEquipmentToInventory(userId, item);
          break;
        case GachaItemType.crystal:
          // Add crystals to inventory
          await _addCrystalToInventory(userId, item);
          break;
        case GachaItemType.consumable:
          // Add consumables to inventory
          await _addConsumableToInventory(userId, item);
          break;
      }
    } catch (e) {
      print('Error adding item to inventory: $e');
    }
  }





  Future<void> _addSkillToInventory(String userId, GachaItem item) async {
    // Implementation depends on skill system
    print('Adding skill ${item.name} to inventory for user $userId');
  }

  Future<void> _addMaterialToInventory(String userId, GachaItem item) async {
    // Implementation depends on material system
    print('Adding material ${item.name} to inventory for user $userId');
  }

  // Update user gacha statistics
  Future<void> _updateGachaStats(String userId, GachaItem item, int crystalsSpent) async {
    try {
      final history = await getUserGachaHistory();
      if (history == null) return;

      final updates = <String, dynamic>{
        'total_pulls': history.totalPulls + 1,
        'total_crystals_spent': history.totalCrystalsSpent + crystalsSpent,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Update rarity counts using rarityCount map
      final newRarityCount = Map<String, int>.from(history.rarityCount);
      final rarityKey = item.rarity.name;
      newRarityCount[rarityKey] = (newRarityCount[rarityKey] ?? 0) + 1;
      
      updates['rarity_count'] = newRarityCount;
      
      // Update pity counter
      switch (item.rarity) {
        case Rarity.common:
        case Rarity.rare:
          updates['pity_counter'] = (history.pityCounter) + 1;
          break;
        case Rarity.epic:
        case Rarity.legendary:
        case Rarity.mythic:
          updates['pity_counter'] = 0; // Reset pity for high rarity items
          break;
      }

      await _supabase
          .from('user_gacha_history')
          .update(updates)
          .eq('user_id', userId);
    } catch (e) {
      print('Error updating gacha stats: $e');
    }
  }

  // Check if user is close to pity (for UI notification)
  Future<bool> isCloseToSSRPity() async {
    try {
      final history = await getUserGachaHistory();
      if (history == null) return false;

      return history.pityCounter >= 80; // Close to 90-pull pity
    } catch (e) {
      return false;
    }
  }

  // Get banner statistics (for display)
  Future<Map<String, dynamic>> getBannerStats(String bannerId) async {
    try {
      final pullsResponse = await _supabase
          .from('gacha_pulls')
          .select('item_id')
          .eq('banner_id', bannerId);

      final totalPulls = (pullsResponse as List).length;

      if (totalPulls == 0) {
        return {
          'total_pulls': 0,
          'ssr_rate': 0.0,
          'sr_rate': 0.0,
          'r_rate': 0.0,
        };
      }

      // Get rarity distribution
      final itemIds = pullsResponse.map((p) => p['item_id']).toList();
      final itemsResponse = await _supabase
          .from('gacha_items')
          .select('rarity')
          .inFilter('id', itemIds);

      final rarityCount = <String, int>{};
      for (final item in itemsResponse as List) {
        final rarity = item['rarity'];
        rarityCount[rarity] = (rarityCount[rarity] ?? 0) + 1;
      }

      return {
        'total_pulls': totalPulls,
        'ssr_rate': (rarityCount['ssr'] ?? 0) / totalPulls,
        'sr_rate': (rarityCount['sr'] ?? 0) / totalPulls,
        'r_rate': (rarityCount['r'] ?? 0) / totalPulls,
      };
    } catch (e) {
      print('Error getting banner stats: $e');
      return {};
    }
  }

  // Helper methods for adding items to inventory
  Future<void> _addCharacterToInventory(String userId, GachaItem item) async {
    // Add character to user's character collection
    await _supabase.from('user_characters').insert({
      'user_id': userId,
      'character_id': item.id,
      'obtained_at': DateTime.now().toIso8601String(),
      'source': 'gacha',
    });
  }

  Future<void> _addEquipmentToInventory(String userId, GachaItem item) async {
    // Add equipment to user's inventory
    await _supabase.from('user_equipment').insert({
      'user_id': userId,
      'equipment_id': item.id,
      'quantity': 1,
      'obtained_at': DateTime.now().toIso8601String(),
      'source': 'gacha',
    });
  }

  Future<void> _addCrystalToInventory(String userId, GachaItem item) async {
    // Add crystals to user's crystal inventory
    final existingCrystal = await _supabase
        .from('user_crystals')
        .select('quantity')
        .eq('user_id', userId)
        .eq('crystal_type', item.id)
        .maybeSingle();

    if (existingCrystal != null) {
      // Update existing crystal count
      await _supabase
          .from('user_crystals')
          .update({
            'quantity': existingCrystal['quantity'] + 1,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('crystal_type', item.id);
    } else {
      // Insert new crystal entry
      await _supabase.from('user_crystals').insert({
        'user_id': userId,
        'crystal_type': item.id,
        'quantity': 1,
        'obtained_at': DateTime.now().toIso8601String(),
        'source': 'gacha',
      });
    }
  }

  Future<void> _addConsumableToInventory(String userId, GachaItem item) async {
    // Add consumables to user's inventory
    final existingItem = await _supabase
        .from('user_consumables')
        .select('quantity')
        .eq('user_id', userId)
        .eq('consumable_id', item.id)
        .maybeSingle();

    if (existingItem != null) {
      // Update existing item count
      await _supabase
          .from('user_consumables')
          .update({
            'quantity': existingItem['quantity'] + 1,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('consumable_id', item.id);
    } else {
      // Insert new consumable entry
      await _supabase.from('user_consumables').insert({
        'user_id': userId,
        'consumable_id': item.id,
        'quantity': 1,
        'obtained_at': DateTime.now().toIso8601String(),
        'source': 'gacha',
      });
    }
  }
}
