import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/character_provider.dart';
import '../models/task.dart';

class HabitListWidget extends StatelessWidget {
  const HabitListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<GameProvider, CharacterProvider>(
      builder: (context, gameProvider, characterProvider, child) {
        final habits = gameProvider.habits;
        final currentStamina = characterProvider.stamina;

        if (habits.isEmpty) {
          return Center(
            child: Column(
              children: [
                Icon(
                  Icons.task_alt,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  '習慣を追加してスタート！',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/habits');
                  },
                  child: const Text('習慣を追加'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // 習慣を追加ボタン
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/habits');
                },
                icon: const Icon(Icons.add),
                label: const Text('習慣を追加'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            // 習慣リスト
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: habits.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final habit = habits[index];
                final canComplete = gameProvider.canCompleteHabit(habit.id, currentStamina);
                
                return HabitTile(
                  habit: habit,
                  canComplete: canComplete,
                  onComplete: () => _completeHabit(context, habit.id),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _completeHabit(BuildContext context, String habitId) async {
    final gameProvider = context.read<GameProvider>();
    final characterProvider = context.read<CharacterProvider>();
    
    // TODO: Get actual character ID
    const characterId = 'sample-character-id';
    
    // Find the habit to get its experience reward
    final habit = gameProvider.habits.firstWhere((h) => h.id == habitId);
    final experienceGain = habit.experienceReward;
    final battlePointsGain = habit.difficulty.staminaCost * 2; // Battle points based on difficulty
    
    final success = await gameProvider.completeHabit(characterId, habitId);
    
    if (success) {
      // Update character stats with experience and battle points
      characterProvider.updateCharacterStats(
        experienceGain: experienceGain,
        battlePointsGain: battlePointsGain,
        staminaGain: -habit.difficulty.staminaCost, // Consume stamina
      );
      
      // Show success animation/dialog with rewards
      _showCompletionDialog(context, experienceGain, battlePointsGain);
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('習慣の完了に失敗しました'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCompletionDialog(BuildContext context, int experienceGain, int battlePointsGain) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('習慣完了！'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('おめでとうございます！'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 32),
                    const SizedBox(height: 4),
                    Text(
                      '+$experienceGain EXP',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Icon(Icons.whatshot, color: Colors.purple, size: 32),
                    const SizedBox(height: 4),
                    Text(
                      '+$battlePointsGain BP',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
}

class HabitTile extends StatelessWidget {
  final Task habit;
  final bool canComplete;
  final VoidCallback onComplete;

  const HabitTile({
    super.key,
    required this.habit,
    required this.canComplete,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: habit.isCompleted ? 1 : 2,
      child: InkWell(
        onTap: habit.isCompleted || !canComplete ? null : onComplete,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: habit.isCompleted 
                ? Colors.green.withValues(alpha: 0.1)
                : canComplete 
                    ? null 
                    : Colors.grey.withValues(alpha: 0.1),
          ),
          child: Row(
            children: [
              // Completion Status Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: habit.isCompleted 
                      ? Colors.green 
                      : canComplete 
                          ? Color(habit.difficulty.color).withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.3),
                ),
                child: Icon(
                  habit.isCompleted
                      ? Icons.check 
                      : Icons.fitness_center,
                  color: habit.isCompleted 
                      ? Colors.white 
                      : canComplete 
                          ? Color(habit.difficulty.color)
                          : Colors.grey,
                  size: 20,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Habit Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: habit.isCompleted 
                            ? TextDecoration.lineThrough 
                            : null,
                        color: habit.isCompleted 
                            ? Colors.grey[600]
                            : canComplete 
                                ? null 
                                : Colors.grey,
                      ),
                    ),
                    if (habit.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        habit.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Difficulty Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color(habit.difficulty.color).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            habit.difficulty.displayName,
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(habit.difficulty.color),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Stamina Cost
                        Row(
                          children: [
                            Icon(
                              Icons.flash_on,
                              size: 12,
                              color: canComplete ? Colors.amber : Colors.grey,
                            ),
                            Text(
                              '${habit.difficulty.staminaCost}',
                              style: TextStyle(
                                fontSize: 12,
                                color: canComplete ? Colors.amber : Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Chain Length
                        if (habit.chainLength > 0)
                          Row(
                            children: [
                              Icon(
                                Icons.link,
                                size: 12,
                                color: Colors.purple[300],
                              ),
                              Text(
                                '${habit.chainLength}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.purple[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Action Button
              if (habit.isCompleted)
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 24,
                )
              else if (canComplete)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 18,
                  ),
                )
              else
                Icon(
                  Icons.lock,
                  color: Colors.grey[400],
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
