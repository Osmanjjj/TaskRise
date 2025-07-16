import 'package:flutter/foundation.dart';
import '../models/character.dart';
import '../models/task.dart';
import '../services/supabase_service.dart';

class AppProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService.instance;
  
  List<Character> _characters = [];
  List<Task> _tasks = [];
  Character? _selectedCharacter;
  bool _isLoading = false;

  List<Character> get characters => _characters;
  List<Task> get tasks => _tasks;
  Character? get selectedCharacter => _selectedCharacter;
  bool get isLoading => _isLoading;

  List<Task> get pendingTasks => _tasks.where((task) => task.status == TaskStatus.pending).toList();
  List<Task> get completedTasks => _tasks.where((task) => task.status == TaskStatus.completed).toList();

  Future<void> loadCharacters() async {
    _setLoading(true);
    _characters = await _supabaseService.getCharacters();
    if (_characters.isNotEmpty && _selectedCharacter == null) {
      _selectedCharacter = _characters.first;
    }
    _setLoading(false);
  }

  Future<void> createCharacter(String name) async {
    _setLoading(true);
    final character = await _supabaseService.createCharacter(name);
    if (character != null) {
      _characters.insert(0, character);
      _selectedCharacter = character;
    }
    _setLoading(false);
  }

  void selectCharacter(Character character) {
    _selectedCharacter = character;
    loadTasks();
    notifyListeners();
  }

  Future<void> loadTasks() async {
    _setLoading(true);
    _tasks = await _supabaseService.getTasks(
      characterId: _selectedCharacter?.id,
    );
    _setLoading(false);
  }

  Future<void> createTask({
    required String title,
    String? description,
    TaskDifficulty difficulty = TaskDifficulty.normal,
    DateTime? dueDate,
    bool isHabit = false,
  }) async {
    _setLoading(true);
    try {
      print('AppProvider.createTask - Selected character ID: ${_selectedCharacter?.id}');
      print('AppProvider.createTask - Selected character name: ${_selectedCharacter?.name}');
      
      final task = await _supabaseService.createTask(
        title: title,
        description: description,
        difficulty: difficulty,
        dueDate: dueDate,
        characterId: _selectedCharacter?.id,
        isHabit: isHabit,
      );
      
      if (task != null) {
        _tasks.insert(0, task);
        print('AppProvider.createTask - Task created successfully');
      } else {
        print('AppProvider.createTask - Task creation returned null');
        throw Exception('タスクの作成に失敗しました');
      }
    } catch (e) {
      print('AppProvider.createTask - Error: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> completeTask(Task task) async {
    if (_selectedCharacter == null) return {'success': false};
    
    _setLoading(true);
    final result = await _supabaseService.completeTaskWithRewards(task, _selectedCharacter!);
    
    if (result['success'] == true) {
      // Update local state
      final taskIndex = _tasks.indexWhere((t) => t.id == task.id);
      if (taskIndex != -1) {
        _tasks[taskIndex] = task.copyWith(status: TaskStatus.completed);
      }
      
      // Update character with new stats
      if (result['updatedCharacter'] != null) {
        final updatedCharacter = result['updatedCharacter'] as Character;
        final characterIndex = _characters.indexWhere((c) => c.id == _selectedCharacter!.id);
        if (characterIndex != -1) {
          _characters[characterIndex] = updatedCharacter;
          _selectedCharacter = updatedCharacter;
        }
        
        // UIを強制的に更新
        notifyListeners();
      } else {
        // キャラクター情報を再取得
        await refreshSelectedCharacter();
      }
    }
    
    _setLoading(false);
    return result;
  }

  Future<void> refreshSelectedCharacter() async {
    if (_selectedCharacter == null) return;
    
    final userId = _supabaseService.client.auth.currentUser?.id;
    if (userId == null) return;
    
    final updatedCharacter = await _supabaseService.getCharacterByUserId(userId);
    if (updatedCharacter != null) {
      final characterIndex = _characters.indexWhere((c) => c.id == updatedCharacter.id);
      if (characterIndex != -1) {
        _characters[characterIndex] = updatedCharacter;
        _selectedCharacter = updatedCharacter;
        notifyListeners();
      }
    }
  }

  Future<void> deleteTask(Task task) async {
    _setLoading(true);
    final success = await _supabaseService.deleteTask(task.id);
    if (success) {
      _tasks.removeWhere((t) => t.id == task.id);
    }
    _setLoading(false);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
