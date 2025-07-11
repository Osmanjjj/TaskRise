enum TaskStatus { pending, completed, failed }

enum TaskDifficulty { easy, normal, hard }

class Task {
  final String id;
  final String title;
  final String? description;
  final TaskDifficulty difficulty;
  final TaskStatus status;
  final int experienceReward;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? characterId;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.difficulty = TaskDifficulty.normal,
    this.status = TaskStatus.pending,
    required this.experienceReward,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.characterId,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      difficulty: TaskDifficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => TaskDifficulty.normal,
      ),
      status: TaskStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TaskStatus.pending,
      ),
      experienceReward: json['experience_reward'] ?? 0,
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      characterId: json['character_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'difficulty': difficulty.name,
      'status': status.name,
      'experience_reward': experienceReward,
      'due_date': dueDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'character_id': characterId,
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskDifficulty? difficulty,
    TaskStatus? status,
    int? experienceReward,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? characterId,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      status: status ?? this.status,
      experienceReward: experienceReward ?? this.experienceReward,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      characterId: characterId ?? this.characterId,
    );
  }

  // Get experience reward based on difficulty
  static int getExperienceForDifficulty(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return 10;
      case TaskDifficulty.normal:
        return 25;
      case TaskDifficulty.hard:
        return 50;
    }
  }

  // Get color for difficulty
  static String getDifficultyColor(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return '#4CAF50'; // Green
      case TaskDifficulty.normal:
        return '#FF9800'; // Orange
      case TaskDifficulty.hard:
        return '#F44336'; // Red
    }
  }
}
