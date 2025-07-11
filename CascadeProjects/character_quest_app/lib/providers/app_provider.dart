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
  }) async {
    _setLoading(true);
    final task = await _supabaseService.createTask(
      title: title,
      description: description,
      difficulty: difficulty,
      dueDate: dueDate,
      characterId: _selectedCharacter?.id,
    );
    if (task != null) {
      _tasks.insert(0, task);
    }
    _setLoading(false);
  }

  Future<void> completeTask(Task task) async {
    if (_selectedCharacter == null) return;
    
    _setLoading(true);
    final success = await _supabaseService.completeTask(task, _selectedCharacter!);
    if (success) {
      // Update local state
      final taskIndex = _tasks.indexWhere((t) => t.id == task.id);
      if (taskIndex != -1) {
        _tasks[taskIndex] = task.copyWith(status: TaskStatus.completed);
      }
      
      // Update character experience
      final characterIndex = _characters.indexWhere((c) => c.id == _selectedCharacter!.id);
      if (characterIndex != -1) {
        final updatedCharacter = _selectedCharacter!.copyWith(
          experience: _selectedCharacter!.experience + task.experienceReward,
        );
        _characters[characterIndex] = updatedCharacter;
        _selectedCharacter = updatedCharacter;
      }
    }
    _setLoading(false);
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
