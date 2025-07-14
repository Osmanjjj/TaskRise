import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/raid.dart';

class RaidBossWidget extends StatelessWidget {
  const RaidBossWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final activeRaidBoss = gameProvider.activeRaidBoss;
        final isRaidTimeActive = _isRaidTimeActive();

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
                      'レイドボス',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showRaidDetailsDialog(context, activeRaidBoss),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info,
                              size: 16,
                              color: Colors.red[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '詳細',
                              style: TextStyle(
                                color: Colors.red[600],
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

                if (activeRaidBoss == null)
                  _buildNoRaidBossMessage(context, isRaidTimeActive)
                else
                  _buildRaidBossCard(context, activeRaidBoss, isRaidTimeActive, gameProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoRaidBossMessage(BuildContext context, bool isRaidTimeActive) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              isRaidTimeActive ? Icons.schedule : Icons.nights_stay,
              size: 40,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              isRaidTimeActive
                  ? 'レイドボスは準備中です...'
                  : 'レイドバトル時間: 20:00 - 22:00',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (!isRaidTimeActive) ...[
              const SizedBox(height: 4),
              Text(
                '今日の習慣を完了してバトルポイントを貯めましょう！',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRaidBossCard(
    BuildContext context,
    RaidBoss raidBoss,
    bool isRaidTimeActive,
    GameProvider gameProvider,
  ) {
    final healthPercentage = (raidBoss.currentHealth / raidBoss.maxHealth * 100).clamp(0, 100);
    final timeRemaining = raidBoss.endTime?.difference(DateTime.now()) ?? const Duration(hours: 24);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getRaidBossColor(raidBoss.difficulty).withValues(alpha: 0.1),
            _getRaidBossColor(raidBoss.difficulty).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getRaidBossColor(raidBoss.difficulty).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getRaidBossColor(raidBoss.difficulty).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: _getRaidBossColor(raidBoss.difficulty),
                    width: 2,
                  ),
                ),
                child: Icon(
                  _getRaidBossIcon(raidBoss.type),
                  color: _getRaidBossColor(raidBoss.difficulty),
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      raidBoss.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getRaidBossColor(raidBoss.difficulty),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(raidBoss.difficulty).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _getDifficultyText(raidBoss.difficulty),
                        style: TextStyle(
                          fontSize: 10,
                          color: _getDifficultyColor(raidBoss.difficulty),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (timeRemaining.inHours > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${timeRemaining.inHours}h ${timeRemaining.inMinutes % 60}m',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Health Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'HP',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${raidBoss.currentHealth.toStringAsFixed(0)} / ${raidBoss.maxHealth.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: healthPercentage / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: healthPercentage > 50
                            ? [Colors.green, Colors.lightGreen]
                            : healthPercentage > 25
                                ? [Colors.orange, Colors.yellow]
                                : [Colors.red, Colors.redAccent],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${healthPercentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: healthPercentage > 50
                      ? Colors.green[700]
                      : healthPercentage > 25
                          ? Colors.orange[700]
                          : Colors.red[700],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),

          // Participants and Attack Button
          Row(
            children: [
              Icon(
                Icons.people,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                '参加者募集中',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              if (isRaidTimeActive && raidBoss.currentHealth > 0)
                ElevatedButton(
                  onPressed: () => _attackRaidBoss(context, raidBoss.id, gameProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getRaidBossColor(raidBoss.difficulty),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.whatshot, size: 16),
                      const SizedBox(width: 4),
                      const Text(
                        '攻撃',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                )
              else if (raidBoss.currentHealth <= 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '討伐完了',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'バトル時間外',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRaidDetailsDialog(BuildContext context, RaidBoss? raidBoss) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(raidBoss?.name ?? 'レイドボス'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (raidBoss != null) ...[
                Text(
                  '詳細情報',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailRow('タイプ', _getRaidBossTypeText(raidBoss.type)),
                _buildDetailRow('難易度', _getDifficultyText(raidBoss.difficulty)),
                _buildDetailRow('最大HP', raidBoss.maxHealth.toStringAsFixed(0)),
                _buildDetailRow('参加者', '募集中'),
                _buildDetailRow(
                  '開始時間',
                  '${raidBoss.createdAt.hour.toString().padLeft(2, '0')}:${raidBoss.createdAt.minute.toString().padLeft(2, '0')}',
                ),
                _buildDetailRow(
                  '終了時間',
                  raidBoss.endTime != null ? '${raidBoss.endTime!.hour.toString().padLeft(2, '0')}:${raidBoss.endTime!.minute.toString().padLeft(2, '0')}' : '未設定',
                ),
                const SizedBox(height: 16),
                Text(
                  '報酬',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '討伐成功時に特別な習慣の結晶と経験値を獲得！',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ] else ...[
                const Text('現在アクティブなレイドボスはありません。'),
                const SizedBox(height: 16),
                const Text(
                  'レイドバトルについて:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• 毎日20:00-22:00に開催\n'
                  '• 習慣完了でバトルポイントを獲得\n'
                  '• バトルポイントでレイドボスを攻撃\n'
                  '• 討伐成功で特別報酬を獲得',
                  style: TextStyle(fontSize: 12),
                ),
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
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _attackRaidBoss(BuildContext context, String raidBossId, GameProvider gameProvider) async {
    // TODO: Get actual character ID
    const characterId = 'sample-character-id';
    
    final success = await gameProvider.attackRaidBoss(characterId, raidBossId, 100); // Use 100 battle points
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('レイドボスを攻撃しました！'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('攻撃に失敗しました（バトルポイント不足の可能性があります）'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _isRaidTimeActive() {
    final now = DateTime.now();
    return now.hour >= 20 && now.hour < 22;
  }

  Color _getRaidBossColor(BossDifficulty difficulty) {
    switch (difficulty) {
      case BossDifficulty.easy:
        return Colors.green;
      case BossDifficulty.normal:
        return Colors.blue;
      case BossDifficulty.hard:
        return Colors.orange;
      case BossDifficulty.extreme:
        return Colors.red;
    }
  }

  Color _getDifficultyColor(BossDifficulty difficulty) {
    switch (difficulty) {
      case BossDifficulty.easy:
        return Colors.lightGreen;
      case BossDifficulty.normal:
        return Colors.green;
      case BossDifficulty.hard:
        return Colors.orange;
      case BossDifficulty.extreme:
        return Colors.red;
    }
  }

  String _getDifficultyText(BossDifficulty difficulty) {
    switch (difficulty) {
      case BossDifficulty.easy:
        return 'イージー';
      case BossDifficulty.normal:
        return 'ノーマル';
      case BossDifficulty.hard:
        return 'ハード';
      case BossDifficulty.extreme:
        return 'エクストリーム';
    }
  }

  IconData _getRaidBossIcon(BossType type) {
    switch (type) {
      case BossType.normal:
        return Icons.sentiment_neutral;
      case BossType.elite:
        return Icons.star;
      case BossType.legendary:
        return Icons.whatshot;
    }
  }

  String _getRaidBossTypeText(BossType type) {
    switch (type) {
      case BossType.normal:
        return 'ノーマル';
      case BossType.elite:
        return 'エリート';
      case BossType.legendary:
        return 'レジェンダリー';
    }
  }
}
