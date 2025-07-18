import 'item.dart';

class GachaPool {
  final String id;
  final String name;
  final String? description;
  final String crystalType;
  final int crystalCost;
  final int pullCount;
  final ItemRarity? guaranteedRarity;
  final bool isActive;
  final DateTime createdAt;

  GachaPool({
    required this.id,
    required this.name,
    this.description,
    required this.crystalType,
    required this.crystalCost,
    required this.pullCount,
    this.guaranteedRarity,
    required this.isActive,
    required this.createdAt,
  });

  factory GachaPool.fromJson(Map<String, dynamic> json) {
    return GachaPool(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      crystalType: json['crystal_type'],
      crystalCost: json['crystal_cost'],
      pullCount: json['pull_count'],
      guaranteedRarity: json['guaranteed_rarity'] != null
          ? ItemRarity.values.firstWhere(
              (e) => e.toString().split('.').last == json['guaranteed_rarity'],
            )
          : null,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'crystal_type': crystalType,
      'crystal_cost': crystalCost,
      'pull_count': pullCount,
      'guaranteed_rarity': guaranteedRarity?.toString().split('.').last,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}