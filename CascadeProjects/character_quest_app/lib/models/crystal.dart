import 'package:flutter/material.dart';

enum CrystalType {
  blue(
    name: '青結晶',
    description: 'タスク完了で獲得',
    color: Colors.blue,
    icon: Icons.diamond,
  ),
  green(
    name: '緑結晶',
    description: '7日連続達成で獲得',
    color: Colors.green,
    icon: Icons.eco,
  ),
  gold(
    name: '金結晶',
    description: '30日連続達成で獲得',
    color: Colors.amber,
    icon: Icons.star,
  ),
  rainbow(
    name: '虹結晶',
    description: '仲間を助けた時に獲得',
    color: Colors.purple,
    icon: Icons.auto_awesome,
  );

  const CrystalType({
    required this.name,
    required this.description,
    required this.color,
    required this.icon,
  });

  final String name;
  final String description;
  final Color color;
  final IconData icon;

  static CrystalType fromString(String value) {
    return CrystalType.values.firstWhere(
      (type) => type.toString().split('.').last == value,
      orElse: () => CrystalType.blue,
    );
  }

  // Get value for crystal type (relative value for conversion)
  int get value {
    switch (this) {
      case CrystalType.blue:
        return 1;
      case CrystalType.green:
        return 5;
      case CrystalType.gold:
        return 20;
      case CrystalType.rainbow:
        return 100;
    }
  }

  // Get emoji for display
  String get emoji {
    switch (this) {
      case CrystalType.blue:
        return '💎';
      case CrystalType.green:
        return '💚';
      case CrystalType.gold:
        return '⭐';
      case CrystalType.rainbow:
        return '🌈';
    }
  }
}

class CrystalInventory {
  final String id;
  final String characterId;
  final int blueCrystals;
  final int greenCrystals;
  final int goldCrystals;
  final int rainbowCrystals;
  final int storageLimit;
  final double conversionRateBonus;
  final DateTime createdAt;
  final DateTime updatedAt;

  CrystalInventory({
    required this.id,
    required this.characterId,
    this.blueCrystals = 0,
    this.greenCrystals = 0,
    this.goldCrystals = 0,
    this.rainbowCrystals = 0,
    this.storageLimit = 100,
    this.conversionRateBonus = 1.0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CrystalInventory.fromJson(Map<String, dynamic> json) {
    return CrystalInventory(
      id: json['id'],
      characterId: json['character_id'],
      blueCrystals: json['blue_crystals'] ?? 0,
      greenCrystals: json['green_crystals'] ?? 0,
      goldCrystals: json['gold_crystals'] ?? 0,
      rainbowCrystals: json['rainbow_crystals'] ?? 0,
      storageLimit: json['storage_limit'] ?? 100,
      conversionRateBonus: (json['conversion_rate_bonus'] ?? 1.0).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'character_id': characterId,
      'blue_crystals': blueCrystals,
      'green_crystals': greenCrystals,
      'gold_crystals': goldCrystals,
      'rainbow_crystals': rainbowCrystals,
      'storage_limit': storageLimit,
      'conversion_rate_bonus': conversionRateBonus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  int getTotalCrystals() {
    return blueCrystals + greenCrystals + goldCrystals + rainbowCrystals;
  }

  int getCrystalCount(CrystalType type) {
    switch (type) {
      case CrystalType.blue:
        return blueCrystals;
      case CrystalType.green:
        return greenCrystals;
      case CrystalType.gold:
        return goldCrystals;
      case CrystalType.rainbow:
        return rainbowCrystals;
    }
  }

  bool hasSpaceFor(int amount) {
    return getTotalCrystals() + amount <= storageLimit;
  }

  CrystalInventory copyWith({
    String? id,
    String? characterId,
    int? blueCrystals,
    int? greenCrystals,
    int? goldCrystals,
    int? rainbowCrystals,
    int? storageLimit,
    double? conversionRateBonus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CrystalInventory(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      blueCrystals: blueCrystals ?? this.blueCrystals,
      greenCrystals: greenCrystals ?? this.greenCrystals,
      goldCrystals: goldCrystals ?? this.goldCrystals,
      rainbowCrystals: rainbowCrystals ?? this.rainbowCrystals,
      storageLimit: storageLimit ?? this.storageLimit,
      conversionRateBonus: conversionRateBonus ?? this.conversionRateBonus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CrystalTransaction {
  final String id;
  final String characterId;
  final CrystalType crystalType;
  final int amount;
  final String transactionType;
  final String source;
  final String? sourceId;
  final String? description;
  final DateTime createdAt;

  CrystalTransaction({
    required this.id,
    required this.characterId,
    required this.crystalType,
    required this.amount,
    required this.transactionType,
    required this.source,
    this.sourceId,
    this.description,
    required this.createdAt,
  });

  factory CrystalTransaction.fromJson(Map<String, dynamic> json) {
    return CrystalTransaction(
      id: json['id'],
      characterId: json['character_id'],
      crystalType: CrystalType.fromString(json['crystal_type']),
      amount: json['amount'],
      transactionType: json['transaction_type'],
      source: json['source'],
      sourceId: json['source_id'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'character_id': characterId,
      'crystal_type': crystalType.toString().split('.').last,
      'amount': amount,
      'transaction_type': transactionType,
      'source': source,
      'source_id': sourceId,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Crystal reward configuration
class CrystalReward {
  final CrystalType type;
  final int amount;
  final String reason;

  const CrystalReward({
    required this.type,
    required this.amount,
    required this.reason,
  });

  static const taskCompletion = CrystalReward(
    type: CrystalType.blue,
    amount: 1,
    reason: 'タスク完了',
  );

  static const streak7Days = CrystalReward(
    type: CrystalType.green,
    amount: 5,
    reason: '7日連続達成',
  );

  static const streak30Days = CrystalReward(
    type: CrystalType.gold,
    amount: 20,
    reason: '30日連続達成',
  );

  static const helpFriend = CrystalReward(
    type: CrystalType.rainbow,
    amount: 3,
    reason: '仲間を助けた',
  );

  static const weeklyStreak = CrystalReward(
    type: CrystalType.green,
    amount: 3,
    reason: '週間連続ボーナス',
  );

  factory CrystalReward.fromJson(Map<String, dynamic> json) {
    return CrystalReward(
      type: CrystalType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => CrystalType.blue,
      ),
      amount: json['amount'] ?? 0,
      reason: json['reason'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'amount': amount,
      'reason': reason,
    };
  }
}