import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/character_provider.dart';
import '../models/character.dart';

class CharacterDisplayWidget extends StatelessWidget {
  const CharacterDisplayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CharacterProvider>(
      builder: (context, characterProvider, child) {
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
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
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
