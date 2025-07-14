import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/character.dart';
import '../models/task.dart';
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
      final now = DateTime.now();
      final response = await client
          .from('characters')
          .insert({
            'name': name,
            'level': 1,
            'experience': 0,
            'health': 100,
            'attack': 10,
            'defense': 5,
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
  }) async {
    try {
      final now = DateTime.now();
      final experienceReward = Task.getExperienceForDifficulty(difficulty);
      
      final response = await client
          .from('tasks')
          .insert({
            'title': title,
            'description': description,
            'difficulty': difficulty.name,
            'status': TaskStatus.pending.name,
            'experience_reward': experienceReward,
            'due_date': dueDate?.toIso8601String(),
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
            'character_id': characterId,
          })
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
