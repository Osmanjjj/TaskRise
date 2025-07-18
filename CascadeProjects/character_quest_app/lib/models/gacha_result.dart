import 'item.dart';

class GachaResult {
  final bool success;
  final String? error;
  final List<GachaItem> items;
  final int crystalSpent;
  final String crystalType;

  GachaResult({
    required this.success,
    this.error,
    required this.items,
    required this.crystalSpent,
    required this.crystalType,
  });

  factory GachaResult.fromJson(Map<String, dynamic> json) {
    return GachaResult(
      success: json['success'],
      error: json['error'],
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => GachaItem.fromJson(item))
          .toList(),
      crystalSpent: json['crystal_spent'] ?? 0,
      crystalType: json['crystal_type'] ?? '',
    );
  }
}

class GachaItem {
  final String itemId;
  final String name;
  final String? description;
  final ItemType itemType;
  final ItemRarity rarity;
  final String? icon;
  final String? color;
  final bool isNew;

  GachaItem({
    required this.itemId,
    required this.name,
    this.description,
    required this.itemType,
    required this.rarity,
    this.icon,
    this.color,
    required this.isNew,
  });

  factory GachaItem.fromJson(Map<String, dynamic> json) {
    return GachaItem(
      itemId: json['item_id'],
      name: json['name'],
      description: json['description'],
      itemType: ItemType.values.firstWhere(
        (e) => e.toString().split('.').last == json['item_type'],
      ),
      rarity: ItemRarity.values.firstWhere(
        (e) => e.toString().split('.').last == json['rarity'],
      ),
      icon: json['icon'],
      color: json['color'],
      isNew: json['is_new'] ?? false,
    );
  }

  Item toItem() {
    return Item(
      id: itemId,
      name: name,
      description: description,
      itemType: itemType,
      rarity: rarity,
      iconName: icon,
      colorHex: color,
      effects: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}