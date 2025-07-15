import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/app_provider.dart';
import '../providers/character_provider.dart';
import '../widgets/task_card.dart';

class TaskList extends StatelessWidget {
  final List<Task> tasks;

  const TaskList({
    super.key,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    final pendingTasks = tasks.where((task) => task.status == TaskStatus.pending).toList();
    final completedTasks = tasks.where((task) => task.status == TaskStatus.completed).toList();

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first task to start earning experience!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.pending_actions, size: 16),
                    const SizedBox(width: 8),
                    Text('Pending (${pendingTasks.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, size: 16),
                    const SizedBox(width: 8),
                    Text('Completed (${completedTasks.length})'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              children: [
                _buildTaskList(context, pendingTasks, isPending: true),
                _buildTaskList(context, completedTasks, isPending: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, List<Task> taskList, {required bool isPending}) {
    if (taskList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPending ? Icons.pending_actions : Icons.check_circle,
              size: 48,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              isPending ? 'No pending tasks' : 'No completed tasks',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isPending
                  ? 'Create a task to start your quest!'
                  : 'Complete some tasks to see them here!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: taskList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final task = taskList[index];
        return TaskCard(
          task: task,
          onComplete: isPending ? () => _completeTask(context, task) : null,
          onDelete: () => _deleteTask(context, task),
        );
      },
    );
  }

  void _completeTask(BuildContext context, Task task) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final characterProvider = Provider.of<CharacterProvider>(context, listen: false);
    
    // レベルアップコールバックを設定
    characterProvider.setLevelUpCallback((oldLevel, newLevel) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          title: Row(
            children: [
              Icon(Icons.star, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text('レベルアップ！'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Lv.$oldLevel → Lv.$newLevel',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text('ステータスが上昇しました！'),
              const SizedBox(height: 8),
              const Text('攻撃力 +2'),
              const Text('防御力 +2'),
              const Text('最大HP +10'),
              const Text('最大スタミナ +5'),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('素晴らしい！'),
            ),
          ],
        ),
      );
    });
    
    appProvider.completeTask(task).then((result) {
      if (result['success'] == true) {
        // CharacterProviderでも経験値を更新（リアルタイム反映のため）
        final expGained = result['expGained'] ?? task.experienceReward;
        characterProvider.updateCharacterStats(experienceGain: expGained);
        
        // 通常の完了通知
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('タスク完了！ +$expGained XP'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // エラー通知
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラー: ${result['error'] ?? 'タスクの完了に失敗しました'}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  void _deleteTask(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              final provider = Provider.of<AppProvider>(context, listen: false);
              provider.deleteTask(task);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
