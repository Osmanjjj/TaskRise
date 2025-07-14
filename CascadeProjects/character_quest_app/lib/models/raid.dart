import 'package:json_annotation/json_annotation.dart';

part 'raid.g.dart';

enum EventType {
  @JsonValue('raid')
  raid,
  @JsonValue('tournament')
  tournament,
  @JsonValue('seasonal')
  seasonal,
  @JsonValue('weekly')
  weekly,
  @JsonValue('special')
  special,
}

enum EventStatus {
  @JsonValue('upcoming')
  upcoming,
  @JsonValue('active')
  active,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
}

enum BossType {
  @JsonValue('normal')
  normal,
  @JsonValue('elite')
  elite,
  @JsonValue('legendary')
  legendary,
}

enum BossDifficulty {
  @JsonValue('easy')
  easy,
  @JsonValue('normal')
  normal,
  @JsonValue('hard')
  hard,
  @JsonValue('extreme')
  extreme,
}

enum RaidBossStatus {
  @JsonValue('active')
  active,
  @JsonValue('defeated')
  defeated,
  @JsonValue('expired')
  expired,
}

extension EventTypeExtension on EventType {
  String get displayName {
    switch (this) {
      case EventType.raid:
        return 'レイドバトル';
      case EventType.tournament:
        return 'トーナメント';
      case EventType.seasonal:
        return 'シーズンイベント';
      case EventType.weekly:
        return 'ウィークリーイベント';
      case EventType.special:
        return 'スペシャルイベント';
    }
  }

  String get icon {
    switch (this) {
      case EventType.raid:
        return '⚔️';
      case EventType.tournament:
        return '🏆';
      case EventType.seasonal:
        return '🌸';
      case EventType.weekly:
        return '📅';
      case EventType.special:
        return '✨';
    }
  }
}



@JsonSerializable()
class RaidBoss {
  final String id;
  final String eventId;
  final String name;
  final BossType type;
  final BossDifficulty difficulty;
  final int maxHealth;
  final int currentHealth;
  final int defense;
  final Map<String, dynamic>? specialAbilities;
  final Map<String, dynamic>? weaknessTypes;
  final Map<String, dynamic>? rewards;
  final DateTime? endTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RaidBoss({
    required this.id,
    required this.eventId,
    required this.name,
    this.type = BossType.normal,
    this.difficulty = BossDifficulty.normal,
    required this.maxHealth,
    required this.currentHealth,
    this.defense = 0,
    this.specialAbilities,
    this.weaknessTypes,
    this.rewards,
    this.endTime,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RaidBoss.fromJson(Map<String, dynamic> json) => _$RaidBossFromJson(json);
  Map<String, dynamic> toJson() => _$RaidBossToJson(this);

  double get healthPercentage => (currentHealth / maxHealth).clamp(0.0, 1.0);
  bool get isAlive => currentHealth > 0;
  bool get isDefeated => currentHealth <= 0;
  bool get isActive => isAlive;
  int get damageReceived => maxHealth - currentHealth;

  RaidBoss copyWith({
    String? name,
    BossType? type,
    BossDifficulty? difficulty,
    int? maxHealth,
    int? currentHealth,
    int? defense,
    Map<String, dynamic>? specialAbilities,
    Map<String, dynamic>? weaknessTypes,
    Map<String, dynamic>? rewards,
    DateTime? endTime,
  }) {
    return RaidBoss(
      id: id,
      eventId: eventId,
      name: name ?? this.name,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      maxHealth: maxHealth ?? this.maxHealth,
      currentHealth: currentHealth ?? this.currentHealth,
      defense: defense ?? this.defense,
      specialAbilities: specialAbilities ?? this.specialAbilities,
      weaknessTypes: weaknessTypes ?? this.weaknessTypes,
      rewards: rewards ?? this.rewards,
      endTime: endTime ?? this.endTime,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'RaidBoss(id: $id, name: $name, health: $currentHealth/$maxHealth)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RaidBoss && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

@JsonSerializable()
class RaidParticipation {
  final String id;
  final String raidBossId;
  final String userId;
  final String characterId;
  final int damageDealt;
  final int battlePointsSpent;
  final int attacksCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RaidParticipation({
    required this.id,
    required this.raidBossId,
    required this.userId,
    required this.characterId,
    this.damageDealt = 0,
    this.battlePointsSpent = 0,
    this.attacksCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RaidParticipation.fromJson(Map<String, dynamic> json) => _$RaidParticipationFromJson(json);
  Map<String, dynamic> toJson() => _$RaidParticipationToJson(this);

  double get averageDamagePerAttack => attacksCount > 0 ? damageDealt / attacksCount : 0.0;
  double get damagePerBattlePoint => battlePointsSpent > 0 ? damageDealt / battlePointsSpent : 0.0;

  RaidParticipation copyWith({
    int? damageDealt,
    int? battlePointsSpent,
    int? attacksCount,
  }) {
    return RaidParticipation(
      id: id,
      raidBossId: raidBossId,
      userId: userId,
      characterId: characterId,
      damageDealt: damageDealt ?? this.damageDealt,
      battlePointsSpent: battlePointsSpent ?? this.battlePointsSpent,
      attacksCount: attacksCount ?? this.attacksCount,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'RaidParticipation(id: $id, damage: $damageDealt, attacks: $attacksCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RaidParticipation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}