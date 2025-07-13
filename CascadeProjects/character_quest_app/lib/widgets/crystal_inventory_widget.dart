import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class CrystalInventoryWidget extends StatelessWidget {
  const CrystalInventoryWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final crystals = gameProvider.crystals;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '習慣の結晶',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showGachaDialog(context, gameProvider),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.casino,
                              size: 16,
                              color: Colors.purple[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'ガチャ',
                              style: TextStyle(
                                color: Colors.purple[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildCrystalCount(
                        context,
                        'ブルー',
                        crystals['blue'] ?? 0,
                        Colors.blue,
                        Icons.diamond,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCrystalCount(
                        context,
                        'グリーン',
                        crystals['green'] ?? 0,
                        Colors.green,
                        Icons.diamond,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCrystalCount(
                        context,
                        'ゴールド',
                        crystals['gold'] ?? 0,
                        Colors.amber,
                        Icons.diamond,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCrystalCount(
                        context,
                        'レインボー',
                        crystals['rainbow'] ?? 0,
                        Colors.purple,
                        Icons.auto_awesome,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '習慣完了で結晶を獲得！ガチャで装備やアイテムを入手しよう',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCrystalCount(
    BuildContext context,
    String label,
    int count,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showGachaDialog(BuildContext context, GameProvider gameProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.casino, color: Colors.purple),
            SizedBox(width: 8),
            Text('習慣ガチャ'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('結晶を使ってアイテムを獲得しよう！'),
            const SizedBox(height: 16),
            _buildGachaOption(
              context,
              'ブルーガチャ',
              '1回',
              Colors.blue,
              () => _performGacha(context, gameProvider, 'blue', 1),
              gameProvider.totalBlueCrystals >= 1,
            ),
            const SizedBox(height: 8),
            _buildGachaOption(
              context,
              'グリーンガチャ',
              '5回',
              Colors.green,
              () => _performGacha(context, gameProvider, 'green', 1),
              gameProvider.totalGreenCrystals >= 1,
            ),
            const SizedBox(height: 8),
            _buildGachaOption(
              context,
              'ゴールドガチャ',
              '20回',
              Colors.amber,
              () => _performGacha(context, gameProvider, 'gold', 1),
              gameProvider.totalGoldCrystals >= 1,
            ),
            const SizedBox(height: 8),
            _buildGachaOption(
              context,
              'レインボーガチャ',
              '3回',
              Colors.purple,
              () => _performGacha(context, gameProvider, 'rainbow', 1),
              gameProvider.totalRainbowCrystals >= 1,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  Widget _buildGachaOption(
    BuildContext context,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
    bool enabled,
  ) {
    return Material(
      color: enabled ? color.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                Icons.diamond,
                color: enabled ? color : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: enabled ? color : Colors.grey,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: enabled ? color : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _performGacha(
    BuildContext context,
    GameProvider gameProvider,
    String crystalType,
    int amount,
  ) async {
    Navigator.of(context).pop(); // Close gacha dialog

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('ガチャ中...'),
          ],
        ),
      ),
    );

    try {
      final result = await gameProvider.useCrystalsForGacha(crystalType, amount);
      
      Navigator.of(context).pop(); // Close loading dialog

      if (result != null) {
        _showGachaResults(context, result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ガチャに失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('エラー: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showGachaResults(BuildContext context, Map<String, dynamic> result) {
    final items = result['items'] as List;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Colors.amber),
            SizedBox(width: 8),
            Text('ガチャ結果'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('おめでとうございます！'),
            const SizedBox(height: 16),
            ...items.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getRarityColor(item['rarity']).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getRarityColor(item['rarity']).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getItemIcon(item['type']),
                    color: _getRarityColor(item['rarity']),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: _getRarityColor(item['rarity']),
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Color _getRarityColor(String? rarity) {
    switch (rarity) {
      case 'legendary':
        return Colors.purple;
      case 'epic':
        return Colors.deepPurple;
      case 'rare':
        return Colors.blue;
      case 'uncommon':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getItemIcon(String? type) {
    switch (type) {
      case 'equipment':
        return Icons.shopping_bag;
      case 'booster':
        return Icons.speed;
      case 'consumable':
        return Icons.local_pharmacy;
      default:
        return Icons.inventory;
    }
  }
}
