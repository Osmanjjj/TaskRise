import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/crystal.dart';
import '../services/crystal_service.dart';

class CrystalInventoryWidget extends StatelessWidget {
  final String characterId;
  final VoidCallback? onTap;

  const CrystalInventoryWidget({
    super.key,
    required this.characterId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final crystalService = CrystalService();
    
    return StreamBuilder<CrystalInventory?>(
      stream: crystalService.watchCrystalInventory(characterId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // 初回読み込み時も既存のデータがあればそれを表示
          return FutureBuilder<CrystalInventory?>(
            future: crystalService.getCrystalInventory(characterId),
            builder: (context, futureSnapshot) {
              if (futureSnapshot.hasData && futureSnapshot.data != null) {
                return _buildContent(context, futureSnapshot.data!);
              }
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          );
        }
        
        if (snapshot.hasError) {
          print('Error watching crystal inventory: ${snapshot.error}');
          return const SizedBox.shrink();
        }
        
        final inventory = snapshot.data;
        if (inventory == null) {
          return const SizedBox.shrink();
        }
        
        return _buildContent(context, inventory);
      },
    );
  }
  
  Widget _buildContent(BuildContext context, CrystalInventory inventory) {

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '結晶の在庫',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${inventory.getTotalCrystals()} / ${inventory.storageLimit}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: inventory.getTotalCrystals() >= inventory.storageLimit
                            ? Colors.red
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.casino),
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      tooltip: 'ガチャを回す',
                      onPressed: () {
                        Navigator.pushNamed(context, '/gacha');
                      },
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: CrystalType.values.map((type) {
                final count = inventory.getCrystalCount(type);
                return _buildCrystalItem(context, type, count);
              }).toList(),
            ),
            if (inventory.conversionRateBonus > 1.0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '変換率ボーナス: x${inventory.conversionRateBonus.toStringAsFixed(1)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ).animate().fadeIn(duration: 300.ms).scale(
        begin: const Offset(0.95, 0.95),
        end: const Offset(1, 1),
        duration: 300.ms,
      ),
    );
  }

  Widget _buildCrystalItem(BuildContext context, CrystalType type, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: type.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: type.color.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            type.icon,
            size: 16,
            color: type.color,
          ).animate(
            onPlay: (controller) => controller.repeat(),
          ).shimmer(
            duration: 2000.ms,
            color: type.color.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 6),
          Text(
            count.toString(),
            style: TextStyle(
              color: type.color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// Crystal detail dialog
class CrystalDetailDialog extends StatelessWidget {
  final CrystalInventory inventory;

  const CrystalDetailDialog({
    super.key,
    required this.inventory,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.diamond,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          const Text('結晶の詳細'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...CrystalType.values.map((type) => _buildDetailRow(
              context,
              type,
              inventory.getCrystalCount(type),
            )),
            const Divider(height: 24),
            _buildStorageInfo(context),
            if (inventory.conversionRateBonus > 1.0) ...[
              const SizedBox(height: 8),
              _buildBonusInfo(context),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, CrystalType type, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            type.icon,
            color: type.color,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  type.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: type.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: type.color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageInfo(BuildContext context) {
    final used = inventory.getTotalCrystals();
    final limit = inventory.storageLimit;
    final percentage = (used / limit * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '保管容量',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              '$used / $limit ($percentage%)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: percentage >= 90 ? Colors.red : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: used / limit,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          color: percentage >= 90 
              ? Colors.red 
              : percentage >= 70 
                  ? Colors.orange 
                  : Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildBonusInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.trending_up,
            color: Colors.green,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '変換率ボーナス: x${inventory.conversionRateBonus.toStringAsFixed(1)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}