import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/character_provider.dart';
import '../models/mentor.dart';

class MentorStatusWidget extends StatelessWidget {
  const MentorStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CharacterProvider>(
      builder: (context, characterProvider, child) {
        final hasMentor = characterProvider.hasMentor;
        final isMentor = characterProvider.isMentor;
        final mentorships = characterProvider.mentorships;
        final mentorStats = characterProvider.mentorStats;

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
                      'メンター',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showMentorDialog(context, characterProvider),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people,
                              size: 16,
                              color: Colors.blue[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '管理',
                              style: TextStyle(
                                color: Colors.blue[600],
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

                if (!hasMentor && !isMentor)
                  _buildNoMentorStatus(context, characterProvider)
                else ...[
                  if (hasMentor) ...[
                    _buildMenteeStatus(context, mentorships),
                    if (isMentor) const SizedBox(height: 12),
                  ],
                  if (isMentor) _buildMentorStatus(context, mentorStats),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoMentorStatus(BuildContext context, CharacterProvider characterProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            Icons.school,
            size: 40,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'メンターシップを始めませんか？',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '経験豊富なメンターから指導を受けたり、\n他のプレイヤーをサポートしたりできます',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _findMentor(context, characterProvider),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text(
                    'メンターを探す',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: characterProvider.character != null && 
                           characterProvider.character!.level >= 15
                      ? () => _becomeMentor(context, characterProvider)
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text(
                    'メンターになる',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenteeStatus(BuildContext context, List<MentorRelationship> mentorships) {
    final activeMentorship = mentorships
        .firstWhere((m) => m.status == MentorshipStatus.active, orElse: () => mentorships.first);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.school,
                color: Colors.green[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'メンター指導中',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.green[100],
                child: Text(
                  'M',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'メンター名', // TODO: Get actual mentor name
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '進捗: ${activeMentorship.menteeProgressBonus}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(activeMentorship.status).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(activeMentorship.status),
                  style: TextStyle(
                    fontSize: 10,
                    color: _getStatusColor(activeMentorship.status),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMentorStatus(BuildContext context, MentorStats? mentorStats) {
    if (mentorStats == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology,
                color: Colors.blue[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'メンター活動',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getMentorRankColor(mentorStats.mentorRank).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'ランク ${mentorStats.mentorRank}',
                  style: TextStyle(
                    fontSize: 10,
                    color: _getMentorRankColor(mentorStats.mentorRank),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMentorStatItem(
                  '現在指導中',
                  mentorStats.activeMentees.toString(),
                  Icons.people,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMentorStatItem(
                  '完了',
                  mentorStats.completedMentorships.toString(),
                  Icons.check_circle,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMentorStatItem(
                  '報酬',
                  mentorStats.totalRewardsEarned.toString(),
                  Icons.star,
                  Colors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMentorStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showMentorDialog(BuildContext context, CharacterProvider characterProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メンターシップ'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (characterProvider.hasMentor || characterProvider.isMentor) ...[
                const Text('現在の状況:'),
                const SizedBox(height: 8),
                ...characterProvider.mentorships.map((dynamic mentorship) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        (mentorship as dynamic).mentorId == characterProvider.character?.id
                            ? Icons.psychology
                            : Icons.school,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          (mentorship as dynamic).mentorId == characterProvider.character?.id
                              ? 'メンティー指導中'
                              : 'メンター指導中',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Text(
                        _getStatusText((mentorship as dynamic).status),
                        style: TextStyle(
                          fontSize: 10,
                          color: _getStatusColor((mentorship as dynamic).status),
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
              ],
              const Text('利用可能なアクション:'),
              const SizedBox(height: 8),
              if (!characterProvider.hasMentor)
                _buildActionButton(
                  context,
                  'メンターを探す',
                  Icons.search,
                  Colors.green,
                  () => _findMentor(context, characterProvider),
                ),
              if (characterProvider.character != null && 
                  characterProvider.character!.level >= 15 &&
                  !characterProvider.isMentor)
                _buildActionButton(
                  context,
                  'メンターになる',
                  Icons.psychology,
                  Colors.blue,
                  () => _becomeMentor(context, characterProvider),
                ),
              if (characterProvider.isMentor)
                _buildActionButton(
                  context,
                  'リーダーボードを見る',
                  Icons.leaderboard,
                  Colors.purple,
                  () => _showLeaderboard(context),
                ),
            ],
          ),
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

  Widget _buildActionButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {
            Navigator.of(context).pop();
            onTap();
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  color: color,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _findMentor(BuildContext context, CharacterProvider characterProvider) {
    // TODO: Navigate to mentor search screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('メンター検索画面への移動機能は開発中です'),
      ),
    );
  }

  void _becomeMentor(BuildContext context, CharacterProvider characterProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メンターになる'),
        content: const Text(
          'メンターになると、他のプレイヤーを指導し、報酬を獲得できます。\n'
          'メンターになりますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement mentor registration
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('メンター登録機能は開発中です'),
                ),
              );
            },
            child: const Text('メンターになる'),
          ),
        ],
      ),
    );
  }

  void _showLeaderboard(BuildContext context) {
    // TODO: Navigate to mentor leaderboard screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('メンターリーダーボード画面への移動機能は開発中です'),
      ),
    );
  }

  Color _getStatusColor(MentorshipStatus status) {
    switch (status) {
      case MentorshipStatus.pending:
        return Colors.orange;
      case MentorshipStatus.active:
        return Colors.green;
      case MentorshipStatus.completed:
        return Colors.blue;
      case MentorshipStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(MentorshipStatus status) {
    switch (status) {
      case MentorshipStatus.pending:
        return '承認待ち';
      case MentorshipStatus.active:
        return '指導中';
      case MentorshipStatus.completed:
        return '完了';
      case MentorshipStatus.cancelled:
        return 'キャンセル';
    }
  }

  Color _getMentorRankColor(int rank) {
    switch (rank) {
      case 5:
        return Colors.purple;
      case 4:
        return Colors.deepPurple;
      case 3:
        return Colors.blue;
      case 2:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
