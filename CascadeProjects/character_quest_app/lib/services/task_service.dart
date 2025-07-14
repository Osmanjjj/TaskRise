import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';
import 'character_service.dart';

class TaskService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CharacterService _characterService = CharacterService();

  // 現在のユーザーのキャラクターIDを取得するヘルパーメソッド
  Future<String> _getCurrentCharacterId() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('ユーザーが認証されていません');
    }
    
    final character = await _characterService.getUserCharacter(userId);
    if (character == null) {
      throw Exception('キャラクターが見つかりません');
    }
    
    return character.id;
  }

  // タスクを作成
  Future<Task> createTask({
    required String title,
    String? description,
    required String category,
    required String difficulty,
    DateTime? dueDate,
  }) async {
    try {
      final characterId = await _getCurrentCharacterId();
      
      // 経験値報酬を難易度に基づいて計算
      final experienceReward = _calculateExperienceReward(difficulty);

      final data = {
        'title': title,
        'description': description,
        'difficulty': difficulty,
        'category': category,
        'experience_reward': experienceReward,
        'due_date': dueDate?.toIso8601String(),
        'character_id': characterId,
        'status': 'pending',
      };

      final response = await _supabase
          .from('tasks')
          .insert(data)
          .select()
          .single();

      return Task.fromJson(response);
    } catch (e) {
      throw Exception('タスクの作成に失敗しました: $e');
    }
  }

  // キャラクターのタスク一覧を取得
  Future<List<Task>> getTasksByCharacter({String status = 'pending'}) async {
    try {
      final characterId = await _getCurrentCharacterId();

      final response = await _supabase
          .from('tasks')
          .select()
          .eq('character_id', characterId)
          .eq('status', status)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Task.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('タスクの取得に失敗しました: $e');
    }
  }

  // 今日のタスクを取得
  Future<List<Task>> getTodayTasks() async {
    try {
      final characterId = await _getCurrentCharacterId();
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('tasks')
          .select()
          .eq('character_id', characterId)
          .gte('due_date', startOfDay.toIso8601String())
          .lt('due_date', endOfDay.toIso8601String())
          .order('due_date', ascending: true);

      return (response as List)
          .map((json) => Task.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('今日のタスクの取得に失敗しました: $e');
    }
  }

  // タスクを完了
  Future<Task> completeTask(String taskId) async {
    try {
      // まずタスクを取得して経験値報酬を確認
      final taskResponse = await _supabase
          .from('tasks')
          .select()
          .eq('id', taskId)
          .single();
      
      final task = Task.fromJson(taskResponse);
      
      // タスクを完了状態に更新
      final response = await _supabase
          .from('tasks')
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', taskId)
          .select()
          .single();

      // キャラクターの経験値を更新
      await _updateCharacterExperience(task.experienceReward);

      return Task.fromJson(response);
    } catch (e) {
      throw Exception('タスクの完了に失敗しました: $e');
    }
  }

  // タスクを更新
  Future<Task> updateTask({
    required String taskId,
    String? title,
    String? description,
    String? category,
    String? difficulty,
    DateTime? dueDate,
    String? status,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (category != null) updates['category'] = category;
      if (difficulty != null) {
        updates['difficulty'] = difficulty;
        updates['experience_reward'] = _calculateExperienceReward(difficulty);
      }
      if (dueDate != null) updates['due_date'] = dueDate.toIso8601String();
      if (status != null) updates['status'] = status;

      final response = await _supabase
          .from('tasks')
          .update(updates)
          .eq('id', taskId)
          .select()
          .single();

      return Task.fromJson(response);
    } catch (e) {
      throw Exception('タスクの更新に失敗しました: $e');
    }
  }

  // タスクを削除
  Future<void> deleteTask(String taskId) async {
    try {
      await _supabase
          .from('tasks')
          .delete()
          .eq('id', taskId);
    } catch (e) {
      throw Exception('タスクの削除に失敗しました: $e');
    }
  }

  // 習慣タスクを取得（カテゴリーが'habit'のもの）
  Future<List<Task>> getHabits() async {
    try {
      final characterId = await _getCurrentCharacterId();

      final response = await _supabase
          .from('tasks')
          .select()
          .eq('character_id', characterId)
          .eq('category', 'habit')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Task.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('習慣の取得に失敗しました: $e');
    }
  }

  // タスク統計を取得
  Future<Map<String, dynamic>> getTaskStats() async {
    try {
      final characterId = await _getCurrentCharacterId();

      // 完了したタスク数
      final completedResponse = await _supabase
          .from('tasks')
          .select('id')
          .eq('character_id', characterId)
          .eq('status', 'completed');
      
      final completedCount = (completedResponse as List).length;

      // 保留中のタスク数
      final pendingResponse = await _supabase
          .from('tasks')
          .select('id')
          .eq('character_id', characterId)
          .eq('status', 'pending');
      
      final pendingCount = (pendingResponse as List).length;

      // 今日完了したタスク数
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      final todayCompletedResponse = await _supabase
          .from('tasks')
          .select('id')
          .eq('character_id', characterId)
          .eq('status', 'completed')
          .gte('completed_at', startOfDay.toIso8601String());
      
      final todayCompletedCount = (todayCompletedResponse as List).length;

      return {
        'totalCompleted': completedCount,
        'totalPending': pendingCount,
        'todayCompleted': todayCompletedCount,
      };
    } catch (e) {
      throw Exception('タスク統計の取得に失敗しました: $e');
    }
  }

  // 経験値報酬を計算
  int _calculateExperienceReward(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 10;
      case 'normal':
        return 20;
      case 'hard':
        return 40;
      default:
        return 20;
    }
  }

  // キャラクターの経験値を更新
  Future<void> _updateCharacterExperience(int experienceGained) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final character = await _characterService.getUserCharacter(userId);
      if (character == null) return;

      final newExperience = character.experience + experienceGained;
      final newLevel = _calculateLevel(newExperience);

      await _characterService.updateCharacterStats(
        userId,
        experience: newExperience,
        level: newLevel,
      );

      // 日次統計も更新
      await _updateDailyStats(character.id, experienceGained);
    } catch (e) {
      print('キャラクター経験値の更新に失敗: $e');
    }
  }

  // レベルを計算
  int _calculateLevel(int experience) {
    // シンプルなレベル計算式: 100経験値ごとに1レベル
    return (experience / 100).floor() + 1;
  }

  // 日次統計を更新
  Future<void> _updateDailyStats(String characterId, int experienceGained) async {
    try {
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // 既存の統計を取得または作成
      final existingStats = await _supabase
          .from('daily_stats')
          .select()
          .eq('character_id', characterId)
          .eq('date', dateStr)
          .maybeSingle();

      if (existingStats != null) {
        // 既存の統計を更新
        await _supabase
            .from('daily_stats')
            .update({
              'habits_completed': (existingStats['habits_completed'] ?? 0) + 1,
              'experience_gained': (existingStats['experience_gained'] ?? 0) + experienceGained,
            })
            .eq('id', existingStats['id']);
      } else {
        // 新しい統計を作成
        await _supabase
            .from('daily_stats')
            .insert({
              'character_id': characterId,
              'date': dateStr,
              'habits_completed': 1,
              'experience_gained': experienceGained,
            });
      }
    } catch (e) {
      print('日次統計の更新に失敗: $e');
    }
  }
}