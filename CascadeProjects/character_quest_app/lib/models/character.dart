import 'crystal.dart';
import 'guild.dart';

class Character {
  final String id;
  final String name;
  final int level;
  final int experience;
  final int health;
  final int attack;
  final int defense;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // TaskRise extensions
  final int battlePoints;
  final int stamina;
  final int maxStamina;
  final String? guildId;
  final String? mentorId;
  final int totalCrystalsEarned;
  final int consecutiveDays;
  final DateTime lastActivityDate;
  
  // Populated via joins
  final Guild? guild;
  final Character? mentor;
  final CrystalInventory? crystalInventory;
  final List<String> equippedItems;

  Character({
    required this.id,
    required this.name,
    required this.level,
    required this.experience,
    required this.health,
    required this.attack,
    required this.defense,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
    this.battlePoints = 0,
    this.stamina = 0,
    this.maxStamina = 100,
    this.guildId,
    this.mentorId,
    this.totalCrystalsEarned = 0,
    this.consecutiveDays = 0,
    required this.lastActivityDate,
    this.guild,
    this.mentor,
    this.crystalInventory,
    this.equippedItems = const [],
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'],
      name: json['name'],
      level: json['level'] ?? 1,
      experience: json['experience'] ?? 0,
      health: json['health'] ?? 100,
      attack: json['attack'] ?? 10,
      defense: json['defense'] ?? 5,
      avatarUrl: json['avatar_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      battlePoints: json['battle_points'] ?? 0,
      stamina: json['stamina'] ?? 0,
      maxStamina: json['max_stamina'] ?? 100,
      guildId: json['guild_id'],
      mentorId: json['mentor_id'],
      totalCrystalsEarned: json['total_crystals_earned'] ?? 0,
      consecutiveDays: json['consecutive_days'] ?? 0,
      lastActivityDate: json['last_activity_date'] != null 
          ? DateTime.parse(json['last_activity_date'])
          : DateTime.now(),
      guild: json['guild'] != null ? Guild.fromJson(json['guild']) : null,
      mentor: json['mentor'] != null ? Character.fromJson(json['mentor']) : null,
      equippedItems: json['equipped_items'] != null 
          ? List<String>.from(json['equipped_items'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'level': level,
      'experience': experience,
      'health': health,
      'attack': attack,
      'defense': defense,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'battle_points': battlePoints,
      'stamina': stamina,
      'max_stamina': maxStamina,
      'guild_id': guildId,
      'mentor_id': mentorId,
      'total_crystals_earned': totalCrystalsEarned,
      'consecutive_days': consecutiveDays,
      'last_activity_date': lastActivityDate.toIso8601String(),
      'equipped_items': equippedItems,
    };
  }

  Character copyWith({
    String? id,
    String? name,
    int? level,
    int? experience,
    int? health,
    int? attack,
    int? defense,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? battlePoints,
    int? stamina,
    int? maxStamina,
    String? guildId,
    String? mentorId,
    int? totalCrystalsEarned,
    int? consecutiveDays,
    DateTime? lastActivityDate,
    Guild? guild,
    Character? mentor,
    CrystalInventory? crystalInventory,
    List<String>? equippedItems,
  }) {
    return Character(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      health: health ?? this.health,
      attack: attack ?? this.attack,
      defense: defense ?? this.defense,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      battlePoints: battlePoints ?? this.battlePoints,
      stamina: stamina ?? this.stamina,
      maxStamina: maxStamina ?? this.maxStamina,
      guildId: guildId ?? this.guildId,
      mentorId: mentorId ?? this.mentorId,
      totalCrystalsEarned: totalCrystalsEarned ?? this.totalCrystalsEarned,
      consecutiveDays: consecutiveDays ?? this.consecutiveDays,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      guild: guild ?? this.guild,
      mentor: mentor ?? this.mentor,
      crystalInventory: crystalInventory ?? this.crystalInventory,
      equippedItems: equippedItems ?? this.equippedItems,
    );
  }

  int get experienceToNextLevel {
    return (level * 100) - (experience % (level * 100));
  }

  double get experienceProgress {
    final currentLevelExp = experience % (level * 100);
    return currentLevelExp / (level * 100);
  }
  
  // Additional getters for compatibility
  int get experienceForCurrentLevel => experience % (level * 100);
  int get experienceForNextLevel => level * 100;
  double get levelProgress => experienceProgress;
  
  int get calculatedLevel {
    // Calculate level based on experience (every 100 XP = 1 level)
    return (experience / 100).floor() + 1;
  }
  
  // TaskRise specific getters
  double get staminaPercentage => maxStamina > 0 ? stamina / maxStamina : 0.0;
  
  bool get hasGuild => guildId != null;
  
  bool get hasMentor => mentorId != null;
  
  bool get isActiveToday {
    final now = DateTime.now();
    return lastActivityDate.year == now.year &&
           lastActivityDate.month == now.month &&
           lastActivityDate.day == now.day;
  }
  
  bool get canUseStamina => stamina > 0;
  
  bool get canParticipateInRaid => battlePoints > 0;
  
  int get powerLevel => attack + defense + (level * 10);
  
  String get experienceDisplay => '$experience XP';
  
  String get battlePointsDisplay => '$battlePoints BP';
  
  String get staminaDisplay => '$stamina / $maxStamina';
  
  String get streakDisplay => consecutiveDays > 0 
      ? '${consecutiveDays}日連続達成' 
      : '連続記録なし';
      
  CharacterRank get rank {
    if (level >= 50) return CharacterRank.legendary;
    if (level >= 30) return CharacterRank.epic;
    if (level >= 20) return CharacterRank.advanced;
    if (level >= 10) return CharacterRank.intermediate;
    return CharacterRank.beginner;
  }
}

enum CharacterRank {
  beginner(name: 'beginner', displayName: '初心者', minLevel: 1, color: 0xFF9E9E9E),
  intermediate(name: 'intermediate', displayName: '中級者', minLevel: 10, color: 0xFF4CAF50),
  advanced(name: 'advanced', displayName: '上級者', minLevel: 20, color: 0xFF2196F3),
  epic(name: 'epic', displayName: 'エキスパート', minLevel: 30, color: 0xFF9C27B0),
  legendary(name: 'legendary', displayName: 'レジェンド', minLevel: 50, color: 0xFFFFD700);

  const CharacterRank({
    required this.name,
    required this.displayName,
    required this.minLevel,
    required this.color,
  });

  final String name;
  final String displayName;
  final int minLevel;
  final int color;
}
