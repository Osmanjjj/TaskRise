import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/character.dart';

class CharacterCard extends StatelessWidget {
  final Character character;
  final bool isSelected;
  final VoidCallback onTap;

  const CharacterCard({
    super.key,
    required this.character,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: isSelected ? 8 : 2,
      color: isSelected ? colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  // Character Avatar
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.secondary,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        character.name.isNotEmpty
                            ? character.name[0].toUpperCase()
                            : '?',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Character Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                character.name,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.secondary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Lv. ${character.level}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildStatRow(
                          context,
                          'HP',
                          character.health,
                          100,
                          Colors.red,
                        ),
                        const SizedBox(height: 4),
                        _buildStatRow(
                          context,
                          'ATK',
                          character.attack,
                          100,
                          Colors.orange,
                        ),
                        const SizedBox(height: 4),
                        _buildStatRow(
                          context,
                          'DEF',
                          character.defense,
                          100,
                          Colors.blue,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Experience Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Experience',
                        style: theme.textTheme.labelMedium,
                      ),
                      Text(
                        '${character.experience} / ${character.level * 100}',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (character.experience % 100) / 100,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.primary,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate(target: isSelected ? 1 : 0).scale(end: const Offset(1.02, 1.02));
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    int value,
    int maxValue,
    Color color,
  ) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        SizedBox(
          width: 30,
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: value / maxValue,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 30,
          child: Text(
            value.toString(),
            style: theme.textTheme.labelSmall,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
