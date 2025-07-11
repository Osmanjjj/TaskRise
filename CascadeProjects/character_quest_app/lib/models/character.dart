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

  Character({
    required this.id,
    required this.name,
    this.level = 1,
    this.experience = 0,
    this.health = 100,
    this.attack = 10,
    this.defense = 5,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
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
    );
  }

  // Calculate experience needed for next level
  int get experienceToNextLevel {
    return (level * 100) - experience;
  }

  // Calculate level from experience
  int get calculatedLevel {
    return (experience / 100).floor() + 1;
  }
}
