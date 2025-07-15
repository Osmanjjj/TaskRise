import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/character_provider.dart';
import '../services/task_service.dart';
import '../models/task.dart';
import '../widgets/character_display_widget.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TaskService _taskService = TaskService();
  List<Task> _todayTasks = [];
  List<Task> _habits = [];
  List<Task> _completedTasks = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Provider data
      await context.read<GameProvider>().loadData();
      await context.read<CharacterProvider>().loadCharacter();
      
      // Tasks data
      final results = await Future.wait([
        _taskService.getTodayTasks(),
        _taskService.getHabits(),
        _taskService.getTasksByCharacter(status: 'completed'),
      ]);
      
      setState(() {
        _todayTasks = results[0];
        _habits = results[1];
        _completedTasks = results[2];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('データの読み込みに失敗しました: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('習慣管理'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '今日のタスク', icon: Icon(Icons.today)),
            Tab(text: '習慣', icon: Icon(Icons.repeat)),
            Tab(text: '完了済み', icon: Icon(Icons.check_circle)),
          ],
        ),
      ),
      body: Column(
        children: [
          // キャラクター表示
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: CharacterDisplayWidget(),
          ),
          
          // タブビュー
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTodayTasksTab(),
                _buildHabitsTab(),
                _buildCompletedTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTaskDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTodayTasksTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_todayTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '今日のタスクはありません',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showCreateTaskDialog(isToday: true),
              icon: const Icon(Icons.add),
              label: const Text('タスクを追加'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _todayTasks.length,
        itemBuilder: (context, index) {
          final task = _todayTasks[index];
          return _buildTaskCard(task);
        },
      ),
    );
  }

  Widget _buildHabitsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_habits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.repeat, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '習慣がまだ登録されていません',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showCreateTaskDialog(isHabit: true),
              icon: const Icon(Icons.add),
              label: const Text('習慣を追加'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _habits.length,
        itemBuilder: (context, index) {
          final habit = _habits[index];
          return _buildTaskCard(habit, isHabit: true);
        },
      ),
    );
  }

  Widget _buildCompletedTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_completedTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'まだ完了したタスクはありません',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _completedTasks.length,
        itemBuilder: (context, index) {
          final task = _completedTasks[index];
          return _buildTaskCard(task, isCompleted: true);
        },
      ),
    );
  }

  Widget _buildTaskCard(Task task, {bool isHabit = false, bool isCompleted = false}) {
    final difficultyColor = _getDifficultyColor(task.difficulty);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCompleted 
              ? Colors.green.withValues(alpha: 0.2)
              : difficultyColor.withValues(alpha: 0.2),
          child: Icon(
            isCompleted ? Icons.check : _getCategoryIcon(task.category),
            color: isCompleted ? Colors.green : difficultyColor,
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty)
              Text(task.description!),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: difficultyColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getDifficultyText(task.difficulty),
                    style: TextStyle(
                      fontSize: 12,
                      color: difficultyColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.star, size: 16, color: Colors.amber),
                Text(
                  ' ${task.experienceReward} EXP',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: isCompleted 
            ? null 
            : IconButton(
                icon: const Icon(Icons.check_circle_outline),
                onPressed: () => _completeTask(task),
              ),
        onTap: isCompleted ? null : () => _showTaskDetailDialog(task),
        onLongPress: isCompleted ? null : () => _showTaskOptionsDialog(task),
      ),
    );
  }

  Future<void> _completeTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('タスクを完了'),
        content: Text('「${task.title}」を完了しますか？\n${task.experienceReward} EXPを獲得します。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('完了'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _taskService.completeTask(task.id);
        
        // レベルアップチェック
        final characterProvider = context.read<CharacterProvider>();
        final oldLevel = characterProvider.character?.level ?? 1;
        
        await _loadData();
        
        final newLevel = characterProvider.character?.level ?? 1;
        if (newLevel > oldLevel) {
          _showLevelUpDialog(oldLevel, newLevel);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('タスクを完了しました！ +${task.experienceReward} EXP'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }

  void _showLevelUpDialog(int oldLevel, int newLevel) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.amber, size: 32),
            const SizedBox(width: 8),
            const Text('レベルアップ！'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'レベル $oldLevel → $newLevel',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 16),
            const Text('おめでとうございます！'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCreateTaskDialog({bool isHabit = false, bool isToday = false}) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    TaskDifficulty difficulty = TaskDifficulty.normal;
    TaskCategory category = isHabit ? TaskCategory.hobby : TaskCategory.other;
    DateTime? dueDate = isToday ? DateTime.now() : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isHabit ? '新しい習慣を追加' : '新しいタスクを追加'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'タイトル',
                    hintText: '例: 30分読書する',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: '説明（オプション）',
                    hintText: '詳細を入力',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TaskCategory>(
                  value: category,
                  decoration: const InputDecoration(
                    labelText: 'カテゴリー',
                  ),
                  items: TaskCategory.values.map((c) => 
                    DropdownMenuItem(
                      value: c,
                      child: Text(c.displayName),
                    ),
                  ).toList(),
                  onChanged: (value) => setState(() => category = value!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TaskDifficulty>(
                  value: difficulty,
                  decoration: const InputDecoration(
                    labelText: '難易度',
                  ),
                  items: TaskDifficulty.values.map((d) => 
                    DropdownMenuItem(
                      value: d,
                      child: Text(d.displayName),
                    ),
                  ).toList(),
                  onChanged: (value) => setState(() => difficulty = value!),
                ),
                if (!isHabit) ...[
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('期限'),
                    subtitle: Text(
                      dueDate != null
                          ? '${dueDate!.year}/${dueDate!.month}/${dueDate!.day}'
                          : '未設定',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dueDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => dueDate = picked);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('タイトルを入力してください')),
                  );
                  return;
                }

                try {
                  await _taskService.createTask(
                    title: titleController.text,
                    description: descriptionController.text.isEmpty 
                        ? null 
                        : descriptionController.text,
                    category: category.displayName,
                    difficulty: difficulty.name,
                    dueDate: dueDate,
                  );
                  
                  // ダイアログを安全に閉じる
                  if (mounted) {
                    Navigator.of(context, rootNavigator: true).pop();
                  }
                  
                  // Context を保存してから非同期処理を実行
                  if (mounted) {
                    await _loadData();
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('タスクを作成しました'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    // ダイアログが開いている場合のみ閉じる
                    try {
                      Navigator.of(context, rootNavigator: true).pop();
                    } catch (_) {
                      // ダイアログが既に閉じられている場合は無視
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('エラー: $e')),
                    );
                  }
                }
              },
              child: const Text('作成'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTaskDetailDialog(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty) ...[
              Text(task.description!),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Icon(Icons.category, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(_getCategoryText(task.category)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.fitness_center, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text('難易度: ${_getDifficultyText(task.difficulty)}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 8),
                Text('獲得経験値: ${task.experienceReward} EXP'),
              ],
            ),
            if (task.dueDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text('期限: ${_formatDate(task.dueDate!)}'),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _completeTask(task);
            },
            icon: const Icon(Icons.check),
            label: const Text('完了'),
          ),
        ],
      ),
    );
  }

  void _showTaskOptionsDialog(Task task) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.check_circle),
            title: const Text('完了'),
            onTap: () {
              Navigator.of(context).pop();
              _completeTask(task);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('編集'),
            onTap: () {
              Navigator.of(context).pop();
              // TODO: 編集機能の実装
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('削除', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.of(context).pop();
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('タスクを削除'),
                  content: Text('「${task.title}」を削除しますか？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('キャンセル'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('削除'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                try {
                  await _taskService.deleteTask(task.id);
                  await _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('タスクを削除しました')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('エラー: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return Colors.green;
      case TaskDifficulty.normal:
        return Colors.orange;
      case TaskDifficulty.hard:
        return Colors.red;
    }
  }

  String _getDifficultyText(TaskDifficulty difficulty) {
    return difficulty.displayName;
  }

  IconData _getCategoryIcon(TaskCategory category) {
    switch (category) {
      case TaskCategory.health:
        return Icons.favorite;
      case TaskCategory.learning:
        return Icons.school;
      case TaskCategory.work:
        return Icons.work;
      case TaskCategory.hobby:
        return Icons.sports_esports;
      case TaskCategory.other:
        return Icons.task_alt;
    }
  }

  String _getCategoryText(TaskCategory category) {
    return category.displayName;
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }
}