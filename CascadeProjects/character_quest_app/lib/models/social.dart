import 'package:json_annotation/json_annotation.dart';

part 'social.g.dart';

enum FriendshipStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('accepted')
  accepted,
  @JsonValue('blocked')
  blocked,
  @JsonValue('declined')
  declined,
}

enum RequestType {
  @JsonValue('friend_request')
  friendRequest,
  @JsonValue('guild_invite')
  guildInvite,
  @JsonValue('mentor_request')
  mentorRequest,
  @JsonValue('support_request')
  supportRequest,
}

enum SupportType {
  @JsonValue('motivation')
  motivation,
  @JsonValue('advice')
  advice,
  @JsonValue('challenge')
  challenge,
  @JsonValue('celebration')
  celebration,
}

extension FriendshipStatusExtension on FriendshipStatus {
  String get displayName {
    switch (this) {
      case FriendshipStatus.pending:
        return '承認待ち';
      case FriendshipStatus.accepted:
        return 'フレンド';
      case FriendshipStatus.blocked:
        return 'ブロック済み';
      case FriendshipStatus.declined:
        return '拒否済み';
    }
  }

  bool get isActive => this == FriendshipStatus.accepted;
  bool get isPending => this == FriendshipStatus.pending;
  bool get isBlocked => this == FriendshipStatus.blocked;
}

extension SupportTypeExtension on SupportType {
  String get displayName {
    switch (this) {
      case SupportType.motivation:
        return '応援メッセージ';
      case SupportType.advice:
        return 'アドバイス';
      case SupportType.challenge:
        return 'チャレンジ';
      case SupportType.celebration:
        return 'お祝い';
    }
  }

  String get icon {
    switch (this) {
      case SupportType.motivation:
        return '💪';
      case SupportType.advice:
        return '💡';
      case SupportType.challenge:
        return '🎯';
      case SupportType.celebration:
        return '🎉';
    }
  }

  String get description {
    switch (this) {
      case SupportType.motivation:
        return 'フレンドを励ますメッセージを送ります';
      case SupportType.advice:
        return '習慣作りのアドバイスを共有します';
      case SupportType.challenge:
        return 'フレンドと一緒に挑戦します';
      case SupportType.celebration:
        return '成功を一緒にお祝いします';
    }
  }
}

@JsonSerializable()
class Friendship {
  final String id;
  final String userId;
  final String friendId;
  final FriendshipStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? acceptedAt;
  
  // Friend info (cached for performance)
  final String friendUsername;
  final String? friendDisplayName;
  final String? friendAvatarUrl;
  final int friendLevel;
  final int friendTotalHabits;

  const Friendship({
    required this.id,
    required this.userId,
    required this.friendId,
    this.status = FriendshipStatus.pending,
    required this.createdAt,
    required this.updatedAt,
    this.acceptedAt,
    required this.friendUsername,
    this.friendDisplayName,
    this.friendAvatarUrl,
    this.friendLevel = 1,
    this.friendTotalHabits = 0,
  });

  factory Friendship.fromJson(Map<String, dynamic> json) => _$FriendshipFromJson(json);
  Map<String, dynamic> toJson() => _$FriendshipToJson(this);

  String get friendDisplayNameOrUsername => friendDisplayName ?? friendUsername;
  bool get isActive => status.isActive;
  bool get isPending => status.isPending;
  Duration get friendshipDuration => acceptedAt != null 
      ? DateTime.now().difference(acceptedAt!)
      : Duration.zero;
  int get friendshipDays => friendshipDuration.inDays;

  Friendship copyWith({
    FriendshipStatus? status,
    DateTime? acceptedAt,
    String? friendUsername,
    String? friendDisplayName,
    String? friendAvatarUrl,
    int? friendLevel,
    int? friendTotalHabits,
  }) {
    return Friendship(
      id: id,
      userId: userId,
      friendId: friendId,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      acceptedAt: acceptedAt ?? this.acceptedAt,
      friendUsername: friendUsername ?? this.friendUsername,
      friendDisplayName: friendDisplayName ?? this.friendDisplayName,
      friendAvatarUrl: friendAvatarUrl ?? this.friendAvatarUrl,
      friendLevel: friendLevel ?? this.friendLevel,
      friendTotalHabits: friendTotalHabits ?? this.friendTotalHabits,
    );
  }

