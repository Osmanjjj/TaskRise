class Collectible {
  final String id;
  final String name;
  final CollectibleRarity rarity;
  final CollectibleType type;
  final String? imageUrl;
  final String description;
  final Map<String, dynamic> stats;
  final DateTime createdAt;

  Collectible({
    required this.id,
    required this.name,
    required this.rarity,
    required this.type,
    this.imageUrl,
    required this.description,
    required this.stats,
    required this.createdAt,
  });

  factory Collectible.fromJson(Map<String, dynamic> json) {
    return Collectible(
      id: json['id'],
      name: json['name'],
      rarity: CollectibleRarity.values.firstWhere(
        (r) => r.name == json['rarity'],
        orElse: () => CollectibleRarity.common,
      ),
      type: CollectibleType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => CollectibleType.character,
      ),
      imageUrl: json['image_url'],
      description: json['description'] ?? '',
      stats: json['stats'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rarity': rarity.name,
      'type': type.name,
      'image_url': imageUrl,
      'description': description,
      'stats': stats,
      'created_at': createdAt.toIso8601String(),
    };
  }

  int get attackBonus => stats['attack'] as int? ?? 0;
  int get defenseBonus => stats['defense'] as int? ?? 0;
  int get healthBonus => stats['health'] as int? ?? 0;
  int get experienceBonus => stats['experience_multiplier_percent'] as int? ?? 0;

  bool get isEquippable => type == CollectibleType.weapon || 
                          type == CollectibleType.armor;

  String get rarityDisplayName => rarity.displayName;
  String get typeDisplayName => type.displayName;
}

enum CollectibleRarity {
  common(
    name: 'common',
    displayName: 'コモン',
    color: 0xFF757575,
    pullRate: 50.0,
    dustValue: 5,
  ),
  rare(
    name: 'rare',
    displayName: 'レア',
    color: 0xFF2196F3,
    pullRate: 30.0,
    dustValue: 20,
  ),
  epic(
    name: 'epic',
    displayName: 'エピック',
    color: 0xFF9C27B0,
    pullRate: 15.0,
    dustValue: 100,
  ),
  legendary(
    name: 'legendary',
    displayName: '伝説',
    color: 0xFFFF9800,
    pullRate: 4.5,
    dustValue: 400,
  ),
  mythic(
    name: 'mythic',
    displayName: '神話',
    color: 0xFFE91E63,
    pullRate: 0.5,
    dustValue: 1600,
  );

  const CollectibleRarity({
    required this.name,
    required this.displayName,
    required this.color,
    required this.pullRate,
    required this.dustValue,
  });

  final String name;
  final String displayName;
  final int color;
  final double pullRate; // Percentage chance to pull
  final int dustValue; // Value when converted to dust
}

enum CollectibleType {
  character(name: 'character', displayName: 'キャラクター', emoji: '👤'),
  weapon(name: 'weapon', displayName: '武器', emoji: '⚔️'),
  armor(name: 'armor', displayName: '防具', emoji: '🛡️'),
  pet(name: 'pet', displayName: 'ペット', emoji: '🐾'),
  mount(name: 'mount', displayName: 'マウント', emoji: '🐴'),
  skill(name: 'skill', displayName: 'スキル', emoji: '💫');

  const CollectibleType({
    required this.name,
    required this.displayName,
    required this.emoji,
  });

  final String name;
  final String displayName;
  final String emoji;
}

class UserCollectible {
  final String id;
  final String characterId;
  final String collectibleId;
  final int quantity;
  final DateTime obtainedAt;
  final Collectible? collectible; // Populated via join

  UserCollectible({
    required this.id,
    required this.characterId,
    required this.collectibleId,
    required this.quantity,
    required this.obtainedAt,
    this.collectible,
  });

  factory UserCollectible.fromJson(Map<String, dynamic> json) {
    return UserCollectible(
      id: json['id'],
      characterId: json['character_id'],
      collectibleId: json['collectible_id'],
      quantity: json['quantity'] ?? 1,
      obtainedAt: DateTime.parse(json['obtained_at']),
      collectible: json['collectible'] != null 
          ? Collectible.fromJson(json['collectible'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'character_id': characterId,
      'collectible_id': collectibleId,
      'quantity': quantity,
      'obtained_at': obtainedAt.toIso8601String(),
      if (collectible != null) 'collectible': collectible!.toJson(),
    };
  }

  UserCollectible copyWith({
    String? id,
    String? characterId,
    String? collectibleId,
    int? quantity,
    DateTime? obtainedAt,
    Collectible? collectible,
  }) {
    return UserCollectible(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      collectibleId: collectibleId ?? this.collectibleId,
      quantity: quantity ?? this.quantity,
      obtainedAt: obtainedAt ?? this.obtainedAt,
      collectible: collectible ?? this.collectible,
    );
  }

  bool get isNewlyObtained {
    final now = DateTime.now();
    final timeDifference = now.difference(obtainedAt);
    return timeDifference.inMinutes < 5; // Consider "new" for 5 minutes
  }
}

class GachaResult {
  final List<UserCollectible> obtainedItems;
  final int crystalsUsed;
  final DateTime timestamp;
  final GachaType gachaType;

  GachaResult({
    required this.obtainedItems,
    required this.crystalsUsed,
    required this.timestamp,
    required this.gachaType,
  });

  bool get hasRareOrBetter => obtainedItems.any((item) =>
      item.collectible?.rarity.name != 'common');

  bool get hasLegendaryOrBetter => obtainedItems.any((item) =>
      item.collectible?.rarity.name == 'legendary' ||
      item.collectible?.rarity.name == 'mythic');

  CollectibleRarity get highestRarity {
    if (obtainedItems.isEmpty) return CollectibleRarity.common;
    
    return obtainedItems
        .map((item) => item.collectible?.rarity ?? CollectibleRarity.common)
        .reduce((current, next) {
          final currentIndex = CollectibleRarity.values.indexOf(current);
          final nextIndex = CollectibleRarity.values.indexOf(next);
          return nextIndex > currentIndex ? next : current;
        });
  }
}

enum GachaType {
  single(name: 'single', displayName: '単発', crystalCost: {'blue': 10}),
  tenPull(name: 'ten_pull', displayName: '10連', crystalCost: {'blue': 90, 'green': 1}),
  premium(name: 'premium', displayName: 'プレミアム', crystalCost: {'green': 5, 'gold': 1});

  const GachaType({
    required this.name,
    required this.displayName,
    required this.crystalCost,
  });

  final String name;
  final String displayName;
  final Map<String, int> crystalCost;
  
  // Compatibility getters
  Map<String, int> get cost => crystalCost;
  int get pullCount => this == GachaType.tenPull ? 10 : 1;
}
