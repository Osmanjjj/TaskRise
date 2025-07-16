import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../models/event.dart';
import '../models/raid.dart';
import '../models/daily_stats.dart';
import '../models/habit_completion.dart';
import '../services/services.dart';
import 'character_provider.dart';
import 'dart:async';

class GameProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  List<GameEvent> _activeEvents = [];
  List<GameEvent> _upcomingEvents = [];
  RaidBoss? _currentRaidBoss;
  List<EventParticipation> _eventParticipations = [];
  DailyStats? _todayStats;
  Map<String, dynamic> _crystals = {};
  bool _isLoading = false;
  String? _error;

  // Services
  final HabitService _habitService = HabitService();
  late final TaskService _taskService;
  final EventService _eventService = EventService();

  GameProvider({CharacterProvider? characterProvider}) {
    _taskService = TaskService(characterProvider: characterProvider);
  }

  // Stream subscriptions for real-time updates
  StreamSubscription? _eventSubscription;
  StreamSubscription? _raidSubscription;

  // Getters
  List<Task> get tasks => List.unmodifiable(_tasks);
  List<Task> get habits => tasks; // 互換性のため一時的に保持
  List<GameEvent> get activeEvents => _activeEvents;
  List<GameEvent> get upcomingEvents => _upcomingEvents;
  RaidBoss? get currentRaidBoss => _currentRaidBoss;
  List<EventParticipation> get eventParticipations => _eventParticipations;
  DailyStats? get todayStats => _todayStats;
  Map<String, dynamic> get crystals => _crystals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Game state getters
  bool get hasActiveRaid => _currentRaidBoss != null && _currentRaidBoss!.isActive;
  RaidBoss? get activeRaidBoss => _currentRaidBoss;
  int get totalBlueCrystals => _crystals['blue'] ?? 0;
  int get totalGreenCrystals => _crystals['green'] ?? 0;
  int get totalGoldCrystals => _crystals['gold'] ?? 0;
  int get totalRainbowCrystals => _crystals['rainbow'] ?? 0;
  int get todayHabitsCompleted => _todayStats?.habitsCompleted ?? 0;
  int get todayExperienceEarned => _todayStats?.experienceGained ?? 0;
  int get todayBattlePointsEarned => _todayStats?.battlePointsEarned ?? 0;
  int get currentChainLength => _todayStats?.longestChain ?? 0;

  /// Initialize game data
  Future<void> initializeGame(String characterId) async {
    _setLoading(true);
    _clearError();

    try {
      await Future.wait([
        _loadHabits(characterId),
        _loadEvents(characterId),
        _loadDailyStats(characterId),
        _loadCrystals(characterId),
      ]);

      // Start real-time subscriptions
      _startEventSubscription();
      _startRaidSubscription();
    } catch (e) {
      _setError('Failed to initialize game: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load character habits
  Future<void> _loadHabits(String characterId) async {
    try {
      _tasks = await _taskService.getTasksByCharacter();
    } catch (e) {
      // For now, create placeholder tasks if service fails
      _tasks = [
      Task(
        id: '1',
        title: '朝の運動',
        description: '毎朝15分の軽い運動をする',
        difficulty: TaskDifficulty.normal,
        experienceReward: 25,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        isCompleted: false,
        chainLength: 5,
        category: TaskCategory.health,
      ),
      Task(
        id: '2',
        title: '読書',
        description: '毎日1時間の読書時間を確保する',
        difficulty: TaskDifficulty.hard,
        experienceReward: 50,
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        isCompleted: false,
        chainLength: 12,
        category: TaskCategory.learning,
      ),
      Task(
        id: '3',
        title: '日記を書く',
        description: 'その日の振り返りを日記に記録する',
        difficulty: TaskDifficulty.easy,
        experienceReward: 10,
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
        updatedAt: DateTime.now(),
        isCompleted: true,
        chainLength: 8,
        category: TaskCategory.other,
      ),
    ];
    }
    notifyListeners();
  }

  /// Load active and upcoming events
  Future<void> _loadEvents(String characterId) async {
    _activeEvents = await _eventService.getActiveEvents();
    _upcomingEvents = await _eventService.getUpcomingEvents();
    _eventParticipations = await _eventService.getCharacterEventParticipations(characterId);
    notifyListeners();
  }

  /// Load daily statistics
  Future<void> _loadDailyStats(String characterId) async {
    _todayStats = await _habitService.getDailyStats(characterId, DateTime.now());
    notifyListeners();
  }

  /// Load crystal inventory
  Future<void> _loadCrystals(String characterId) async {
    // This would come from a character service
    // For now, set placeholder crystal counts
    _crystals = {
      'blue': 25,
      'green': 12,
      'gold': 3,
      'rainbow': 1,
    };
    notifyListeners();
  }

  /// Complete a habit
  Future<bool> completeHabit(String characterId, String habitId) async {
    _setLoading(true);
    try {
      final task = _tasks.firstWhere((h) => h.id == habitId);
      final completion = await _habitService.completeHabit(
        characterId: characterId,
        taskId: habitId,
        difficulty: task.difficulty.name,
      );
      
      if (completion != null) {
        // Update habit state
        final habitIndex = _tasks.indexWhere((h) => h.id == habitId);
        if (habitIndex != -1) {
          _tasks[habitIndex] = _tasks[habitIndex].copyWith(
            isCompleted: true,
            chainLength: completion.chainLength,
          );
        }

        // Update crystals
        if (completion.crystalsEarned.isNotEmpty) {
          for (final crystal in completion.crystalsEarned) {
            final type = crystal.type.name;
            final amount = crystal.amount;
            _crystals[type] = (_crystals[type] ?? 0) + amount;
          }
        }

        // Refresh daily stats
        await _loadDailyStats(characterId);
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to complete habit: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Join an event
  Future<bool> joinEvent(String characterId, String eventId) async {
    _setLoading(true);
    try {
      final participation = await _eventService.joinEvent(characterId, eventId);
      
      if (participation != null) {
        _eventParticipations.add(participation);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to join event: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update event progress
  Future<bool> updateEventProgress(String participationId, String characterId, int progress) async {
    try {
      final participation = _eventParticipations.firstWhere((p) => p.id == participationId);
      final success = await _eventService.updateEventProgress(participation.eventId, characterId, progress);
      
      if (success) {
        final index = _eventParticipations.indexWhere((p) => p.id == participationId);
        if (index != -1) {
          _eventParticipations[index] = _eventParticipations[index].copyWith(
            score: progress,
          );
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      _setError('Failed to update event progress: $e');
      return false;
    }
  }

  /// Claim event rewards
  Future<bool> claimEventRewards(String participationId, String characterId) async {
    _setLoading(true);
    try {
      final participation = _eventParticipations.firstWhere((p) => p.id == participationId);
      final rewards = await _eventService.claimEventRewards(participation.eventId, characterId);
      
      if (rewards.isNotEmpty) {
        // Update crystals from rewards
        for (final reward in rewards) {
          if (reward.type == EventRewardType.crystals) {
            _crystals['blue'] = (_crystals['blue'] ?? 0) + reward.amount;
          }
        }

        // Mark participation as rewards claimed
        final index = _eventParticipations.indexWhere((p) => p.id == participationId);
        if (index != -1) {
          _eventParticipations[index] = _eventParticipations[index].copyWith(
            rewardsReceived: {'claimed': true, 'date': DateTime.now().toIso8601String()},
          );
        }

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to claim event rewards: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get event leaderboard
  Future<List<EventLeaderboardEntry>> getEventLeaderboard(String eventId) async {
    try {
      return await _eventService.getEventLeaderboard(eventId);
    } catch (e) {
      _setError('Failed to get event leaderboard: $e');
      return [];
    }
  }

  /// Get habit completion history
  Future<List<HabitCompletion>> getHabitHistory(String characterId, {int days = 30}) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      // Mock habit completion history - replace with actual implementation
      return [];
      // TODO: return await _habitService.getCompletionHistory(characterId, startDate, endDate);
    } catch (e) {
      _setError('Failed to get habit history: $e');
      return [];
    }
  }

  /// Use crystals for gacha
  Future<Map<String, dynamic>?> useCrystalsForGacha(String type, int amount) async {
    if ((_crystals[type] ?? 0) < amount) {
      _setError('結晶が不足しています');
      return null;
    }

    try {
      // This would call a gacha service
      // For now, simulate gacha results
      _crystals[type] = (_crystals[type] ?? 0) - amount;
      notifyListeners();

      return {
        'items': [
          {'type': 'equipment', 'name': 'レアソード', 'rarity': 'rare'},
          {'type': 'booster', 'name': '経験値ブースター', 'duration': 3600}, // 1 hour
        ],
        'crystals_used': {'type': type, 'amount': amount},
      };
    } catch (e) {
      _setError('ガチャでエラーが発生しました: $e');
      return null;
    }
  }

  /// Start real-time event subscription
  void _startEventSubscription() {
    // TODO: Replace with actual streaming when implemented
    /*
    _eventSubscription = _eventService.streamActiveEvents().listen(
      (events) {
        _activeEvents = events;
        notifyListeners();
      },
      onError: (error) {
        _setError('Event stream error: $error');
      },
    );
    */
  }

  /// Start real-time raid subscription
  void _startRaidSubscription() {
    // TODO: Replace with actual streaming when implemented
    /*
    _raidSubscription = _eventService.streamRaidBosses().listen(
      (raids) {
        if (raids.isNotEmpty) {
          _currentRaidBoss = raids.first;
        } else {
          _currentRaidBoss = null;
        }
        notifyListeners();
      },
      onError: (error) {
        _setError('Raid stream error: $error');
      },
    );
    */
  }

  /// Refresh all game data
  Future<void> refresh(String characterId) async {
    await initializeGame(characterId);
  }

  /// Get total crystal count
  int getTotalCrystals() {
    return totalBlueCrystals + totalGreenCrystals + totalGoldCrystals + totalRainbowCrystals;
  }

  /// Check if character can complete habit (stamina check)
  bool canCompleteHabit(String habitId, int currentStamina) {
    final habit = _tasks.firstWhere((Task h) => h.id == habitId);
    final staminaCost = habit.difficulty.staminaCost;
    return currentStamina >= staminaCost;
  }

  /// Get habits that can be completed today
  List<Task> getCompletableHabits(int currentStamina) {
    return _tasks.where((Task habit) => 
      !habit.isCompleted && 
      currentStamina >= habit.difficulty.staminaCost
    ).toList();
  }
  
  /// Create a new habit
  Future<void> createHabit({
    required String name,
    required String description,
    required String category,
    required int difficulty,
  }) async {
    try {
      _setLoading(true);
      
      // Create new habit with proper difficulty mapping
      final taskDifficulty = _mapDifficultyToTaskDifficulty(difficulty);
      final experienceReward = difficulty * 10;
      
      final newHabit = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: name,
        description: description.isEmpty ? name : description,
        difficulty: taskDifficulty,
        experienceReward: experienceReward,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isCompleted: false,
        chainLength: 0,
      );
      
      // Add to habits list
      _tasks.add(newHabit);
      
      // In a real app, this would save to the database
      // await _habitService.createHabit(newHabit);
      
      notifyListeners();
    } catch (e) {
      _setError('習慣の作成に失敗しました: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  TaskDifficulty _mapDifficultyToTaskDifficulty(int difficulty) {
    switch (difficulty) {
      case 1: return TaskDifficulty.easy;
      case 2: return TaskDifficulty.normal;
      case 3: return TaskDifficulty.normal;
      case 4: return TaskDifficulty.hard;
      case 5: return TaskDifficulty.hard;
      default: return TaskDifficulty.normal;
    }
  }

  /// Attack raid boss with battle points
  Future<bool> attackRaidBoss(String characterId, String raidBossId, int battlePoints) async {
    if (_currentRaidBoss == null || !_currentRaidBoss!.isActive) {
      _setError('レイドボスが利用できません');
      return false;
    }
    
    try {
      _setLoading(true);
      // This would call the raid service to attack the boss
      // For now, simulate the attack
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Update raid boss health (mock implementation)
      // In real implementation, this would come from the server
      return true;
    } catch (e) {
      _setError('レイドボス攻撃でエラーが発生しました: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Method for loading game data
  Future<void> loadData() async {
    _setLoading(true);
    try {
      // Load habits, events, and other game data
      // Load mock data or call existing methods
      await Future.delayed(const Duration(milliseconds: 500));
      // Mock loading - replace with actual service calls when implemented
    } catch (e) {
      print('Error loading game data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Getter for daily stats
  Map<String, dynamic> get dailyStats {
    return {
      'habitsCompleted': _tasks.where((Task h) => h.isCompleted).length,
      'totalHabits': _tasks.length,
      'experienceGained': 0, // Mock data
      'crystalsEarned': 0, // Mock data
      'battlePointsEarned': 0, // Mock data
    };
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _raidSubscription?.cancel();
    super.dispose();
  }
}
