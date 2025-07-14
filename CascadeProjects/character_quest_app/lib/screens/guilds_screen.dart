import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/character_provider.dart';

class GuildsScreen extends StatefulWidget {
  const GuildsScreen({super.key});

  @override
  State<GuildsScreen> createState() => _GuildsScreenState();
}

class _GuildsScreenState extends State<GuildsScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('ギルド'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'マイギルド', icon: Icon(Icons.home)),
            Tab(text: '参加可能', icon: Icon(Icons.search)),
            Tab(text: 'ランキング', icon: Icon(Icons.leaderboard)),
          ],
        ),
        actions: [
          Consumer<CharacterProvider>(
            builder: (context, characterProvider, child) {
              final canCreateGuild = characterProvider.subscriptionBenefits?.canCreateFixedGuild ?? false;
              
              return IconButton(
                onPressed: canCreateGuild 
                    ? () => _showCreateGuildDialog(context)
                    : () => _showPremiumRequiredDialog(context),
                icon: const Icon(Icons.add),
                tooltip: 'ギルドを作成',
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyGuildTab(),
          _buildAvailableGuildsTab(),
          _buildGuildRankingTab(),
        ],
      ),
    );
  }

  Widget _buildMyGuildTab() {
    return Consumer<CharacterProvider>(
      builder: (context, characterProvider, child) {
        // TODO: Get guild membership status from provider
        // For now, always show no guild state
        return _buildNoGuildState();
      },
    );
  }

  Widget _buildNoGuildState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Icon(
            Icons.groups_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'ギルドに参加していません',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'ギルドに参加して、仲間と一緒に習慣を育てましょう！\nギルドクエストや特別な報酬を獲得できます。',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildGuildTypeCard(
            'フリーギルド',
            '無料で参加できる週替わりギルド',
            '• 毎週新しいメンバーとクエスト\n• 基本的な報酬を獲得\n• 気軽に参加可能',
            Colors.blue,
            Icons.people,
            () => _joinFreeGuild(context),
          ),
          const SizedBox(height: 16),
          _buildGuildTypeCard(
            '固定ギルド',
            '継続的な関係を築けるプレミアムギルド',
            '• 固定メンバーで長期間活動\n• 特別な報酬とボーナス\n• プレミアム機能（¥300/月）',
            Colors.purple,
            Icons.workspace_premium,
            () => _showPremiumGuildInfo(context),
          ),
        ],
      ),
    );
  }

  Widget _buildGuildTypeCard(
    String title,
    String subtitle,
    String features,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  features,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // TODO: Implement when guild membership is available
  // Widget _buildGuildDetailsView() {
  //   return SingleChildScrollView(
  //     padding: const EdgeInsets.all(16.0),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         _buildGuildHeader(),
  //         const SizedBox(height: 24),
  //         _buildGuildQuests(),
  //         const SizedBox(height: 24),
  //         _buildGuildMembers(),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildGuildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(
                    Icons.shield,
                    color: Colors.purple,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'サンプルギルド',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'レベル 5 • メンバー 12/20',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'プレミアム',
                    style: TextStyle(
                      color: Colors.amber[800],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '一緒に習慣を育てて、最高のギルドを目指しましょう！',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuildQuests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ギルドクエスト',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.assignment,
                      color: Colors.green[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ウィークリークエスト: 習慣マスター',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'ギルドメンバー全員で今週中に100個の習慣を完了させよう！',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: 0.67,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '67/100',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.green[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuildMembers() {
    final members = [
      _GuildMember('リーダー', 'Lv.25', true, 850),
      _GuildMember('メンバー1', 'Lv.18', false, 620),
      _GuildMember('メンバー2', 'Lv.22', false, 590),
      _GuildMember('あなた', 'Lv.12', false, 450),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ギルドメンバー',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: members.map((member) => ListTile(
              leading: CircleAvatar(
                backgroundColor: member.isLeader ? Colors.amber.withValues(alpha: 0.2) : Colors.blue.withValues(alpha: 0.2),
                child: Icon(
                  member.isLeader ? Icons.star : Icons.person,
                  color: member.isLeader ? Colors.amber[700] : Colors.blue[700],
                  size: 20,
                ),
              ),
              title: Text(
                member.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(member.level),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${member.weeklyScore}pt',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '今週',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableGuildsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '参加可能なギルド',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildAvailableGuildCard('フリーギルド A', '週替わり', 15, 20, false),
          _buildAvailableGuildCard('フリーギルド B', '週替わり', 8, 20, false),
          _buildAvailableGuildCard('プレミアムギルド', '固定メンバー', 12, 15, true),
        ],
      ),
    );
  }

  Widget _buildAvailableGuildCard(String name, String type, int members, int maxMembers, bool isPremium) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPremium ? Icons.workspace_premium : Icons.people,
                  color: isPremium ? Colors.purple : Colors.blue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$type • $members/$maxMembers メンバー',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: isPremium && !(context.read<CharacterProvider>().subscriptionBenefits?.canCreateFixedGuild ?? false)
                      ? null
                      : () => _joinGuild(context, name),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPremium ? Colors.purple : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('参加', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuildRankingTab() {
    final rankings = [
      _GuildRanking('ドラゴンギルド', 12500, 1),
      _GuildRanking('フェニックス団', 11800, 2),
      _GuildRanking('スターライト', 10950, 3),
      _GuildRanking('サンプルギルド', 8750, 7),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ギルドランキング',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '今週のギルド活動ポイントランキング',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ...rankings.map((guild) => _buildRankingCard(guild)),
        ],
      ),
    );
  }

  Widget _buildRankingCard(_GuildRanking guild) {
    final isMyGuild = guild.name == 'サンプルギルド';
    
    return Card(
      color: isMyGuild ? Colors.blue.withValues(alpha: 0.05) : null,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _getRankColor(guild.rank),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  guild.rank.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    guild.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isMyGuild ? Colors.blue[700] : null,
                    ),
                  ),
                  if (isMyGuild)
                    Text(
                      'あなたのギルド',
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '${guild.score} pt',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getRankColor(guild.rank),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey[600]!;
      case 3:
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }

  void _showCreateGuildDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ギルドを作成'),
        content: const Text('ギルド作成機能は開発中です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPremiumRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プレミアム機能'),
        content: const Text('ギルドの作成にはギルドプラン（¥300/月）への加入が必要です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Navigate to subscription screen
            },
            child: const Text('プランを見る'),
          ),
        ],
      ),
    );
  }

  void _showPremiumGuildInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('固定ギルド'),
        content: const Text(
          '固定ギルドは継続的なメンバーシップで、長期間同じメンバーと活動できます。\n\n'
          '特典:\n'
          '• 専用のギルドハウス\n'
          '• 特別なクエストと報酬\n'
          '• メンバー限定のコミュニケーション機能\n\n'
          'ギルドプラン（¥300/月）への加入が必要です。'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Navigate to subscription screen
            },
            child: const Text('プランを見る'),
          ),
        ],
      ),
    );
  }

  void _joinFreeGuild(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('フリーギルド参加機能は開発中です'),
      ),
    );
  }

  void _joinGuild(BuildContext context, String guildName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$guildNameへの参加機能は開発中です'),
      ),
    );
  }
}

class _GuildMember {
  final String name;
  final String level;
  final bool isLeader;
  final int weeklyScore;

  _GuildMember(this.name, this.level, this.isLeader, this.weeklyScore);
}

class _GuildRanking {
  final String name;
  final int score;
  final int rank;

  _GuildRanking(this.name, this.score, this.rank);
}
