import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/crystal.dart';
import '../models/collectible.dart';
import '../config/supabase_config.dart';

class CrystalService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get crystal inventory for a character
  Future<CrystalInventory?> getCrystalInventory(String characterId) async {
    try {
      final response = await _supabase
          .from('crystals')
          .select()
          .eq('character_id', characterId)
          .single();

      return CrystalInventory.fromJson(response);
    } catch (e) {
      print('Error getting crystal inventory: $e');
      return null;
    }
  }

  /// Initialize crystal inventory for new character
  Future<CrystalInventory?> initializeCrystalInventory(String characterId) async {
    try {
      final response = await _supabase
          .from('crystals')
          .insert({
            'character_id': characterId,
            'blue_crystals': 0,
            'green_crystals': 0,
            'gold_crystals': 0,
            'rainbow_crystals': 0,
          })
          .select()
          .single();

      return CrystalInventory.fromJson(response);
    } catch (e) {
      print('Error initializing crystal inventory: $e');
      return null;
    }
  }

  /// Add crystals to inventory
  Future<bool> addCrystals(String characterId, Map<CrystalType, int> crystalsToAdd) async {
    try {
      // Get current inventory
      final currentInventory = await getCrystalInventory(characterId);
      if (currentInventory == null) return false;

      // Calculate new amounts
      final newBlueCrystals = currentInventory.blueCrystals + (crystalsToAdd[CrystalType.blue] ?? 0);
      final newGreenCrystals = currentInventory.greenCrystals + (crystalsToAdd[CrystalType.green] ?? 0);
      final newGoldCrystals = currentInventory.goldCrystals + (crystalsToAdd[CrystalType.gold] ?? 0);
      final newRainbowCrystals = currentInventory.rainbowCrystals + (crystalsToAdd[CrystalType.rainbow] ?? 0);

      // Update inventory
      await _supabase
          .from('crystals')
          .update({
            'blue_crystals': newBlueCrystals,
            'green_crystals': newGreenCrystals,
            'gold_crystals': newGoldCrystals,
            'rainbow_crystals': newRainbowCrystals,
          })
          .eq('character_id', characterId);

      return true;
    } catch (e) {
      print('Error adding crystals: $e');
      return false;
    }
  }

  /// Spend crystals from inventory
  Future<bool> spendCrystals(String characterId, Map<CrystalType, int> crystalsToSpend) async {
    try {
      // Get current inventory
      final currentInventory = await getCrystalInventory(characterId);
      if (currentInventory == null) return false;

      // Check if user has enough crystals
      for (final entry in crystalsToSpend.entries) {
        final currentAmount = currentInventory.getCrystalCount(entry.key);
        if (currentAmount < entry.value) {
          return false; // Not enough crystals
        }
      }

      // Calculate new amounts
      final newBlueCrystals = currentInventory.blueCrystals - (crystalsToSpend[CrystalType.blue] ?? 0);
      final newGreenCrystals = currentInventory.greenCrystals - (crystalsToSpend[CrystalType.green] ?? 0);
      final newGoldCrystals = currentInventory.goldCrystals - (crystalsToSpend[CrystalType.gold] ?? 0);
      final newRainbowCrystals = currentInventory.rainbowCrystals - (crystalsToSpend[CrystalType.rainbow] ?? 0);

      // Update inventory
      await _supabase
          .from('crystals')
          .update({
            'blue_crystals': newBlueCrystals,
            'green_crystals': newGreenCrystals,
            'gold_crystals': newGoldCrystals,
            'rainbow_crystals': newRainbowCrystals,
          })
          .eq('character_id', characterId);

      return true;
    } catch (e) {
      print('Error spending crystals: $e');
      return false;
    }
  }

  /// Perform gacha pull
  Future<GachaResult?> performGacha(String characterId, GachaType gachaType) async {
    try {
      // Get current inventory
      final inventory = await getCrystalInventory(characterId);
      if (inventory == null) return null;

      // Check if user can afford gacha
      final cost = gachaType.cost;
      if (!inventory.canAffordGacha(
        blueCost: cost['blue'] ?? 0,
        greenCost: cost['green'] ?? 0,
        goldCost: cost['gold'] ?? 0,
        rainbowCost: cost['rainbow'] ?? 0,
      )) {
        return null;
      }

      // Spend crystals
      final crystalTypeCost = <CrystalType, int>{};
      for (final entry in cost.entries) {
        final crystalType = CrystalType.values.firstWhere((t) => t.name == entry.key);
        crystalTypeCost[crystalType] = entry.value;
      }
      final success = await spendCrystals(characterId, crystalTypeCost);
      if (!success) return null;

      // Generate gacha results
      final collectibles = await _generateGachaRewards(gachaType);
      
      // Save collectibles to user inventory
      for (final collectible in collectibles) {
        await _addCollectibleToInventory(characterId, collectible);
      }

      return GachaResult(
        gachaType: gachaType,
        collectibles: collectibles,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('Error performing gacha: $e');
      return null;
    }
  }

  /// Generate gacha rewards based on rates
  Future<List<Collectible>> _generateGachaRewards(GachaType gachaType) async {
    try {
      // Get all available collectibles for this gacha type
      final response = await _supabase
          .from('collectibles')
          .select()
          .eq('gacha_type', gachaType.name);

      final allCollectibles = (response as List)
          .map((json) => Collectible.fromJson(json))
          .toList();

      final results = <Collectible>[];
      final pullCount = gachaType.pullCount;

      for (int i = 0; i < pullCount; i++) {
        // Generate random number for rarity determination
        final random = (DateTime.now().millisecondsSinceEpoch + i) % 10000 / 10000.0;
        
        CollectibleRarity targetRarity;
        if (random < 0.01) { // 1% for legendary
          targetRarity = CollectibleRarity.legendary;
        } else if (random < 0.05) { // 4% for epic
          targetRarity = CollectibleRarity.epic;
        } else if (random < 0.20) { // 15% for rare
          targetRarity = CollectibleRarity.rare;
        } else { // 80% for common
          targetRarity = CollectibleRarity.common;
        }

        // Filter collectibles by rarity
        final availableCollectibles = allCollectibles
            .where((c) => c.rarity == targetRarity)
            .toList();

        if (availableCollectibles.isNotEmpty) {
          // Select random collectible from the rarity tier
          final index = (DateTime.now().millisecondsSinceEpoch + i) % availableCollectibles.length;
          results.add(availableCollectibles[index]);
        }
      }

      return results;
    } catch (e) {
      print('Error generating gacha rewards: $e');
      return [];
    }
  }

  /// Add collectible to user inventory
  Future<void> _addCollectibleToInventory(String characterId, Collectible collectible) async {
    try {
      // Check if user already has this collectible
      final existing = await _supabase
          .from('user_collectibles')
          .select()
          .eq('character_id', characterId)
          .eq('collectible_id', collectible.id)
          .maybeSingle();

      if (existing != null) {
        // Increment quantity
        await _supabase
            .from('user_collectibles')
            .update({
              'quantity': existing['quantity'] + 1,
            })
            .eq('character_id', characterId)
            .eq('collectible_id', collectible.id);
      } else {
        // Create new entry
        await _supabase
            .from('user_collectibles')
            .insert({
              'character_id': characterId,
              'collectible_id': collectible.id,
              'quantity': 1,
              'obtained_at': DateTime.now().toIso8601String(),
            });
      }
    } catch (e) {
      print('Error adding collectible to inventory: $e');
    }
  }

  /// Get user's collectibles
  Future<List<UserCollectible>> getUserCollectibles(String characterId) async {
    try {
      final response = await _supabase
          .from('user_collectibles')
          .select('''
            *,
            collectible:collectibles(*)
          ''')
          .eq('character_id', characterId);

      return (response as List)
          .map((json) => UserCollectible.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting user collectibles: $e');
      return [];
    }
  }

  /// Stream crystal inventory changes
  Stream<CrystalInventory?> watchCrystalInventory(String characterId) {
    return _supabase
        .from('crystals')
        .stream(primaryKey: ['character_id'])
        .eq('character_id', characterId)
        .map((data) {
          if (data.isEmpty) return null;
          return CrystalInventory.fromJson(data.first);
        });
  }
}

class GachaResult {
  final GachaType gachaType;
  final List<Collectible> collectibles;
  final DateTime timestamp;

  GachaResult({
    required this.gachaType,
    required this.collectibles,
    required this.timestamp,
  });

  bool get hasLegendary => collectibles.any((c) => c.rarity == CollectibleRarity.legendary);
  bool get hasEpic => collectibles.any((c) => c.rarity == CollectibleRarity.epic);
  bool get hasRare => collectibles.any((c) => c.rarity == CollectibleRarity.rare);

  int get legendaryCount => collectibles.where((c) => c.rarity == CollectibleRarity.legendary).length;
  int get epicCount => collectibles.where((c) => c.rarity == CollectibleRarity.epic).length;
  int get rareCount => collectibles.where((c) => c.rarity == CollectibleRarity.rare).length;
  int get commonCount => collectibles.where((c) => c.rarity == CollectibleRarity.common).length;

  String get resultSummary {
    final parts = <String>[];
    if (legendaryCount > 0) parts.add('★★★★★ ${legendaryCount}個');
    if (epicCount > 0) parts.add('★★★★ ${epicCount}個');
    if (rareCount > 0) parts.add('★★★ ${rareCount}個');
    if (commonCount > 0) parts.add('★★ ${commonCount}個');
    return parts.join(' + ');
  }
}
