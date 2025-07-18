import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';
import '../models/character.dart';
import '../models/crystal.dart';
import 'character_service.dart';
import 'crystal_service.dart';
import '../providers/character_provider.dart';

class TaskService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CharacterService _characterService = CharacterService();
  final CrystalService _crystalService = CrystalService();
  final CharacterProvider? _characterProvider;

  TaskService({CharacterProvider? characterProvider}) : _characterProvider = characterProvider;

  // 現在のユーザーのキャラクターIDを取得するヘルパーメソッド
  Future<String> _getCurrentCharacterId() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('ユーザーが認証されていません');
    }
    
    var character = await _characterService.getUserCharacter(userId);
    if (character == null) {
      // キャラクターが存在しない場合は作成する
      character = await _createDefaultCharacter(userId);
      if (character == null) {
        throw Exception('キャラクターの作成に失敗しました');
      }
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
    bool isHabit = false,
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
        'is_habit': isHabit,
        'streak_count': 0,
        'streak_bonus_multiplier': 1.0,
        'max_streak': 0,
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
          .eq('status', 'pending') // 未完了タスクのみ取得
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

  // 今日完了したタスクを取得
  Future<List<Task>> getTodayCompletedTasks() async {
    try {
      final characterId = await _getCurrentCharacterId();
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('tasks')
          .select()
          .eq('character_id', characterId)
          .eq('status', 'completed')
          .gte('completed_at', startOfDay.toIso8601String())
          .lt('completed_at', endOfDay.toIso8601String())
          .order('completed_at', ascending: false);

      return (response as List)
          .map((json) => Task.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('今日の完了済みタスクの取得に失敗しました: $e');
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
      
      // 既に完了済みのタスクかチェック
      if (task.status == TaskStatus.completed) {
        print('Task already completed: $taskId');
        throw Exception('このタスクは既に完了済みです');
      }
      
      // タスクを完了状態に更新（データベースのトリガーが連続記録を更新）
      final now = DateTime.now();
      final response = await _supabase
          .from('tasks')
          .update({
            'status': 'completed',
            'completed_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .eq('id', taskId)
          .select()
          .single();

      // 更新されたタスクを取得
      final updatedTask = Task.fromJson(response);
      
      // 習慣タスクの場合は連続達成ボーナスを含めた経験値を計算
      int totalExp = task.experienceReward;
      if (updatedTask.isHabit) {
        // 連続達成ボーナスを適用
        totalExp = updatedTask.experienceWithBonus;
        print('習慣タスク完了: ${updatedTask.title}');
        print('連続達成日数: ${updatedTask.streakCount}日');
        print('ボーナス倍率: ${updatedTask.streakBonusMultiplier}x');
        print('獲得経験値: ${task.experienceReward} → $totalExp');
      }

      // キャラクターの経験値を更新
      await _updateCharacterExperience(totalExp);

      // 結晶の獲得処理
      // 注意: タスク完了時の青結晶付与はデータベーストリガーで自動的に行われるため、
      // ここでは重複を避けるため削除しています。
      
      try {
        // 習慣タスクの連続達成マイルストーンチェック
        if (updatedTask.isHabit && updatedTask.streakCount > 0) {
          final milestoneResult = await _crystalService.checkStreakMilestones(
            characterId: task.characterId!,
            streakCount: updatedTask.streakCount,
            taskId: task.id,
          );
          
          if (milestoneResult['milestone_reached'] == true) {
            print('マイルストーン達成！追加結晶を獲得しました');
          }
        }
      } catch (e) {
        print('結晶獲得処理でエラーが発生しましたが、タスク完了は成功しました: $e');
      }

      return updatedTask;
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
          .eq('is_habit', true)
          .eq('status', 'pending') // 未完了の習慣タスクのみ取得
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
    // Task.getExperienceForDifficultyの値に統一
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 10;
      case 'normal':
        return 25;
      case 'hard':
        return 50;
      default:
        return 25;
    }
  }

  // キャラクターの経験値を更新
  Future<void> _updateCharacterExperience(int experienceGained) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('Error: No authenticated user');
        return;
      }
      print('Updating experience for user: $userId');

      final character = await _characterService.getUserCharacter(userId);
      if (character == null) {
        print('Error: No character found for user: $userId');
        return;
      }
      print('Character found: ${character.name} (ID: ${character.id})');

      // CharacterServiceのaddExperienceメソッドを使用してレベルアップ処理も含めて実行
      final result = await _characterService.addExperience(userId, experienceGained);
      print('Experience update result: $result');
      
      if (result['success'] == true) {
        // 日次統計も更新
        await _updateDailyStats(character.id, experienceGained);
        
        // CharacterProviderを更新してUIに反映
        if (_characterProvider != null) {
          await _characterProvider!.refreshByUserId(userId);
          print('CharacterProvider updated successfully');
        }
        
        // レベルアップした場合の処理（将来的にUI通知などを追加可能）
        if (result['leveledUp'] == true) {
          print('レベルアップ！ Lv.${result['oldLevel']} → Lv.${result['newLevel']}');
        }
      } else {
        print('Experience update failed: ${result['error']}');
      }
    } catch (e) {
      print('キャラクター経験値の更新に失敗: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  // レベルを計算
  int _calculateLevel(int experience) {
    // シンプルなレベル計算式: 100経験値ごとに1レベル
    return (experience / 100).floor() + 1;
  }

  // 連続達成ボーナスを計算
  Future<int> _calculateStreakBonus(String characterId, TaskCategory category) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      
      // 過去7日間の同じカテゴリの完了タスク数を取得
      final response = await _supabase
          .from('tasks')
          .select()
          .eq('character_id', characterId)
          .eq('category', category.displayName)
          .eq('status', 'completed')
          .gte('completed_at', sevenDaysAgo.toIso8601String())
          .order('completed_at', ascending: false);
      
      final completedTasks = (response as List).length;
      
      // 連続達成ボーナス: 3日連続で5EXP、5日連続で10EXP、7日連続で20EXP
      if (completedTasks >= 7) {
        return 20;
      } else if (completedTasks >= 5) {
        return 10;
      } else if (completedTasks >= 3) {
        return 5;
      }
      
      return 0;
    } catch (e) {
      print('連続達成ボーナスの計算に失敗: $e');
      return 0;
    }
  }

  // デフォルトキャラクターを作成
  Future<Character?> _createDefaultCharacter(String userId) async {
    try {
      final userData = await _supabase
          .from('user_profiles')
          .select('display_name')
          .eq('id', userId)
          .maybeSingle();
      
      final displayName = userData?['display_name'] ?? 'プレイヤー';
      
      final response = await _supabase
          .from('characters')
          .insert({
            'user_id': userId,
            'name': displayName,
            'level': 1,
            'experience': 0,
            'health': 100,
            'attack': 10,
            'defense': 10,
            'stamina': 100,
            'max_stamina': 100,
            'battle_points': 0,
            'total_crystals_earned': 0,
            'consecutive_days': 0,
            'last_activity_date': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      
      return await _characterService.getUserCharacter(userId);
    } catch (e) {
      print('デフォルトキャラクターの作成に失敗: $e');
      return null;
    }
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