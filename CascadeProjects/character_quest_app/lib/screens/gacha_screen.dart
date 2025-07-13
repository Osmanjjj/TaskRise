import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/character_provider.dart';
import '../widgets/crystal_inventory_widget.dart';

class GachaScreen extends StatefulWidget {
  const GachaScreen({Key? key}) : super(key: key);

  @override
  State<GachaScreen> createState() => _GachaScreenState();
}

class _GachaScreenState extends State<GachaScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isSpinning = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          const CrystalInventoryWidget(),
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
        _buildGachaOptionCard(
          '単発ガチャ',
          '青い結晶 x1',
          'シンプルな装飾品やアバターパーツが手に入る',
          Colors.blue,
          Icons.diamond,
          1,
          () => _performGacha(1, 'blue'),
        ),
        const SizedBox(height: 12),
        _buildGachaOptionCard(
          '5連ガチャ',
          '緑の結晶 x1',
          'レア装飾品やスキンが手に入りやすい',
          Colors.green,
          Icons.diamond,
          5,
          () => _performGacha(5, 'green'),
        ),
        const SizedBox(height: 12),
        _buildGachaOptionCard(
          '20連ガチャ',
          '金の結晶 x1',
          'エピック装飾品が1つ以上確定！',
          Colors.amber,
          Icons.diamond,
          20,
          () => _performGacha(20, 'gold'),
        ),
        const SizedBox(height: 12),
        _buildGachaOptionCard(
          'レインボーガチャ',
          'レインボー結晶 x1',
          'レジェンダリーアイテムが確定！',
          Colors.pink,
          Icons.auto_awesome,
          1,
          () => _performGacha(1, 'rainbow'),
        ),
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
                _buildCollectionGrid(_getAllItems()),
                _buildCollectionGrid(_getAvatarItems()),
                _buildCollectionGrid(_getDecorationItems()),
                _buildCollectionGrid(_getSkinItems()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionGrid(List<_CollectionItem> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildCollectionItemCard(item);
      },
    );
  }

  Widget _buildCollectionItemCard(_CollectionItem item) {
    return Card(
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: item.rarity == 'legendary'
                    ? Colors.amber.withValues(alpha: 0.1)
                    : item.rarity == 'epic'
                        ? Colors.purple.withValues(alpha: 0.1)
                        : item.rarity == 'rare'
                            ? Colors.blue.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      item.icon,
                      size: 40,
                      color: item.owned
                          ? (item.rarity == 'legendary'
                              ? Colors.amber
                              : item.rarity == 'epic'
                                  ? Colors.purple
                                  : item.rarity == 'rare'
                                      ? Colors.blue
                                      : Colors.grey[600])
                          : Colors.grey[400],
                    ),
                  ),
                  if (!item.owned)
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.black.withValues(alpha: 0.6),
                      child: const Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  if (item.isNew)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
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
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: item.owned ? null : Colors.grey[500],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: (item.rarity == 'legendary'
                            ? Colors.amber
                            : item.rarity == 'epic'
                                ? Colors.purple
                                : item.rarity == 'rare'
                                    ? Colors.blue
                                    : Colors.grey)
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.rarity.toUpperCase(),
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: item.rarity == 'legendary'
                          ? Colors.amber[700]
                          : item.rarity == 'epic'
                              ? Colors.purple[700]
                              : item.rarity == 'rare'
                                  ? Colors.blue[700]
                                  : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_CollectionItem> _getAllItems() {
    return [
      _CollectionItem('クリスタルクラウン', 'avatar', 'legendary', Icons.diamond, true, true),
      _CollectionItem('ファイアブレード', 'decoration', 'epic', Icons.whatshot, true, false),
      _CollectionItem('ミスティックローブ', 'avatar', 'rare', Icons.checkroom, false, false),
      _CollectionItem('シャドウマスク', 'avatar', 'rare', Icons.masks, true, false),
      _CollectionItem('ライトニングスタッフ', 'decoration', 'epic', Icons.flash_on, false, false),
      _CollectionItem('フラワーリング', 'decoration', 'common', Icons.local_florist, true, false),
    ];
  }

  List<_CollectionItem> _getAvatarItems() {
    return _getAllItems().where((item) => item.type == 'avatar').toList();
  }

  List<_CollectionItem> _getDecorationItems() {
    return _getAllItems().where((item) => item.type == 'decoration').toList();
  }

  List<_CollectionItem> _getSkinItems() {
    return []; // Empty for now
  }

  void _performGacha(int pulls, String crystalType) async {
    setState(() {
      _isSpinning = true;
    });

    // Simulate gacha spinning
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isSpinning = false;
    });

    // Show result dialog
    _showGachaResult(pulls, crystalType);
  }

  void _showGachaResult(int pulls, String crystalType) {
    final results = _generateGachaResults(pulls, crystalType);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ガチャ結果 (${pulls}回)'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              return ListTile(
                leading: Icon(
                  result.icon,
                  color: result.rarity == 'legendary'
                      ? Colors.amber
                      : result.rarity == 'epic'
                          ? Colors.purple
                          : result.rarity == 'rare'
                              ? Colors.blue
                              : Colors.grey[600],
                ),
                title: Text(result.name),
                subtitle: Text(result.rarity.toUpperCase()),
                trailing: result.isNew
                    ? Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
              );
            },
          ),
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

  List<_CollectionItem> _generateGachaResults(int pulls, String crystalType) {
    // Mock gacha results
    return List.generate(pulls, (index) {
      return _CollectionItem(
        'ガチャアイテム${index + 1}',
        'decoration',
        crystalType == 'rainbow' ? 'legendary' : 'common',
        Icons.star,
        false,
        true,
      );
    });
  }
}

class _CollectionItem {
  final String name;
  final String type;
  final String rarity;
  final IconData icon;
  final bool owned;
  final bool isNew;

  _CollectionItem(
    this.name,
    this.type,
    this.rarity,
    this.icon,
    this.owned,
    this.isNew,
  );
}
