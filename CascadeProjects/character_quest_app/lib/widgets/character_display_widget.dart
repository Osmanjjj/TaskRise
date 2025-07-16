import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/character_provider.dart';
import '../models/character.dart';

class CharacterDisplayWidget extends StatefulWidget {
  const CharacterDisplayWidget({super.key});

  @override
  State<CharacterDisplayWidget> createState() => _CharacterDisplayWidgetState();
}

class _CharacterDisplayWidgetState extends State<CharacterDisplayWidget>
    with TickerProviderStateMixin {

  late AnimationController _expAnimationController;
  late Animation<double> _expAnimation;
  double _previousProgress = 0.0;
  double _currentAnimatedProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _expAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _expAnimation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _expAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _expAnimation.addListener(() {
      setState(() {
        _currentAnimatedProgress = _expAnimation.value;
      });
    });
  }

  @override
  void dispose() {
    _expAnimationController.dispose();
    super.dispose();
  }

  void _updateExpProgress(double newProgress) {
    print('_updateExpProgress called: previous=$_previousProgress, new=$newProgress');
    
    // 初回の場合は即座に設定
    if (_previousProgress == 0.0 && newProgress > 0.0) {
      print('Setting initial EXP progress: $newProgress');
      setState(() {
        _currentAnimatedProgress = newProgress;
        _previousProgress = newProgress;
      });
      return;
    }
    
    // 経験値が変化した場合（増加・減少問わず）
    if ((newProgress - _previousProgress).abs() > 0.001) {
      print('Animating EXP progress: $_previousProgress → $newProgress');
      
      // アニメーションをよりダイナミックに
      _expAnimation = Tween<double>(
        begin: _currentAnimatedProgress,
        end: newProgress,
      ).animate(CurvedAnimation(
        parent: _expAnimationController,
        curve: Curves.elasticOut, // よりダイナミックなカーブ
      ));
      
      _expAnimationController.reset();
      _expAnimationController.forward();
      _previousProgress = newProgress;
      
      // EXP獲得時の特別なエフェクト
      _showExpGainEffect();
    } else {
      print('No significant change in EXP progress');
    }
  }
  
  void _showExpGainEffect() {
    // バイブレーションやサウンドなどのエフェクトを追加できる
    print('🎆 EXP獲得エフェクト!');
    // TODO: パーティクルエフェクトやサウンドを追加
  }
  
  void _showLevelUpAnimation(int oldLevel, int newLevel) {
    print('🎉 LEVEL UP! $oldLevel → $newLevel');
    
    // レベルアップダイアログを表示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade300, Colors.orange.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star,
                  size: 60,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                const Text(
                  'LEVEL UP!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Level $oldLevel → Level $newLevel',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.orange,
                  ),
                  child: const Text('おめでとう!'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CharacterProvider>(
      builder: (context, characterProvider, child) {
        // レベルアップチェック
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (characterProvider.hasLeveledUp) {
            _showLevelUpAnimation(characterProvider.previousLevel!, characterProvider.newLevel!);
            characterProvider.clearLevelUpNotification();
          }
        });
        final character = characterProvider.character;
        
        if (character == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.person_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('キャラクターを読み込み中...'),
                ],
              ),
            ),
          );
        }

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Character Header
                Row(
                  children: [
                    // Character Avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _getCharacterColor(character.level),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: _getRankColor(character.rank),
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        _getCharacterIcon(character.level),
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Character Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            character.name,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'レベル ${character.level} ${characterProvider.rankDisplay}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _getRankColor(character.rank),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Experience Bar
                          _buildExperienceBar(context, characterProvider),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Stats Row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'HP',
                        '${character.health}',
                        Icons.favorite,
                        Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'ATK',
                        '${character.attack}',
                        Icons.flash_on,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'DEF',
                        '${character.defense}',
                        Icons.shield,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'BP',
                        '${characterProvider.battlePoints}',
                        Icons.whatshot,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Stamina Bar
                _buildStaminaBar(context, characterProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExperienceBar(BuildContext context, CharacterProvider provider) {
    final progress = provider.levelProgress;
    final currentExp = provider.experienceForCurrentLevel;
    final nextLevelExp = provider.experienceForNextLevel;
    
    // 経験値の進行度が変わった場合にアニメーションを開始
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateExpProgress(progress);
    });
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'EXP',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '$currentExp / $nextLevelExp',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: Colors.grey[300],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Stack(
              children: [
                // Background
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.grey[300],
                ),
                // Animated progress
                FractionallySizedBox(
                  widthFactor: _currentAnimatedProgress,
                  child: Container(
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.shade400,
                          Colors.green.shade600,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.3),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaminaBar(BuildContext context, CharacterProvider provider) {
    final staminaPercentage = provider.staminaPercentage;
    final stamina = provider.stamina;
    final maxStamina = provider.maxStamina;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.battery_charging_full, size: 16, color: Colors.blue),
                const SizedBox(width: 4),
                Text(
                  'スタミナ',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Text(
              '$stamina / $maxStamina',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: staminaPercentage,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            staminaPercentage > 0.5 ? Colors.blue : Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
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

  Color _getCharacterColor(int level) {
    if (level >= 50) return Colors.purple;
    if (level >= 30) return Colors.blue;
    if (level >= 15) return Colors.green;
    if (level >= 5) return Colors.orange;
    return Colors.grey;
  }

  IconData _getCharacterIcon(int level) {
    if (level >= 50) return Icons.auto_awesome;
    if (level >= 30) return Icons.star;
    if (level >= 15) return Icons.emoji_events;
    if (level >= 5) return Icons.local_fire_department;
    return Icons.person;
  }

  Color _getRankColor(CharacterRank rank) {
    switch (rank) {
      case CharacterRank.beginner:
        return Colors.grey;
      case CharacterRank.intermediate:
        return Colors.green;
      case CharacterRank.advanced:
        return Colors.blue;
      case CharacterRank.epic:
        return Colors.purple;
      case CharacterRank.legendary:
        return Colors.orange;
    }
  }
}
