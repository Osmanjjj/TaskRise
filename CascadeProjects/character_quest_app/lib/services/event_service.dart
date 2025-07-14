import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event.dart';
import '../models/character.dart' as char;
import '../models/crystal.dart';
import 'crystal_service.dart';

class EventService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CrystalService _crystalService = CrystalService();

  /// Get active events
  Future<List<GameEvent>> getActiveEvents() async {
    try {
      final now = DateTime.now();
      final response = await _supabase
          .from('game_events')
          .select()
          .lte('start_date', now.toIso8601String())
          .gte('end_date', now.toIso8601String())
          .eq('is_active', true)
          .order('priority', ascending: false);

      return (response as List)
          .map((json) => GameEvent.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting active events: $e');
      return [];
    }
  }

  /// Get upcoming events
  Future<List<GameEvent>> getUpcomingEvents({int limit = 10}) async {
    try {
      final now = DateTime.now();
      final response = await _supabase
          .from('game_events')
          .select()
          .gt('start_date', now.toIso8601String())
          .eq('is_active', true)
          .order('start_date', ascending: true)
          .limit(limit);

      return (response as List)
          .map((json) => GameEvent.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting upcoming events: $e');
      return [];
    }
  }

  /// Get past events
  Future<List<GameEvent>> getPastEvents({int limit = 20}) async {
    try {
      final now = DateTime.now();
      final response = await _supabase
          .from('game_events')
          .select()
          .lt('end_date', now.toIso8601String())
          .order('end_date', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => GameEvent.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting past events: $e');
      return [];
    }
  }

  /// Join event
  Future<EventParticipation?> joinEvent(String eventId, String characterId) async {
    try {
      // Check if already participating
      final existing = await _supabase
          .from('event_participations')
          .select()
          .eq('event_id', eventId)
          .eq('character_id', characterId)
          .maybeSingle();

      if (existing != null) {
        return EventParticipation.fromJson(existing);
      }

      // Get event details
      final event = await getEvent(eventId);
      if (event == null) return null;

      // Check if event is still active
      if (!event.isActive || event.hasEnded) return null;

      // Check character eligibility
      final character = await _getCharacter(characterId);
      if (character == null) return null;

      if (character.level < event.minLevel) return null;

      // Create participation record
      final response = await _supabase
          .from('event_participations')
          .insert({
            'event_id': eventId,
            'character_id': characterId,
            'joined_at': DateTime.now().toIso8601String(),
            'progress': 0,
            'status': EventParticipationStatus.active.name,
            'rewards_claimed': false,
          })
          .select()
          .single();

      return EventParticipation.fromJson(response);
    } catch (e) {
      print('Error joining event: $e');
      return null;
    }
  }

  /// Update event progress
  Future<bool> updateEventProgress(String eventId, String characterId, int progressAmount) async {
    try {
      final participation = await _supabase
          .from('event_participations')
          .select()
          .eq('event_id', eventId)
          .eq('character_id', characterId)
          .maybeSingle();

      if (participation == null) return false;

      final currentProgress = participation['progress'] ?? 0;
      final newProgress = currentProgress + progressAmount;

      await _supabase
          .from('event_participations')
          .update({
            'progress': newProgress,
            'last_activity': DateTime.now().toIso8601String(),
          })
          .eq('event_id', eventId)
          .eq('character_id', characterId);

      // Check if event objectives are completed
      await _checkEventCompletion(eventId, characterId, newProgress);

      return true;
    } catch (e) {
      print('Error updating event progress: $e');
      return false;
    }
  }

  /// Claim event rewards
  Future<List<EventReward>> claimEventRewards(String eventId, String characterId) async {
    try {
      final participation = await _supabase
          .from('event_participations')
          .select()
          .eq('event_id', eventId)
          .eq('character_id', characterId)
          .single();

      final eventParticipation = EventParticipation.fromJson(participation);

      if (eventParticipation.rewardsClaimed) {
        return []; // Already claimed
      }

      if (eventParticipation.status != EventParticipationStatus.completed) {
        return []; // Not eligible for rewards
      }

      // Get event details
      final event = await getEvent(eventId);
      if (event == null) return [];

      // Calculate rewards based on progress and event type
      final rewards = _calculateEventRewards(event, eventParticipation);

      // Apply rewards to character
      await _applyEventRewards(characterId, rewards);

      // Mark rewards as claimed
      await _supabase
          .from('event_participations')
          .update({
            'rewards_claimed': true,
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('event_id', eventId)
          .eq('character_id', characterId);

      return rewards;
    } catch (e) {
      print('Error claiming event rewards: $e');
      return [];
    }
  }

  /// Get character's event participation
  Future<List<EventParticipation>> getCharacterEvents(String characterId) async {
    try {
      final response = await _supabase
          .from('event_participations')
          .select('''
            *,
            event:game_events(*)
          ''')
          .eq('character_id', characterId)
          .order('joined_at', ascending: false);

      return (response as List)
          .map((json) => EventParticipation.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting character events: $e');
      return [];
    }
  }

  /// Get character's event participations
  Future<List<EventParticipation>> getCharacterEventParticipations(String characterId) async {
    return getCharacterEvents(characterId);
  }

  /// Get event leaderboard
  Future<List<EventLeaderboardEntry>> getEventLeaderboard(String eventId, {int limit = 50}) async {
    try {
      final response = await _supabase
          .rpc('get_event_leaderboard', params: {
            'event_id_param': eventId,
            'limit_param': limit,
          });

      return (response as List)
          .map((json) => EventLeaderboardEntry.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting event leaderboard: $e');
      return [];
    }
  }

  /// Get specific event
  Future<GameEvent?> getEvent(String eventId) async {
    try {
      final response = await _supabase
          .from('game_events')
          .select()
          .eq('id', eventId)
          .single();

      return GameEvent.fromJson(response);
    } catch (e) {
      print('Error getting event: $e');
      return null;
    }
  }

  /// Create event (admin function)
  Future<GameEvent?> createEvent({
    required String title,
    required String description,
    required EventType type,
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, dynamic> objectives,
    required List<Map<String, dynamic>> rewards,
    int minLevel = 1,
    int priority = 0,
  }) async {
    try {
      final response = await _supabase
          .from('game_events')
          .insert({
            'title': title,
            'description': description,
            'event_type': type.name,
            'start_date': startDate.toIso8601String(),
            'end_date': endDate.toIso8601String(),
            'objectives': objectives,
            'rewards': rewards,
            'min_level': minLevel,
            'priority': priority,
            'is_active': true,
          })
          .select()
          .single();

      return GameEvent.fromJson(response);
    } catch (e) {
      print('Error creating event: $e');
      return null;
    }
  }

  /// Deactivate event (admin function)
  Future<bool> deactivateEvent(String eventId) async {
    try {
      await _supabase
          .from('game_events')
          .update({'is_active': false})
          .eq('id', eventId);

      return true;
    } catch (e) {
      print('Error deactivating event: $e');
      return false;
    }
  }

  /// Get event statistics (admin function)
  Future<EventStatistics> getEventStatistics(String eventId) async {
    try {
      final response = await _supabase
          .rpc('get_event_statistics', params: {
            'event_id_param': eventId,
          });

      return EventStatistics.fromJson(response);
    } catch (e) {
      print('Error getting event statistics: $e');
      return EventStatistics.empty();
    }
  }

  /// Helper methods
  List<EventReward> _calculateEventRewards(GameEvent event, EventParticipation participation) {
    final rewards = <EventReward>[];

    // Base rewards from event configuration
    // Convert rewards map to list and iterate
    final rewardsList = event.rewards['items'] as List<dynamic>? ?? [];
    for (final rewardData in rewardsList) {
      final type = EventRewardType.values.firstWhere(
        (t) => t.name == rewardData['type'],
        orElse: () => EventRewardType.experience,
      );
      
      final amount = rewardData['amount'] ?? 0;
      
      rewards.add(EventReward(
        type: type,
        amount: amount,
        description: rewardData['description'] ?? '',
      ));
    }

    // Bonus rewards based on participation level
    final progressPercent = participation.progress / (event.objectives['target_progress'] ?? 100);
    
    if (progressPercent >= 1.0) {
      // Completion bonus
      rewards.add(EventReward(
        type: EventRewardType.crystals,
        amount: 5,
        description: 'イベント完走ボーナス',
      ));
    }

    if (progressPercent >= 1.5) {
      // Overachiever bonus
      rewards.add(EventReward(
        type: EventRewardType.rare_item,
        amount: 1,
        description: 'オーバーアチーバーボーナス',
      ));
    }

    return rewards;
  }

  Future<void> _applyEventRewards(String characterId, List<EventReward> rewards) async {
    // Get current character stats
    final characterData = await _supabase
        .from('characters')
        .select('experience, battle_points, stamina, max_stamina')
        .eq('id', characterId)
        .single();
    
    int currentExp = characterData['experience'] ?? 0;
    int currentBP = characterData['battle_points'] ?? 0;
    int currentStamina = characterData['stamina'] ?? 0;
    int maxStamina = characterData['max_stamina'] ?? 100;
    
    for (final reward in rewards) {
      switch (reward.type) {
        case EventRewardType.experience:
          currentExp += reward.amount.toInt();
          break;
        
        case EventRewardType.crystals:
          await _crystalService.addCrystals(characterId, {
            CrystalType.blue: reward.amount,
          });
          break;
        
        case EventRewardType.battle_points:
          currentBP += reward.amount.toInt();
          break;
        
        case EventRewardType.stamina:
          currentStamina = (currentStamina + reward.amount.toInt()).clamp(0, maxStamina);
          break;
        
        case EventRewardType.rare_item:
          // Add to character's inventory
          await _crystalService.addCrystals(characterId, {
            CrystalType.gold: reward.amount,
          });
          break;
        
        case EventRewardType.special_ability:
          // TODO: Implement special abilities system
          break;
      }
    }
    
    // Update character with accumulated changes
    await _supabase
        .from('characters')
        .update({
          'experience': currentExp,
          'battle_points': currentBP,
          'stamina': currentStamina,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', characterId);
  }

  Future<void> _checkEventCompletion(String eventId, String characterId, int newProgress) async {
    final event = await getEvent(eventId);
    if (event == null) return;

    final targetProgress = event.objectives['target_progress'] ?? 100;
    
    if (newProgress >= targetProgress) {
      await _supabase
          .from('event_participations')
          .update({
            'status': EventParticipationStatus.completed.name,
          })
          .eq('event_id', eventId)
          .eq('character_id', characterId);
    }
  }

  Future<char.Character?> _getCharacter(String characterId) async {
    try {
      final response = await _supabase
          .from('characters')
          .select()
          .eq('id', characterId)
          .single();
      return char.Character.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Stream active events
  Stream<List<GameEvent>> watchActiveEvents() {
    return _supabase
        .from('game_events')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .order('priority', ascending: false)
        .map((data) => data.map((json) => GameEvent.fromJson(json)).toList());
  }

  /// Stream character's event participations
  Stream<List<EventParticipation>> watchCharacterEvents(String characterId) {
    return _supabase
        .from('event_participations')
        .stream(primaryKey: ['id'])
        .eq('character_id', characterId)
        .order('joined_at', ascending: false)
        .map((data) => data.map((json) => EventParticipation.fromJson(json)).toList());
  }

  /// Stream event leaderboard
  Stream<List<EventLeaderboardEntry>> watchEventLeaderboard(String eventId) {
    return _supabase
        .from('event_participations')
        .stream(primaryKey: ['id'])
        .eq('event_id', eventId)
        .order('progress', ascending: false)
        .map((data) => data.map((json) => EventLeaderboardEntry.fromParticipation(json)).toList());
  }
}

class EventLeaderboardEntry {
  final String characterId;
  final String characterName;
  final String? avatarUrl;
  final int level;
  final int progress;
  final int rank;
  final DateTime lastActivity;

  EventLeaderboardEntry({
    required this.characterId,
    required this.characterName,
    this.avatarUrl,
    required this.level,
    required this.progress,
    required this.rank,
    required this.lastActivity,
  });

  factory EventLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return EventLeaderboardEntry(
      characterId: json['character_id'],
      characterName: json['character_name'],
      avatarUrl: json['avatar_url'],
      level: json['level'],
      progress: json['progress'],
      rank: json['rank'] ?? 0,
      lastActivity: DateTime.parse(json['last_activity']),
    );
  }

  factory EventLeaderboardEntry.fromParticipation(Map<String, dynamic> json) {
    return EventLeaderboardEntry(
      characterId: json['character_id'],
      characterName: json['character_name'] ?? 'Unknown',
      avatarUrl: json['avatar_url'],
      level: json['level'] ?? 1,
      progress: json['progress'] ?? 0,
      rank: 0, // Will be set by ordering
      lastActivity: DateTime.parse(json['last_activity'] ?? DateTime.now().toIso8601String()),
    );
  }

  String get displayRank => '#$rank';
  String get progressDisplay => '$progress pts';
}

class EventStatistics {
  final int totalParticipants;
  final int activeParticipants;
  final int completedParticipants;
  final double averageProgress;
  final int totalRewardsClaimed;
  final Map<String, int> progressDistribution;

  EventStatistics({
    required this.totalParticipants,
    required this.activeParticipants,
    required this.completedParticipants,
    required this.averageProgress,
    required this.totalRewardsClaimed,
    required this.progressDistribution,
  });

  factory EventStatistics.fromJson(Map<String, dynamic> json) {
    return EventStatistics(
      totalParticipants: json['total_participants'] ?? 0,
      activeParticipants: json['active_participants'] ?? 0,
      completedParticipants: json['completed_participants'] ?? 0,
      averageProgress: (json['average_progress'] as num?)?.toDouble() ?? 0.0,
      totalRewardsClaimed: json['total_rewards_claimed'] ?? 0,
      progressDistribution: Map<String, int>.from(json['progress_distribution'] ?? {}),
    );
  }

  factory EventStatistics.empty() {
    return EventStatistics(
      totalParticipants: 0,
      activeParticipants: 0,
      completedParticipants: 0,
      averageProgress: 0.0,
      totalRewardsClaimed: 0,
      progressDistribution: {},
    );
  }

  double get completionRate => totalParticipants > 0 ? (completedParticipants / totalParticipants) * 100 : 0.0;
  String get completionRateDisplay => '${completionRate.toStringAsFixed(1)}%';
}
