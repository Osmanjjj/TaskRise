// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Friendship _$FriendshipFromJson(Map<String, dynamic> json) => Friendship(
  id: json['id'] as String,
  userId: json['userId'] as String,
  friendId: json['friendId'] as String,
  status:
      $enumDecodeNullable(_$FriendshipStatusEnumMap, json['status']) ??
      FriendshipStatus.pending,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  acceptedAt: json['acceptedAt'] == null
      ? null
      : DateTime.parse(json['acceptedAt'] as String),
  friendUsername: json['friendUsername'] as String,
  friendDisplayName: json['friendDisplayName'] as String?,
  friendAvatarUrl: json['friendAvatarUrl'] as String?,
  friendLevel: (json['friendLevel'] as num?)?.toInt() ?? 1,
  friendTotalHabits: (json['friendTotalHabits'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$FriendshipToJson(Friendship instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'friendId': instance.friendId,
      'status': _$FriendshipStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'acceptedAt': instance.acceptedAt?.toIso8601String(),
      'friendUsername': instance.friendUsername,
      'friendDisplayName': instance.friendDisplayName,
      'friendAvatarUrl': instance.friendAvatarUrl,
      'friendLevel': instance.friendLevel,
      'friendTotalHabits': instance.friendTotalHabits,
    };

const _$FriendshipStatusEnumMap = {
  FriendshipStatus.pending: 'pending',
  FriendshipStatus.accepted: 'accepted',
  FriendshipStatus.blocked: 'blocked',
  FriendshipStatus.declined: 'declined',
};

FriendRequest _$FriendRequestFromJson(Map<String, dynamic> json) =>
    FriendRequest(
      id: json['id'] as String,
      fromUserId: json['fromUserId'] as String,
      toUserId: json['toUserId'] as String,
      requestType:
          $enumDecodeNullable(_$RequestTypeEnumMap, json['requestType']) ??
          RequestType.friendRequest,
      message: json['message'] as String?,
      status:
          $enumDecodeNullable(_$FriendshipStatusEnumMap, json['status']) ??
          FriendshipStatus.pending,
      requestData: json['requestData'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      respondedAt: json['respondedAt'] == null
          ? null
          : DateTime.parse(json['respondedAt'] as String),
    );

Map<String, dynamic> _$FriendRequestToJson(FriendRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fromUserId': instance.fromUserId,
      'toUserId': instance.toUserId,
      'requestType': _$RequestTypeEnumMap[instance.requestType]!,
      'message': instance.message,
      'status': _$FriendshipStatusEnumMap[instance.status]!,
      'requestData': instance.requestData,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'respondedAt': instance.respondedAt?.toIso8601String(),
    };

const _$RequestTypeEnumMap = {
  RequestType.friendRequest: 'friend_request',
  RequestType.guildInvite: 'guild_invite',
  RequestType.mentorRequest: 'mentor_request',
  RequestType.supportRequest: 'support_request',
};

SupportMessage _$SupportMessageFromJson(Map<String, dynamic> json) =>
    SupportMessage(
      id: json['id'] as String,
      fromUserId: json['fromUserId'] as String,
      toUserId: json['toUserId'] as String,
      supportType: $enumDecode(_$SupportTypeEnumMap, json['supportType']),
      message: json['message'] as String,
      supportData: json['supportData'] as Map<String, dynamic>?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['readAt'] == null
          ? null
          : DateTime.parse(json['readAt'] as String),
    );

Map<String, dynamic> _$SupportMessageToJson(SupportMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fromUserId': instance.fromUserId,
      'toUserId': instance.toUserId,
      'supportType': _$SupportTypeEnumMap[instance.supportType]!,
      'message': instance.message,
      'supportData': instance.supportData,
      'isRead': instance.isRead,
      'createdAt': instance.createdAt.toIso8601String(),
      'readAt': instance.readAt?.toIso8601String(),
    };

const _$SupportTypeEnumMap = {
  SupportType.motivation: 'motivation',
  SupportType.advice: 'advice',
  SupportType.challenge: 'challenge',
  SupportType.celebration: 'celebration',
};

UserSocialStats _$UserSocialStatsFromJson(Map<String, dynamic> json) =>
    UserSocialStats(
      userId: json['userId'] as String,
      totalFriends: (json['totalFriends'] as num?)?.toInt() ?? 0,
      supportMessagesSent: (json['supportMessagesSent'] as num?)?.toInt() ?? 0,
      supportMessagesReceived:
          (json['supportMessagesReceived'] as num?)?.toInt() ?? 0,
      helpfulVotes: (json['helpfulVotes'] as num?)?.toInt() ?? 0,
      mentorshipCount: (json['mentorshipCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$UserSocialStatsToJson(UserSocialStats instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'totalFriends': instance.totalFriends,
      'supportMessagesSent': instance.supportMessagesSent,
      'supportMessagesReceived': instance.supportMessagesReceived,
      'helpfulVotes': instance.helpfulVotes,
      'mentorshipCount': instance.mentorshipCount,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
