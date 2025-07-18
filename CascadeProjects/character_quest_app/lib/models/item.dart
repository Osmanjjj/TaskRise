import 'package:flutter/material.dart';

enum ItemRarity {
  common,
  rare,
  epic,
  legendary,
}

enum ItemType {
  avatar,
  decoration,
  skin,
  effect,
}

class Item {
  final String id;
  final String name;
  final String? description;
  final ItemType itemType;
  final ItemRarity rarity;
  final String? iconName;
  final String? colorHex;
  final String? imageUrl;
  final Map<String, dynamic>? effects;
  final DateTime createdAt;
  final DateTime updatedAt;

  Item({
    required this.id,
    required this.name,
    this.description,
    required this.itemType,
    required this.rarity,
    this.iconName,
    this.colorHex,
    this.imageUrl,
    this.effects,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      itemType: ItemType.values.firstWhere(
        (e) => e.toString().split('.').last == json['item_type'],
      ),
      rarity: ItemRarity.values.firstWhere(
        (e) => e.toString().split('.').last == json['rarity'],
      ),
      iconName: json['icon'],
      colorHex: json['color'],
      imageUrl: json['image_url'],
      effects: json['effects'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'item_type': itemType.toString().split('.').last,
      'rarity': rarity.toString().split('.').last,
      'icon': iconName,
      'color': colorHex,
      'image_url': imageUrl,
      'effects': effects,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  IconData get icon {
    if (iconName == null) return Icons.help_outline;
    
    // Map string names to IconData
    final iconMap = {
      'sports_martial_arts': Icons.sports_martial_arts,
      'person': Icons.person,
      'directions_walk': Icons.directions_walk,
      'radio_button_unchecked': Icons.radio_button_unchecked,
      'flash_on': Icons.flash_on,
      'auto_fix_high': Icons.auto_fix_high,
      'flight': Icons.flight,
      'stars': Icons.stars,
      'whatshot': Icons.whatshot,
      'ac_unit': Icons.ac_unit,
      'shield': Icons.shield,
      'bolt': Icons.bolt,
      'star': Icons.star,
      'local_fire_department': Icons.local_fire_department,
      'schedule': Icons.schedule,
      'psychology': Icons.psychology,
    };
    
    return iconMap[iconName] ?? Icons.help_outline;
  }

  Color get color {
    if (colorHex == null) return Colors.grey;
    
    try {
      return Color(int.parse(colorHex!.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  Color get rarityColor {
    switch (rarity) {
      case ItemRarity.legendary:
        return Colors.amber;
      case ItemRarity.epic:
        return Colors.purple;
      case ItemRarity.rare:
        return Colors.blue;
      case ItemRarity.common:
      default:
        return Colors.grey;
    }
  }

  String get rarityText {
    switch (rarity) {
      case ItemRarity.legendary:
        return 'LEGENDARY';
      case ItemRarity.epic:
        return 'EPIC';
      case ItemRarity.rare:
        return 'RARE';
      case ItemRarity.common:
      default:
        return 'COMMON';
    }
  }
}