class Crystal {
  final String id;
  final String characterId;
  final CrystalType type;
  final int quantity;
  final DateTime createdAt;
  final DateTime updatedAt;

  Crystal({
    required this.id,
    required this.characterId,
    required this.type,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Crystal.fromJson(Map<String, dynamic> json) {
    return Crystal(
      id: json['id'],
      characterId: json['character_id'],
      type: CrystalType.values.firstWhere(
        (e) => e.name == json['crystal_type'],
        orElse: () => CrystalType.blue,
      ),
      quantity: json['quantity'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'character_id': characterId,
      'crystal_type': type.name,
      'quantity': quantity,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Crystal copyWith({
    String? id,
    String? characterId,
    CrystalType? type,
    int? quantity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Crystal(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum CrystalType {
  blue(name: 'blue', displayName: '青結晶', baseReward: 1, color: 0xFF2196F3, emoji: '💙'),
  green(name: 'green', displayName: '緑結晶', baseReward: 5, color: 0xFF4CAF50, emoji: '💚'),
  gold(name: 'gold', displayName: '金結晶', baseReward: 20, color: 0xFFFFD700, emoji: '💛'),
  rainbow(name: 'rainbow', displayName: '虹結晶', baseReward: 3, color: 0xFF9C27B0, emoji: '🌈');

  const CrystalType({
    required this.name,
    required this.displayName,
    required this.baseReward,
    required this.color,
    required this.emoji,
  });

  final String name;
  final String displayName;
  final int baseReward;
  final int color;
  final String emoji;
  
  // Alias for baseReward to maintain compatibility
  int get value => baseReward;
}

class CrystalInventory {
  final Map<CrystalType, int> crystals;

  CrystalInventory({Map<CrystalType, int>? crystals})
      : crystals = crystals ?? {
          CrystalType.blue: 0,
          CrystalType.green: 0,
          CrystalType.gold: 0,
          CrystalType.rainbow: 0,
        };

  factory CrystalInventory.fromCrystalList(List<Crystal> crystalList) {
    final Map<CrystalType, int> inventory = {};
    for (final crystal in crystalList) {
      inventory[crystal.type] = crystal.quantity;
    }
    return CrystalInventory(crystals: inventory);
  }
  
  factory CrystalInventory.fromJson(Map<String, dynamic> json) {
    final crystals = <CrystalType, int>{};
    for (final type in CrystalType.values) {
      crystals[type] = json[type.name] ?? 0;
    }
    return CrystalInventory(crystals: crystals);
  }

  int get totalCrystals => crystals.values.fold(0, (sum, count) => sum + count);

  int getCrystalCount(CrystalType type) => crystals[type] ?? 0;
  
  // Individual crystal type getters for compatibility
  int get blueCrystals => getCrystalCount(CrystalType.blue);
  int get greenCrystals => getCrystalCount(CrystalType.green);
  int get goldCrystals => getCrystalCount(CrystalType.gold);
  int get rainbowCrystals => getCrystalCount(CrystalType.rainbow);

  bool canAffordGacha({
    int blueCost = 10,
    int greenCost = 2,
    int goldCost = 1,
    int rainbowCost = 0,
  }) {
    return getCrystalCount(CrystalType.blue) >= blueCost &&
           getCrystalCount(CrystalType.green) >= greenCost &&
           getCrystalCount(CrystalType.gold) >= goldCost &&
           getCrystalCount(CrystalType.rainbow) >= rainbowCost;
  }

  CrystalInventory useCrystals({
    int blueCost = 0,
    int greenCost = 0,
    int goldCost = 0,
    int rainbowCost = 0,
  }) {
    final newCrystals = Map<CrystalType, int>.from(crystals);
    newCrystals[CrystalType.blue] = (newCrystals[CrystalType.blue] ?? 0) - blueCost;
    newCrystals[CrystalType.green] = (newCrystals[CrystalType.green] ?? 0) - greenCost;
    newCrystals[CrystalType.gold] = (newCrystals[CrystalType.gold] ?? 0) - goldCost;
    newCrystals[CrystalType.rainbow] = (newCrystals[CrystalType.rainbow] ?? 0) - rainbowCost;
    
    return CrystalInventory(crystals: newCrystals);
  }

  CrystalInventory addCrystals({
    int blueGain = 0,
    int greenGain = 0,
    int goldGain = 0,
    int rainbowGain = 0,
  }) {
    final newCrystals = Map<CrystalType, int>.from(crystals);
    newCrystals[CrystalType.blue] = (newCrystals[CrystalType.blue] ?? 0) + blueGain;
    newCrystals[CrystalType.green] = (newCrystals[CrystalType.green] ?? 0) + greenGain;
    newCrystals[CrystalType.gold] = (newCrystals[CrystalType.gold] ?? 0) + goldGain;
    newCrystals[CrystalType.rainbow] = (newCrystals[CrystalType.rainbow] ?? 0) + rainbowGain;
    
    return CrystalInventory(crystals: newCrystals);
  }
}