  @override
  String toString() {
    return 'Friendship(id: $id, friend: $friendUsername, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Friendship && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

@JsonSerializable()
class FriendRequest {
  final String id;
  final String fromUserId;
  final String toUserId;
  final RequestType requestType;
  final String? message;
  final FriendshipStatus status;
  final Map<String, dynamic>? requestData;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? respondedAt;

  const FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    this.requestType = RequestType.friendRequest,
    this.message,
    this.status = FriendshipStatus.pending,
    this.requestData,
    required this.createdAt,
    required this.updatedAt,
    this.respondedAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) => _$FriendRequestFromJson(json);
  Map<String, dynamic> toJson() => _$FriendRequestToJson(this);

  bool get isPending => status == FriendshipStatus.pending;
  bool get isAccepted => status == FriendshipStatus.accepted;
  bool get isDeclined => status == FriendshipStatus.declined;
  Duration get timeSinceCreated => DateTime.now().difference(createdAt);
  bool get isRecent => timeSinceCreated.inHours < 24;

  FriendRequest copyWith({
    String? message,
    FriendshipStatus? status,
    Map<String, dynamic>? requestData,
    DateTime? respondedAt,
  }) {
    return FriendRequest(
      id: id,
      fromUserId: fromUserId,
      toUserId: toUserId,
      requestType: requestType,
      message: message ?? this.message,
      status: status ?? this.status,
      requestData: requestData ?? this.requestData,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }

  @override
  String toString() {
    return 'FriendRequest(id: $id, from: $fromUserId, to: $toUserId, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FriendRequest && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

@JsonSerializable()
class SupportMessage {
  final String id;
  final String fromUserId;
  final String toUserId;
  final SupportType supportType;
  final String message;
  final Map<String, dynamic>? supportData;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  const SupportMessage({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.supportType,
    required this.message,
    this.supportData,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) => _$SupportMessageFromJson(json);
  Map<String, dynamic> toJson() => _$SupportMessageToJson(this);

  String get supportTypeDisplayName => supportType.displayName;
  String get supportTypeIcon => supportType.icon;
  Duration get timeSinceCreated => DateTime.now().difference(createdAt);
  bool get isRecent => timeSinceCreated.inHours < 24;
  bool get isUnread => !isRead;

  SupportMessage copyWith({
    String? message,
    Map<String, dynamic>? supportData,
    bool? isRead,
    DateTime? readAt,
  }) {
    return SupportMessage(
      id: id,
      fromUserId: fromUserId,
      toUserId: toUserId,
      supportType: supportType,
      message: message ?? this.message,
      supportData: supportData ?? this.supportData,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  @override
  String toString() {
    return 'SupportMessage(id: $id, from: $fromUserId, type: $supportType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SupportMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

@JsonSerializable()
class UserSocialStats {
  final String userId;
  final int totalFriends;
  final int supportMessagesSent;
  final int supportMessagesReceived;
  final int helpfulVotes;
  final int mentorshipCount;
  final DateTime createdAt;  
  final DateTime updatedAt;

  const UserSocialStats({
    required this.userId,
    this.totalFriends = 0,
    this.supportMessagesSent = 0,
    this.supportMessagesReceived = 0,
    this.helpfulVotes = 0,
    this.mentorshipCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserSocialStats.fromJson(Map<String, dynamic> json) => _$UserSocialStatsFromJson(json);
  Map<String, dynamic> toJson() => _$UserSocialStatsToJson(this);

  int get totalSocialInteractions => supportMessagesSent + supportMessagesReceived;
  double get socialActivityScore => (totalSocialInteractions * 0.5) + (helpfulVotes * 0.3) + (mentorshipCount * 1.0);
  bool get isSociallyActive => totalSocialInteractions > 10;
  bool get isMentor => mentorshipCount > 0;

  UserSocialStats copyWith({
    int? totalFriends,
    int? supportMessagesSent,
    int? supportMessagesReceived,
    int? helpfulVotes,
    int? mentorshipCount,
  }) {
    return UserSocialStats(
      userId: userId,
      totalFriends: totalFriends ?? this.totalFriends,
      supportMessagesSent: supportMessagesSent ?? this.supportMessagesSent,
      supportMessagesReceived: supportMessagesReceived ?? this.supportMessagesReceived,
      helpfulVotes: helpfulVotes ?? this.helpfulVotes,
      mentorshipCount: mentorshipCount ?? this.mentorshipCount,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'UserSocialStats(userId: $userId, friends: $totalFriends, score: ${socialActivityScore.toStringAsFixed(1)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserSocialStats && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}
