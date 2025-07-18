import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/character_provider.dart';
import '../widgets/crystal_inventory_widget.dart';
import '../services/gacha_service.dart';
import '../services/crystal_service.dart';
import '../models/gacha_pool.dart';
import '../models/gacha_result.dart';
import '../models/item.dart';
import '../models/inventory_item.dart';
import '../widgets/inventory_widget.dart';
import '../widgets/item_image_widget.dart';

class GachaScreen extends StatefulWidget {
  const GachaScreen({super.key});

  @override
  State<GachaScreen> createState() => _GachaScreenState();
}

class _GachaScreenState extends State<GachaScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final _gachaService = GachaService();
  final _crystalService = CrystalService();
  bool _isSpinning = false;
  List<GachaPool> _gachaPools = [];
  Map<String, dynamic> _collection = {'owned_items': [], 'all_items': []};
  String? _characterId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGachaPools();
  }

  Future<void> _loadGachaPools() async {
    final pools = await _gachaService.getGachaPools();
    setState(() {
      _gachaPools = pools;
    });
  }

  Future<void> _loadCollection() async {
    if (_characterId != null) {
      final collection = await _gachaService.getCharacterCollection(_characterId!);
      setState(() {
        _collection = collection;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final characterProvider = context.watch<CharacterProvider>();
    final characterId = characterProvider.character?.id;
    
    if (characterId == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Update character ID and load collection if changed
    if (_characterId != characterId) {
      _characterId = characterId;
      _loadCollection();
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('ガチャ'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'ガチャ', icon: Icon(Icons.casino)),
            Tab(text: 'コレクション', icon: Icon(Icons.collections)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGachaTab(),
          _buildCollectionTab(),
        ],
      ),
    );
  }

  Widget _buildGachaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Crystal inventory at the top
          CrystalInventoryWidget(characterId: _characterId!),
          const SizedBox(height: 24),
          
          // Gacha machine visual
          _buildGachaMachine(),
          const SizedBox(height: 24),
          
          // Gacha options
          _buildGachaOptions(),
          const SizedBox(height: 24),
          
          // Drop rates info
          _buildDropRatesInfo(),
        ],
      ),
    );
  }

  Widget _buildGachaMachine() {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.purple.withValues(alpha: 0.1),
                    Colors.blue.withValues(alpha: 0.1),
                    Colors.pink.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: Colors.purple.withValues(alpha: 0.3),
                  width: 3,
                ),
              ),
              child: _isSpinning
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 6,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                      ),
                    )
                  : const Icon(
                      Icons.auto_awesome,
                      size: 80,
                      color: Colors.purple,
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              'マジッククリスタルガチャ',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            Text(
              '習慣の力で手に入れた結晶を使って、\n素敵なアイテムを獲得しよう！',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGachaOptions() {
    if (_gachaPools.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              'ガチャデータを読み込めませんでした',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'データベースの設定を確認してください',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ガチャを回す',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._gachaPools.map((pool) {
          Color color;
          IconData icon;
          switch (pool.crystalType) {
            case 'blue':
              color = Colors.blue;
              icon = Icons.diamond;
              break;
            case 'green':
              color = Colors.green;
              icon = Icons.diamond;
              break;
            case 'gold':
              color = Colors.amber;
              icon = Icons.diamond;
              break;
            case 'rainbow':
              color = Colors.pink;
              icon = Icons.auto_awesome;
              break;
            default:
              color = Colors.grey;
              icon = Icons.diamond;
          }

          final crystalName = {
            'blue': '青い結晶',
            'green': '緑の結晶',
            'gold': '金の結晶',
            'rainbow': 'レインボー結晶',
          }[pool.crystalType] ?? '結晶';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildGachaOptionCard(
              pool.name,
              '$crystalName x${pool.crystalCost}',
              pool.description ?? '',
              color,
              icon,
              pool.pullCount,
              () => _performGacha(pool),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildGachaOptionCard(
    String title,
    String cost,
    String description,
    Color color,
    IconData icon,
    int pulls,
    VoidCallback onPressed,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${pulls}回',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: color.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    cost,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _isSpinning ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                _isSpinning ? '...' : '回す',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropRatesInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '排出確率',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildRarityRow('コモン', '70%', Colors.grey),
            _buildRarityRow('レア', '25%', Colors.blue),
            _buildRarityRow('エピック', '4.5%', Colors.purple),
            _buildRarityRow('レジェンダリー', '0.5%', Colors.amber),
            const SizedBox(height: 8),
            Text(
              '※ レインボーガチャではレジェンダリー100%確定',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRarityRow(String rarity, String rate, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            rarity,
            style: const TextStyle(fontSize: 12),
          ),
          const Spacer(),
          Text(
            rate,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionTab() {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'すべて'),
              Tab(text: 'アバター'),
              Tab(text: '装飾品'),
              Tab(text: 'スキン'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                InventoryWidget(characterId: _characterId!),
                InventoryWidget(
                  characterId: _characterId!,
                  filterType: ItemType.avatar,
                ),
                InventoryWidget(
                  characterId: _characterId!,
                  filterType: ItemType.decoration,
                ),
                InventoryWidget(
                  characterId: _characterId!,
                  filterType: ItemType.skin,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  void _performGacha(GachaPool pool) async {
    if (_characterId == null) return;

    setState(() {
      _isSpinning = true;
    });

    try {
      final result = await _gachaService.performGacha(_characterId!, pool.id);
      
      setState(() {
        _isSpinning = false;
      });

      if (result == null || !result.success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result?.error ?? 'ガチャの実行に失敗しました'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Reload collection to reflect new items
      _loadCollection();

      // Show result dialog
      if (!mounted) return;
      _showGachaResult(result);
    } catch (e) {
      setState(() {
        _isSpinning = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('エラーが発生しました'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showGachaResult(GachaResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ガチャ結果',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                constraints: const BoxConstraints(maxHeight: 400),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: result.items.length,
                  itemBuilder: (context, index) {
                    final item = result.items[index];
                    final itemData = item.toItem();
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: ItemImageWidget(
                          item: itemData,
                          size: 48,
                          showRarityGlow: false,
                        ).animate(delay: (index * 100).ms)
                          .fadeIn(duration: 300.ms)
                          .scale(begin: const Offset(0.8, 0.8)),
                        title: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          itemData.rarityText,
                          style: TextStyle(
                            color: itemData.rarityColor,
                            fontSize: 12,
                          ),
                        ),
                        trailing: item.isNew
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'NEW',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Switch to collection tab to see new items
                  _tabController.animateTo(1);
                },
                child: const Text('コレクションを見る'),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
