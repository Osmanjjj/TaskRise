import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;

  const TaskCard({
    super.key,
    required this.task,
    this.onComplete,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCompleted = task.status == TaskStatus.completed;

    Color getDifficultyColor() {
      switch (task.difficulty) {
        case TaskDifficulty.easy:
          return Colors.green;
        case TaskDifficulty.normal:
          return Colors.orange;
        case TaskDifficulty.hard:
          return Colors.red;
      }
    }

    IconData getDifficultyIcon() {
      switch (task.difficulty) {
        case TaskDifficulty.easy:
          return Icons.star_border;
        case TaskDifficulty.normal:
          return Icons.star_half;
        case TaskDifficulty.hard:
          return Icons.star;
      }
    }

    return Card(
      elevation: isCompleted ? 1 : 3,
      color: isCompleted ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5) : null,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Task Status Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? Colors.green.withValues(alpha: 0.2)
                        : getDifficultyColor().withValues(alpha: 0.2),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_circle : getDifficultyIcon(),
                    color: isCompleted ? Colors.green : getDifficultyColor(),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Task Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: isCompleted
                              ? colorScheme.onSurface.withValues(alpha: 0.6)
                              : null,
                        ),
                      ),
                      if (task.description != null && task.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            task.description!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                // Actions
                if (onDelete != null)
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    iconSize: 20,
                    color: colorScheme.error,
                    tooltip: 'Delete Task',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Task Details Row
            Row(
              children: [
                // Difficulty Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: getDifficultyColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: getDifficultyColor().withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        getDifficultyIcon(),
                        size: 12,
                        color: getDifficultyColor(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.difficulty.name.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: getDifficultyColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Experience Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        size: 12,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+${task.experienceReward} XP',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Due Date
                if (task.dueDate != null)
                  Text(
                    _formatDueDate(task.dueDate!),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _isDueSoon(task.dueDate!)
                          ? Colors.red
                          : colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
            // Complete Button
            if (onComplete != null && !isCompleted)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onComplete,
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Complete Task'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.2, end: 0);
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);

    if (difference.isNegative) {
      return 'Overdue';
    } else if (difference.inDays == 0) {
      return 'Due today';
    } else if (difference.inDays == 1) {
      return 'Due tomorrow';
    } else if (difference.inDays < 7) {
      return 'Due in ${difference.inDays} days';
    } else {
      return 'Due ${dueDate.month}/${dueDate.day}';
    }
  }

  bool _isDueSoon(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);
    return difference.isNegative || difference.inDays <= 1;
  }
}
