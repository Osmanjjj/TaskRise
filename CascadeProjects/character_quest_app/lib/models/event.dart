class GameEvent {
  final String id;
  final String name;
  final String description;
  final EventType type;
  final DateTime startTime;
  final DateTime endTime;
  final Map<String, dynamic> rewards;
  final Map<String, dynamic> requirements;
  final bool isActive;
  final int maxParticipants;
  final int currentParticipants;
  final String? imageUrl;

  GameEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.rewards,
    required this.requirements,
    required this.isActive,
    this.maxParticipants = 0,
    this.currentParticipants = 0,
    this.imageUrl,
  });

  factory GameEvent.fromJson(Map<String, dynamic> json) {
    return GameEvent(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: EventType.values.firstWhere(
        (t) => t.name == json['event_type'],
        orElse: () => EventType.community,
      ),
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      rewards: json['rewards'] ?? {},
      requirements: json['requirements'] ?? {},
      isActive: json['is_active'] ?? true,
      maxParticipants: json['max_participants'] ?? 0,
      currentParticipants: json['current_participants'] ?? 0,
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'event_type': type.name,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'rewards': rewards,
      'requirements': requirements,
      'is_active': isActive,
      'max_participants': maxParticipants,
      'current_participants': currentParticipants,
      'image_url': imageUrl,
    };
  }

  bool get isLive {
    final now = DateTime.now();
    return isActive && now.isAfter(startTime) && now.isBefore(endTime);
  }

  bool get isUpcoming {
    final now = DateTime.now();
    return isActive && now.isBefore(startTime);
  }

  bool get isExpired {
    final now = DateTime.now();
    return now.isAfter(endTime);
  }
  
  // Alias for requirements (used in some service layers)
  Map<String, dynamic> get objectives => requirements;
  
  // Additional getters for compatibility
  String get title => name;
  DateTime get startDate => startTime;
  DateTime get endDate => endTime;
  
  // Additional compatibility getters
  bool get hasEnded => isExpired;
  int get minLevel => 1; // Default minimum level

  bool get hasSpaceAvailable {
    return maxParticipants == 0 || currentParticipants < maxParticipants;
  }

  Duration get timeRemaining {
    if (isExpired) return Duration.zero;
    if (isUpcoming) return startTime.difference(DateTime.now());
    return endTime.difference(DateTime.now());
  }

  String get statusDisplay {
    if (isLive) return '開催中';
    if (isUpcoming) return '開催予定';
    if (isExpired) return '終了';
    return '非アクティブ';
  }

  String get participantsDisplay {
    if (maxParticipants == 0) return '${currentParticipants}人参加中';
    return '${currentParticipants}/${maxParticipants}人';
  }

  EventParticipation createParticipation(String characterId) {
    return EventParticipation(
      id: '', // Will be set by database
      eventId: id,
      characterId: characterId,
      joinedAt: DateTime.now(),
      score: 0,
      completed: false,
      rewardsReceived: {},
    );
  }
}

enum EventType {
  raid(name: 'raid', displayName: 'レイドバトル', icon: '⚔️', color: 0xFFE91E63),
  community(name: 'community', displayName: 'コミュニティ', icon: '👥', color: 0xFF4CAF50),
  challenge(name: 'challenge', displayName: 'チャレンジ', icon: '🏆', color: 0xFFFF9800),
  seasonal(name: 'seasonal', displayName: 'シーズン', icon: '🎭', color: 0xFF9C27B0),
  guild(name: 'guild', displayName: 'ギルド', icon: '🏰', color: 0xFF2196F3);

  const EventType({
    required this.name,
    required this.displayName,
    required this.icon,
    required this.color,
  });

  final String name;
  final String displayName;
  final String icon;
  final int color;
}

enum EventParticipationStatus {
  notJoined,
  active,
  completed,
  failed;
}

class EventParticipation {
  final String id;
  final String eventId;
  final String characterId;
  final DateTime joinedAt;
  final int score;
  final bool completed;
  final Map<String, dynamic> rewardsReceived;
  final DateTime? completedAt;

  // Populated via joins
  final GameEvent? event;
  final Character? character;

  EventParticipation({
    required this.id,
    required this.eventId,
    required this.characterId,
    required this.joinedAt,
    required this.score,
    required this.completed,
    required this.rewardsReceived,
    this.completedAt,
    this.event,
    this.character,
  });

