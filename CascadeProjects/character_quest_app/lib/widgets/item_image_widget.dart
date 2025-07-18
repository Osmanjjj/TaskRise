import 'package:flutter/material.dart';
import '../models/item.dart';
import 'item_placeholder_painter.dart';

class ItemImageWidget extends StatelessWidget {
  final Item item;
  final double size;
  final bool showRarityGlow;

  const ItemImageWidget({
    Key? key,
    required this.item,
    this.size = 80,
    this.showRarityGlow = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: showRarityGlow ? _getRarityGradient() : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(showRarityGlow ? 2 : 0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Theme.of(context).cardColor,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                // Background color based on rarity
                Container(
                  color: item.rarityColor.withOpacity(0.1),
                ),
                // Item image or custom painted placeholder
                Center(
                  child: SizedBox(
                    width: size * 0.9,
                    height: size * 0.9,
                    child: CustomPaint(
                      painter: ItemPlaceholderPainter(
                        item: item,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  ),
                ),
                // Rarity badge
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: item.rarityColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _getRarityAbbreviation(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconFallback() {
    return Icon(
      item.icon,
      size: size * 0.5,
      color: item.rarityColor,
    );
  }

  LinearGradient _getRarityGradient() {
    Color baseColor = item.rarityColor;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor.withOpacity(0.8),
        baseColor.withOpacity(0.4),
        baseColor.withOpacity(0.8),
      ],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  String _getRarityAbbreviation() {
    switch (item.rarity) {
      case ItemRarity.legendary:
        return 'L';
      case ItemRarity.epic:
        return 'E';
      case ItemRarity.rare:
        return 'R';
      case ItemRarity.common:
      default:
        return 'C';
    }
  }
}