import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/character_provider.dart';
import '../models/task.dart';

class HabitListWidget extends StatelessWidget {
  const HabitListWidget({Key? key}) : super(key: key);

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
                    // Navigate to habit creation
                  },
                  child: const Text('習慣を追加'),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
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
        );
      },
    );
  }

  Future<void> _completeHabit(BuildContext context, String habitId) async {
    final gameProvider = context.read<GameProvider>();
    final characterProvider = context.read<CharacterProvider>();
    
    // TODO: Get actual character ID
    const characterId = 'sample-character-id';
    
    final success = await gameProvider.completeHabit(characterId, habitId);
    
    if (success) {
      // Show success animation/dialog
      _showCompletionDialog(context);
      
      // Update character stats if needed
      // This would be handled by the service integration
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

  void _showCompletionDialog(BuildContext context) {
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
        content: const Text('経験値とバトルポイントを獲得しました！'),
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
    Key? key,
    required this.habit,
    required this.canComplete,
    required this.onComplete,
  }) : super(key: key);

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