  factory EventParticipation.fromJson(Map<String, dynamic> json) {
    return EventParticipation(
      id: json['id'],
      eventId: json['event_id'],
      characterId: json['character_id'],
      joinedAt: DateTime.parse(json['joined_at']),
      score: json['score'] ?? 0,
      completed: json['completed'] ?? false,
      rewardsReceived: json['rewards_received'] ?? {},
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at']) 
          : null,
      event: json['event'] != null ? GameEvent.fromJson(json['event']) : null,
      character: json['character'] != null ? Character.fromJson(json['character']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'character_id': characterId,
      'joined_at': joinedAt.toIso8601String(),
      'score': score,
      'completed': completed,
      'rewards_received': rewardsReceived,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  Duration get participationDuration {
    final end = completedAt ?? DateTime.now();
    return end.difference(joinedAt);
  }

  bool get hasReceivedRewards => rewardsReceived.isNotEmpty;
  
  // Additional getters for compatibility
  int get progress => score;
  EventParticipationStatus get status => completed ? EventParticipationStatus.completed : EventParticipationStatus.active;
  bool get rewardsClaimed => hasReceivedRewards;

  EventParticipation copyWith({
    String? id,
    String? eventId,
    String? characterId,
    DateTime? joinedAt,
    int? score,
    bool? completed,
    Map<String, dynamic>? rewardsReceived,
    DateTime? completedAt,
    GameEvent? event,
    Character? character,
  }) {
    return EventParticipation(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      characterId: characterId ?? this.characterId,
      joinedAt: joinedAt ?? this.joinedAt,
      score: score ?? this.score,
      completed: completed ?? this.completed,
      rewardsReceived: rewardsReceived ?? this.rewardsReceived,
      completedAt: completedAt ?? this.completedAt,
      event: event ?? this.event,
      character: character ?? this.character,
    );
  }
}

// Temporary Character class - will import from character.dart
class Character {
  final String id;
  final String name;
  
  Character({required this.id, required this.name});
  
  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(id: json['id'], name: json['name']);
  }
}

enum EventRewardType {
  experience,
  crystals,
  battle_points,
  stamina,
  rare_item,
  special_ability,
}

class EventReward {
  final EventRewardType type;
  final int amount;
  final String? itemId;
  final String? description;

  EventReward({
    required this.type,
    required this.amount,
    this.itemId,
    this.description,
  });
}

class EventRewards {
  final int experience;
  final int battlePoints;
  final int stamina;
  final List<CrystalReward> crystals;
  final List<String> collectibles;
  final Map<String, dynamic> customRewards;

  EventRewards({
    this.experience = 0,
    this.battlePoints = 0,
    this.stamina = 0,
    this.crystals = const [],
    this.collectibles = const [],
    this.customRewards = const {},
  });

  factory EventRewards.fromJson(Map<String, dynamic> json) {
    return EventRewards(
      experience: json['experience'] ?? 0,
      battlePoints: json['battle_points'] ?? 0,
      stamina: json['stamina'] ?? 0,
      crystals: json['crystals'] != null
          ? (json['crystals'] as List)
              .map((c) => CrystalReward.fromJson(c))
              .toList()
          : [],
      collectibles: json['collectibles'] != null
          ? List<String>.from(json['collectibles'])
          : [],
      customRewards: json['custom_rewards'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'experience': experience,
      'battle_points': battlePoints,
      'stamina': stamina,
      'crystals': crystals.map((c) => c.toJson()).toList(),
      'collectibles': collectibles,
      'custom_rewards': customRewards,
    };
  }

  bool get isEmpty => 
      experience == 0 && 
      battlePoints == 0 && 
      stamina == 0 && 
      crystals.isEmpty && 
      collectibles.isEmpty && 
      customRewards.isEmpty;

  String get summaryText {
    final parts = <String>[];
    if (experience > 0) parts.add('${experience}XP');
    if (battlePoints > 0) parts.add('${battlePoints}BP');
    if (stamina > 0) parts.add('${stamina}スタミナ');
    if (crystals.isNotEmpty) parts.add('結晶${crystals.length}個');
    if (collectibles.isNotEmpty) parts.add('アイテム${collectibles.length}個');
    return parts.join(' + ');
  }
}

// Temporary CrystalReward class - will import from habit_completion.dart
class CrystalReward {
  final String type;
  final int amount;

  CrystalReward({required this.type, required this.amount});

  factory CrystalReward.fromJson(Map<String, dynamic> json) {
    return CrystalReward(type: json['type'], amount: json['amount']);
  }

  Map<String, dynamic> toJson() {
    return {'type': type, 'amount': amount};
  }
}
