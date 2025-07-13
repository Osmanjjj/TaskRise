import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/character_provider.dart';
import '../widgets/mentor_status_widget.dart';

class MentorScreen extends StatefulWidget {
  const MentorScreen({Key? key}) : super(key: key);

  @override
  State<MentorScreen> createState() => _MentorScreenState();
}

class _MentorScreenState extends State<MentorScreen> with TickerProviderStateMixin {
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
        title: const Text('メンター'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'ホーム', icon: Icon(Icons.home)),
            Tab(text: 'メンター検索', icon: Icon(Icons.search)),
            Tab(text: 'ランキング', icon: Icon(Icons.leaderboard)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHomeTab(),
          _buildMentorSearchTab(),
          _buildRankingTab(),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mentor status widget
          const MentorStatusWidget(),
          const SizedBox(height: 24),
          
          // My mentorships section
          _buildMyMentorshipsSection(),
          const SizedBox(height: 24),
          
          // Mentor benefits section
          _buildMentorBenefitsSection(),
        ],
      ),
    );
  }

  Widget _buildMyMentorshipsSection() {
    return Consumer<CharacterProvider>(
      builder: (context, characterProvider, child) {
        // Mock data - replace with actual data from provider
        final mentorships = [
          _MentorshipData('初心者A', 'メンティー', 45, 'active'),
          _MentorshipData('初心者B', 'メンティー', 23, 'active'),
        ];
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'マイメンターシップ',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (mentorships.isEmpty)
              _buildEmptyMentorshipState()
            else
              ...mentorships.map((mentorship) => _buildMentorshipCard(mentorship)),
          ],
        );
      },
    );
  }

  Widget _buildEmptyMentorshipState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              Icons.person_search,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'アクティブなメンターシップがありません',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'メンターになったり、メンターを見つけて\n習慣作りの旅を始めましょう！',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(1),
              child: const Text('メンターを探す'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMentorshipCard(_MentorshipData mentorship) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: mentorship.role == 'メンター' 
                  ? Colors.purple.withValues(alpha: 0.2)
                  : Colors.blue.withValues(alpha: 0.2),
              child: Icon(
                mentorship.role == 'メンター' ? Icons.school : Icons.person,
                color: mentorship.role == 'メンター' ? Colors.purple : Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mentorship.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    mentorship.role,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: mentorship.progress / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      mentorship.role == 'メンター' ? Colors.purple : Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  '${mentorship.progress}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '進捗',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: () => _showMentorshipDetails(mentorship),
              icon: const Icon(Icons.info_outline),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMentorBenefitsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star,
                  color: Colors.amber[600],
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'メンター特典',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildBenefitRow(Icons.diamond, '結晶ボーナス', 'メンティーの成長に応じて追加結晶獲得'),
            _buildBenefitRow(Icons.trending_up, '経験値ボーナス', '指導により自分も経験値アップ'),
            _buildBenefitRow(Icons.emoji_events, '特別称号', 'メンター実績に応じた称号を獲得'),
            _buildBenefitRow(Icons.group, 'コミュニティ', 'メンター限定のコミュニティ参加'),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.amber[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMentorSearchTab() {
    return Column(
      children: [
        // Search filters
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'メンターを検索...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    // TODO: Implement search
                  },
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list),
                onSelected: (value) {
                  // TODO: Implement filter
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'experience',
                    child: Text('経験豊富'),
                  ),
                  const PopupMenuItem(
                    value: 'rating',
                    child: Text('高評価'),
                  ),
                  const PopupMenuItem(
                    value: 'category',
                    child: Text('カテゴリー'),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Mentor list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: _getMockMentors().length,
            itemBuilder: (context, index) {
              final mentor = _getMockMentors()[index];
              return _buildMentorCard(mentor);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMentorCard(_MentorData mentor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.purple.withValues(alpha: 0.2),
                  child: Text(
                    mentor.name.substring(0, 1),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            mentor.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Lv.${mentor.level}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.amber[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.amber[600],
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${mentor.rating}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${mentor.mentees}人指導',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _requestMentorship(mentor),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('依頼', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              mentor.introduction,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: mentor.specialties.map((specialty) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  specialty,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue[700],
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'メンターランキング',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '今月の優秀なメンター',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          
          // Top 3 mentors
          _buildTopMentorsSection(),
          const SizedBox(height: 24),
          
          // Other mentors ranking
          _buildMentorRankingList(),
        ],
      ),
    );
  }

  Widget _buildTopMentorsSection() {
    final topMentors = [
      _MentorRanking('スーパーメンター', 4.9, 156, 1),
      _MentorRanking('習慣マスター', 4.8, 134, 2),
      _MentorRanking('ライフコーチ', 4.7, 128, 3),
    ];

    return Row(
      children: topMentors.map((mentor) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: mentor.rank == 1 ? 0 : 4,
            ),
            child: _buildTopMentorCard(mentor),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopMentorCard(_MentorRanking mentor) {
    final colors = [Colors.amber, Colors.grey[600]!, Colors.brown];
    final color = colors[mentor.rank - 1];

    return Card(
      elevation: mentor.rank == 1 ? 8 : 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  mentor.rank.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mentor.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: mentor.rank == 1 ? 14 : 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star,
                  color: color,
                  size: 12,
                ),
                const SizedBox(width: 2),
                Text(
                  '${mentor.rating}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
            Text(
              '${mentor.mentees}人',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMentorRankingList() {
    final rankings = List.generate(10, (index) {
      return _MentorRanking(
        'メンター${index + 4}',
        4.6 - (index * 0.1),
        120 - (index * 5),
        index + 4,
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'その他のランキング',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...rankings.map((mentor) => _buildRankingListItem(mentor)),
      ],
    );
  }

  Widget _buildRankingListItem(_MentorRanking mentor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withValues(alpha: 0.2),
          child: Text(
            mentor.rank.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        title: Text(
          mentor.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text('${mentor.mentees}人指導'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star,
              color: Colors.amber[600],
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '${mentor.rating}',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_MentorData> _getMockMentors() {
    return [
      _MentorData(
        'ヘルスコーチ田中',
        25,
        4.8,
        45,
        '運動と食事の習慣化をサポートします。3年間で100人以上の方をサポートしてきました。',
        ['健康', '運動', '食事'],
      ),
      _MentorData(
        '読書王佐藤',
        18,
        4.7,
        32,
        '読書習慣を身につけたい方を応援します。月20冊読む習慣を一緒に作りましょう。',
        ['読書', '学習', '自己啓発'],
      ),
      _MentorData(
        '早起き達人鈴木',
        22,
        4.9,
        28,
        '朝活習慣で人生を変えませんか？5時起きを5年続けている経験をシェアします。',
        ['早起き', '朝活', '時間管理'],
      ),
    ];
  }

  void _showMentorshipDetails(_MentorshipData mentorship) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${mentorship.name}との関係'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('役割: ${mentorship.role}'),
            const SizedBox(height: 8),
            Text('進捗: ${mentorship.progress}%'),
            const SizedBox(height: 8),
            Text('ステータス: ${mentorship.status}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  void _requestMentorship(_MentorData mentor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${mentor.name}にメンター依頼'),
        content: const Text('メンターシップを依頼しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${mentor.name}にメンター依頼を送信しました'),
                ),
              );
            },
            child: const Text('依頼する'),
          ),
        ],
      ),
    );
  }
}

class _MentorshipData {
  final String name;
  final String role;
  final int progress;
  final String status;

  _MentorshipData(this.name, this.role, this.progress, this.status);
}

class _MentorData {
  final String name;
  final int level;
  final double rating;
  final int mentees;
  final String introduction;
  final List<String> specialties;

  _MentorData(
    this.name,
    this.level,
    this.rating,
    this.mentees,
    this.introduction,
    this.specialties,
  );
}

class _MentorRanking {
  final String name;
  final double rating;
  final int mentees;
  final int rank;

  _MentorRanking(this.name, this.rating, this.mentees, this.rank);
}
