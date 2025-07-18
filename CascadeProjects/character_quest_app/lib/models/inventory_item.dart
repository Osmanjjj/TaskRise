import 'item.dart';

class InventoryItem {
  final String id;
  final String characterId;
  final String itemId;
  final int quantity;
  final DateTime obtainedAt;
  final bool isNew;
  final bool isEquipped;
  final Item? item;

  InventoryItem({
    required this.id,
    required this.characterId,
    required this.itemId,
    required this.quantity,
    required this.obtainedAt,
    required this.isNew,
    required this.isEquipped,
    this.item,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'],
      characterId: json['character_id'],
      itemId: json['item_id'],
      quantity: json['quantity'],
      obtainedAt: DateTime.parse(json['obtained_at']),
      isNew: json['is_new'] ?? false,
      isEquipped: json['is_equipped'] ?? false,
      item: json['item'] != null ? Item.fromJson(json['item']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'character_id': characterId,
      'item_id': itemId,
      'quantity': quantity,
      'obtained_at': obtainedAt.toIso8601String(),
      'is_new': isNew,
      'is_equipped': isEquipped,
      if (item != null) 'item': item!.toJson(),
    };
  }
}