import 'character.dart';

class MentorRelationship {
  final String id;
  final String mentorId;
  final String menteeId;
  final MentorshipStatus status;
  final int mentorRewardsEarned;
  final double menteeProgressBonus;
  final DateTime startedAt;
  final DateTime? endedAt;
  
  // Populated via joins
  final Character? mentor;
  final Character? mentee;

  MentorRelationship({
    required this.id,
    required this.mentorId,
    required this.menteeId,
    required this.status,
    this.mentorRewardsEarned = 0,
    this.menteeProgressBonus = 1.0,
    required this.startedAt,
    this.endedAt,
    this.mentor,
    this.mentee,
  });

  factory MentorRelationship.fromJson(Map<String, dynamic> json) {
    return MentorRelationship(
      id: json['id'],
      mentorId: json['mentor_id'],
      menteeId: json['mentee_id'],
      status: MentorshipStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => MentorshipStatus.pending,
      ),
      mentorRewardsEarned: json['mentor_rewards_earned'] ?? 0,
      menteeProgressBonus: (json['mentee_progress_bonus'] as num?)?.toDouble() ?? 1.0,
      startedAt: DateTime.parse(json['started_at']),
      endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at']) : null,
      mentor: json['mentor'] != null ? Character.fromJson(json['mentor']) : null,
      mentee: json['mentee'] != null ? Character.fromJson(json['mentee']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mentor_id': mentorId,
      'mentee_id': menteeId,
      'status': status.name,
      'mentor_rewards_earned': mentorRewardsEarned,
      'mentee_progress_bonus': menteeProgressBonus,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
    };
  }

  Duration get relationshipDuration {
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt);
  }

  bool get isActive => status == MentorshipStatus.active;
  
  bool get isCompleted => status == MentorshipStatus.completed;
  
  int get daysActive => relationshipDuration.inDays;
  
  double get progressBonusPercentage => (menteeProgressBonus - 1.0) * 100;

  MentorRelationship copyWith({
    String? id,
    String? mentorId,
    String? menteeId,
    MentorshipStatus? status,
    int? mentorRewardsEarned,
    double? menteeProgressBonus,
    DateTime? startedAt,
    DateTime? endedAt,
    Character? mentor,
    Character? mentee,
  }) {
    return MentorRelationship(
      id: id ?? this.id,
      mentorId: mentorId ?? this.mentorId,
      menteeId: menteeId ?? this.menteeId,
      status: status ?? this.status,
      mentorRewardsEarned: mentorRewardsEarned ?? this.mentorRewardsEarned,
      menteeProgressBonus: menteeProgressBonus ?? this.menteeProgressBonus,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      mentor: mentor ?? this.mentor,
      mentee: mentee ?? this.mentee,
    );
  }
}

enum MentorshipStatus {
  pending(name: 'pending', displayName: '承認待ち', color: 0xFFFFB74D),
  active(name: 'active', displayName: 'アクティブ', color: 0xFF4CAF50),
  completed(name: 'completed', displayName: '完了', color: 0xFF2196F3),
  cancelled(name: 'cancelled', displayName: 'キャンセル', color: 0xFF757575);

  const MentorshipStatus({
    required this.name,
    required this.displayName,
    required this.color,
  });

  final String name;
  final String displayName;
  final int color;
}

class MentorStats {
  final String mentorId;
  final int totalMentees;
  final int activeMentees;
  final int completedMentorships;
  final int totalRewardsEarned;
  final double averageMenteeProgress;
  final int mentorRank;
  final DateTime lastActivityDate;

  MentorStats({
    required this.mentorId,
    required this.totalMentees,
    required this.activeMentees,
    required this.completedMentorships,
    required this.totalRewardsEarned,
    required this.averageMenteeProgress,
    required this.mentorRank,
    required this.lastActivityDate,
  });

  factory MentorStats.fromJson(Map<String, dynamic> json) {
    return MentorStats(
      mentorId: json['mentor_id'],
      totalMentees: json['total_mentees'] ?? 0,
      activeMentees: json['active_mentees'] ?? 0,
      completedMentorships: json['completed_mentorships'] ?? 0,
      totalRewardsEarned: json['total_rewards_earned'] ?? 0,
      averageMenteeProgress: (json['average_mentee_progress'] as num?)?.toDouble() ?? 0.0,
      mentorRank: json['mentor_rank'] ?? 1,
      lastActivityDate: DateTime.parse(json['last_activity_date']),
    );
  }

  MentorTier get tier {
    if (completedMentorships >= 50) return MentorTier.grandmaster;
    if (completedMentorships >= 25) return MentorTier.master;
    if (completedMentorships >= 10) return MentorTier.expert;
    if (completedMentorships >= 5) return MentorTier.experienced;
    return MentorTier.novice;
  }

  bool get isEligibleForPremium => completedMentorships >= 3 && averageMenteeProgress > 0.8;

  double get successRate => totalMentees > 0 ? completedMentorships / totalMentees : 0.0;
}

enum MentorTier {
  novice(name: 'novice', displayName: '新人メンター', minMentorships: 0, color: 0xFF9E9E9E, maxMentees: 1),
  experienced(name: 'experienced', displayName: '経験豊富', minMentorships: 5, color: 0xFF4CAF50, maxMentees: 3),
  expert(name: 'expert', displayName: 'エキスパート', minMentorships: 10, color: 0xFF2196F3, maxMentees: 5),
  master(name: 'master', displayName: 'マスター', minMentorships: 25, color: 0xFF9C27B0, maxMentees: 8),
  grandmaster(name: 'grandmaster', displayName: 'グランドマスター', minMentorships: 50, color: 0xFFFFD700, maxMentees: 12);

  const MentorTier({
    required this.name,
    required this.displayName,
    required this.minMentorships,
    required this.color,
    required this.maxMentees,
  });

  final String name;
  final String displayName;
  final int minMentorships;
  final int color;
  final int maxMentees;
}

