enum TaskStatus { pending, completed, failed }

enum TaskDifficulty {
  easy(displayName: '簡単', color: 0xFF4CAF50, staminaCost: 1, icon: 'easy_icon'),
  normal(displayName: '普通', color: 0xFFFF9800, staminaCost: 2, icon: 'normal_icon'),
  hard(displayName: '難しい', color: 0xFFF44336, staminaCost: 3, icon: 'hard_icon');

  const TaskDifficulty({
    required this.displayName,
    required this.color,
    required this.staminaCost,
    required this.icon,
  });

  final String displayName;
  final int color;
  final int staminaCost;
  final String icon;
}

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
  
  // Habit-related properties for compatibility
  final int chainLength;
  final bool isCompleted;

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
    this.chainLength = 0,
    bool? isCompleted,
  }) : isCompleted = isCompleted ?? (status == TaskStatus.completed);

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
      chainLength: json['chain_length'] ?? 0,
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
      'chain_length': chainLength,
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
    int? chainLength,
    bool? isCompleted,
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
      chainLength: chainLength ?? this.chainLength,
      isCompleted: isCompleted,
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
