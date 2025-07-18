import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/character.dart';
import '../models/task.dart';
import 'task_service.dart';
import 'character_service.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();
  
  SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;

  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }

  // Character operations
  Future<List<Character>> getCharacters() async {
    try {
      final response = await client
          .from('characters')
          .select()
          .order('created_at', ascending: false);
      
      return response.map<Character>((json) => Character.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching characters: $e');
      return [];
    }
  }

  Future<Character?> createCharacter(String name) async {
    try {
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        print('Error: No authenticated user');
        return null;
      }
      
      final now = DateTime.now();
      final response = await client
          .from('characters')
          .insert({
            'name': name,
            'user_id': currentUser.id,  // user_idを追加
            'level': 1,
            'experience': 0,
            'health': 100,
            'attack': 10,
            'defense': 5,
            'stamina': 100,
            'max_stamina': 100,
            'battle_points': 0,
            'total_crystals_earned': 0,
            'consecutive_days': 0,
            'last_activity_date': now.toIso8601String(),
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .select()
          .single();
      
      return Character.fromJson(response);
    } catch (e) {
      print('Error creating character: $e');
      return null;
    }
  }

  Future<Character?> updateCharacter(Character character) async {
    try {
      final updatedCharacter = character.copyWith(updatedAt: DateTime.now());
      final response = await client
          .from('characters')
          .update(updatedCharacter.toJson())
          .eq('id', character.id)
          .select()
          .single();
      
      return Character.fromJson(response);
    } catch (e) {
      print('Error updating character: $e');
      return null;
    }
  }

  // Task operations
  Future<List<Task>> getTasks({String? characterId}) async {
    try {
      var query = client
          .from('tasks')
          .select();
      
      if (characterId != null) {
        query = query.eq('character_id', characterId);
      }
      
      final response = await query.order('created_at', ascending: false);
      return response.map<Task>((json) => Task.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching tasks: $e');
      return [];
    }
  }

  Future<Task?> createTask({
    required String title,
    String? description,
    TaskDifficulty difficulty = TaskDifficulty.normal,
    DateTime? dueDate,
    String? characterId,
    bool isHabit = false,
  }) async {
    try {
      // デバッグ: 現在のユーザーとキャラクターIDを確認
      final currentUser = client.auth.currentUser;
      print('Debug - Current user ID: ${currentUser?.id}');
      print('Debug - Character ID being used: $characterId');
      
      // キャラクターIDが渡されていない場合、現在のユーザーのキャラクターを取得
      String? actualCharacterId = characterId;
      if (actualCharacterId == null && currentUser != null) {
        final characterResponse = await client
            .from('characters')
            .select('id')
            .eq('user_id', currentUser.id)
            .maybeSingle();
        
        if (characterResponse != null) {
          actualCharacterId = characterResponse['id'];
          print('Debug - Found character ID: $actualCharacterId');
        } else {
          // キャラクターが存在しない場合は作成
          print('Debug - No character found, creating new one');
          final newCharacter = await createCharacter('プレイヤー');
          actualCharacterId = newCharacter?.id;
        }
      }
      
      if (actualCharacterId == null) {
        throw Exception('キャラクターIDが見つかりません');
      }
      
      final now = DateTime.now();
      final experienceReward = Task.getExperienceForDifficulty(difficulty);
      
      // 基本的なタスクデータ
      final taskData = <String, dynamic>{
        'title': title,
        'description': description,
        'difficulty': difficulty.name,
        'status': TaskStatus.pending.name,
        'category': 'その他',
        'experience_reward': experienceReward,
        'due_date': dueDate?.toIso8601String(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'character_id': actualCharacterId,
      };
      
      // データベースに新しいカラムが存在する場合のみ追加
      // TODO: マイグレーション実行後、これらのフィールドを常に含めるように変更
      try {
        // 新しいカラムが存在するかチェック
        await client.from('tasks').select('is_habit').limit(1);
        // エラーが発生しなければ、新しいカラムが存在する
        taskData['is_habit'] = isHabit;
        taskData['streak_count'] = 0;
        taskData['streak_bonus_multiplier'] = 1.0;
        taskData['max_streak'] = 0;
      } catch (e) {
        // カラムが存在しない場合は無視
        print('Note: Streak fields not yet available in database. Run migration to enable.');
      }
      
      final response = await client
          .from('tasks')
          .insert(taskData)
          .select()
          .single();
      
      return Task.fromJson(response);
    } catch (e) {
      print('Error creating task: $e');
      return null;
    }
  }

  Future<Task?> updateTask(Task task) async {
    try {
      final updatedTask = task.copyWith(updatedAt: DateTime.now());
      final response = await client
          .from('tasks')
          .update(updatedTask.toJson())
          .eq('id', task.id)
          .select()
          .single();
      
      return Task.fromJson(response);
    } catch (e) {
      print('Error updating task: $e');
      return null;
    }
  }

  Future<bool> completeTask(Task task, Character character) async {
    try {
      // Update task status
      final completedTask = task.copyWith(
        status: TaskStatus.completed,
        updatedAt: DateTime.now(),
      );
      
      // Update character with experience
      final updatedCharacter = character.copyWith(
        experience: character.experience + task.experienceReward,
        level: character.calculatedLevel,
        updatedAt: DateTime.now(),
      );

      // Execute both updates
      await Future.wait([
        updateTask(completedTask),
        updateCharacter(updatedCharacter),
      ]);

      return true;
    } catch (e) {
      print('Error completing task: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> completeTaskWithRewards(Task task, Character character) async {
    try {
      // TaskServiceを使用してタスクを完了（ボーナスEXPなどの計算も含む）
      final taskService = TaskService();
      final completedTask = await taskService.completeTask(task.id);
      
      // CharacterServiceを使用して最新のキャラクター情報を取得
      final characterService = CharacterService();
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');
      
      // 少し待機してデータベースの更新を確実にする
      await Future.delayed(const Duration(milliseconds: 500));
      
      final updatedCharacter = await characterService.getUserCharacter(userId);
      
      // レベルアップチェック
      final oldLevel = character.level;
      final newLevel = updatedCharacter?.level ?? character.level;
      final leveledUp = newLevel > oldLevel;
      
      // 実際に獲得したEXPを計算（ボーナス込み）
      final actualExpGained = (updatedCharacter?.experience ?? character.experience) - 
                             character.experience + 
                             (leveledUp ? (oldLevel * 100) : 0);
      
      return {
        'success': true,
        'completedTask': completedTask,
        'updatedCharacter': updatedCharacter,
        'expGained': actualExpGained > 0 ? actualExpGained : task.experienceReward,
        'leveledUp': leveledUp,
        'oldLevel': oldLevel,
        'newLevel': newLevel,
      };
    } catch (e) {
      print('Error completing task with rewards: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Character?> getCharacterByUserId(String userId) async {
    try {
      final response = await client
          .from('characters')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return Character.fromJson(response);
    } catch (e) {
      print('Error getting character by user ID: $e');
      return null;
    }
  }

  Future<bool> deleteTask(String taskId) async {
    try {
      await client.from('tasks').delete().eq('id', taskId);
      return true;
    } catch (e) {
      print('Error deleting task: $e');
      return false;
    }
  }
}
