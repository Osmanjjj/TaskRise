import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/inventory_item.dart';
import '../models/item.dart';
import '../services/gacha_service.dart';
import 'item_image_widget.dart';

class InventoryWidget extends StatefulWidget {
  final String characterId;
  final ItemType? filterType;
  final Function(InventoryItem)? onItemTap;

  const InventoryWidget({
    Key? key,
    required this.characterId,
    this.filterType,
    this.onItemTap,
  }) : super(key: key);

  @override
  State<InventoryWidget> createState() => _InventoryWidgetState();
}

class _InventoryWidgetState extends State<InventoryWidget> {
  final _gachaService = GachaService();
  List<InventoryItem> _inventory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  @override
  void didUpdateWidget(InventoryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.characterId != widget.characterId ||
        oldWidget.filterType != widget.filterType) {
      _loadInventory();
    }
  }

  Future<void> _loadInventory() async {
    setState(() {
      _isLoading = true;
    });

    final inventory = await _gachaService.getCharacterInventory(widget.characterId);
    
    final filteredInventory = widget.filterType != null
        ? inventory.where((item) => item.item?.itemType == widget.filterType).toList()
        : inventory;

    setState(() {
      _inventory = filteredInventory;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_inventory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'アイテムがありません',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ガチャを回してアイテムを獲得しましょう！',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/gacha');
              },
              icon: const Icon(Icons.casino),
              label: const Text('ガチャへ'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: _inventory.length,
      itemBuilder: (context, index) {
        final inventoryItem = _inventory[index];
        final item = inventoryItem.item;
        
        if (item == null) return const SizedBox();

        return GestureDetector(
          onTap: () {
            if (widget.onItemTap != null) {
              widget.onItemTap!(inventoryItem);
            } else {
              _showItemDetails(inventoryItem);
            }
          },
          child: Card(
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: item.rarityColor.withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Item image
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ItemImageWidget(
                            item: item,
                            size: double.infinity,
                            showRarityGlow: false,
                          ),
                        ),
                        if (inventoryItem.isNew)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        if (inventoryItem.quantity > 1)
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'x${inventoryItem.quantity}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        if (inventoryItem.isEquipped)
                          Positioned(
                            top: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: item.rarityColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.rarityText,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: item.rarityColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate(delay: (index * 50).ms)
            .fadeIn(duration: 300.ms)
            .scale(begin: const Offset(0.9, 0.9)),
        );
      },
    );
  }

  void _showItemDetails(InventoryItem inventoryItem) {
    final item = inventoryItem.item;
    if (item == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Column(
          children: [
            ItemImageWidget(
              item: item,
              size: 120,
              showRarityGlow: true,
            ),
            const SizedBox(height: 12),
            Text(
              item.name,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: item.rarityColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                item.rarityText,
                style: TextStyle(
                  color: item.rarityColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (item.description != null) ...[
              Text(
                item.description!,
                style: TextStyle(
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Icon(Icons.inventory, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '所持数: ${inventoryItem.quantity}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '取得日: ${_formatDate(inventoryItem.obtainedAt)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (!inventoryItem.isEquipped && item.itemType == ItemType.avatar)
            TextButton(
              onPressed: () async {
                final success = await _gachaService.toggleItemEquipped(
                  widget.characterId,
                  item.id,
                  true,
                );
                if (success) {
                  Navigator.of(context).pop();
                  _loadInventory();
                }
              },
              child: const Text('装備する'),
            ),
          if (inventoryItem.isEquipped)
            TextButton(
              onPressed: () async {
                final success = await _gachaService.toggleItemEquipped(
                  widget.characterId,
                  item.id,
                  false,
                );
                if (success) {
                  Navigator.of(context).pop();
                  _loadInventory();
                }
              },
              child: const Text('装備を外す'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );

    // Mark as viewed
    if (inventoryItem.isNew) {
      _gachaService.markItemsAsViewed(widget.characterId, [item.id]);
      // Reload to update the new badge
      Future.delayed(const Duration(milliseconds: 500), _loadInventory);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}