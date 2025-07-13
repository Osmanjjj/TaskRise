import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/social.dart';

class SocialService {
  final _supabase = Supabase.instance.client;

  // Send friend request
  Future<FriendRequest?> sendFriendRequest(String targetUserId, {String? message}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      // Check if request already exists
      final existingRequest = await _supabase
          .from('friend_requests')
          .select()
          .eq('sender_id', user.id)
          .eq('receiver_id', targetUserId)
          .eq('status', 'pending')
          .maybeSingle();

      if (existingRequest != null) {
        return FriendRequest.fromJson(existingRequest);
      }

      // Check if they're already friends
      final existingFriendship = await _supabase
          .from('friendships')
          .select()
          .or('and(user_id.eq.${user.id},friend_id.eq.$targetUserId),and(user_id.eq.$targetUserId,friend_id.eq.${user.id})')
          .eq('status', 'accepted')
          .maybeSingle();

      if (existingFriendship != null) {
        throw Exception('Already friends');
      }

      final requestData = {
        'sender_id': user.id,
        'receiver_id': targetUserId,
        'request_type': RequestType.friend.name,
        'status': 'pending',
        'message': message,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('friend_requests')
          .insert(requestData)
          .select()
          .single();

      return FriendRequest.fromJson(response);
    } catch (e) {
      print('Error sending friend request: $e');
      return null;
    }
  }

  // Accept friend request
  Future<Friendship?> acceptFriendRequest(String requestId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      // Get the request
      final request = await _supabase
          .from('friend_requests')
          .select()
          .eq('id', requestId)
          .eq('receiver_id', user.id)
          .eq('status', 'pending')
          .maybeSingle();

      if (request == null) return null;

      final friendRequest = FriendRequest.fromJson(request);

      // Update request status
      await _supabase
          .from('friend_requests')
          .update({
            'status': 'accepted',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);

      // Create friendship records (bidirectional)
      final friendshipData = [
        {
          'user_id': user.id,
          'friend_id': friendRequest.senderId,
          'status': FriendshipStatus.accepted.name,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        {
          'user_id': friendRequest.senderId,
          'friend_id': user.id,
          'status': FriendshipStatus.accepted.name,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      ];

      final friendshipResponse = await _supabase
          .from('friendships')
          .insert(friendshipData)
          .select()
          .single();

      return Friendship.fromJson(friendshipResponse);
    } catch (e) {
      print('Error accepting friend request: $e');
      return null;
    }
  }

  // Decline friend request
  Future<bool> declineFriendRequest(String requestId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase
          .from('friend_requests')
          .update({
            'status': 'declined',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId)
          .eq('receiver_id', user.id);

      return true;
    } catch (e) {
      print('Error declining friend request: $e');
      return false;
    }
  }

  // Get pending friend requests received
  Future<List<FriendRequest>> getPendingReceivedRequests() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('friend_requests')
          .select('''
            *,
            sender:user_profiles!friend_requests_sender_id_fkey(username, display_name, avatar_url)
          ''')
          .eq('receiver_id', user.id)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => FriendRequest.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting pending requests: $e');
      return [];
    }
  }

  // Get pending friend requests sent
  Future<List<FriendRequest>> getPendingSentRequests() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('friend_requests')
          .select('''
            *,
            receiver:user_profiles!friend_requests_receiver_id_fkey(username, display_name, avatar_url)
          ''')
          .eq('sender_id', user.id)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => FriendRequest.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting sent requests: $e');
      return [];
    }
  }

  // Get friends list
  Future<List<Friendship>> getFriends() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('friendships')
          .select('''
            *,
            friend:user_profiles!friendships_friend_id_fkey(username, display_name, avatar_url),
            friend_character:characters!friendships_friend_id_fkey(level, last_active)
          ''')
          .eq('user_id', user.id)
          .eq('status', 'accepted')
          .order('updated_at', ascending: false);

      return (response as List)
          .map((json) => Friendship.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting friends: $e');
      return [];
    }
  }

  // Remove friend
  Future<bool> removeFriend(String friendshipId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Get friendship to find the bidirectional pair
      final friendship = await _supabase
          .from('friendships')
          .select()
          .eq('id', friendshipId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (friendship == null) return false;

      final friendId = friendship['friend_id'];

      // Remove both directions of the friendship
      await _supabase
          .from('friendships')
          .delete()
          .or('and(user_id.eq.${user.id},friend_id.eq.$friendId),and(user_id.eq.$friendId,friend_id.eq.${user.id})');

      return true;
    } catch (e) {
      print('Error removing friend: $e');
      return false;
    }
  }

  // Send support message
  Future<SupportMessage?> sendSupportMessage({
    required String receiverId,
    required SupportType type,
    String? message,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final messageData = {
        'sender_id': user.id,
        'receiver_id': receiverId,
        'support_type': type.name,
        'message': message,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('support_messages')
          .insert(messageData)
          .select()
          .single();

      return SupportMessage.fromJson(response);
    } catch (e) {
      print('Error sending support message: $e');
      return null;
    }
  }

  // Get support messages received
  Future<List<SupportMessage>> getReceivedSupportMessages() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('support_messages')
          .select('''
            *,
            sender:user_profiles!support_messages_sender_id_fkey(username, display_name, avatar_url)
          ''')
          .eq('receiver_id', user.id)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => SupportMessage.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting support messages: $e');
      return [];
    }
  }

  // Mark support message as read
  Future<bool> markSupportMessageAsRead(String messageId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase
          .from('support_messages')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId)
          .eq('receiver_id', user.id);

      return true;
    } catch (e) {
      print('Error marking message as read: $e');
      return false;
    }
  }

  // Get user social stats
  Future<UserSocialStats?> getUserSocialStats() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      // Get friends count
      final friendsResponse = await _supabase
          .from('friendships')
          .select('id')
          .eq('user_id', user.id)
          .eq('status', 'accepted');

      final friendsCount = (friendsResponse as List).length;

      // Get support messages sent/received counts
      final sentMessagesResponse = await _supabase
          .from('support_messages')
          .select('id')
          .eq('sender_id', user.id);

      final receivedMessagesResponse = await _supabase
          .from('support_messages')
          .select('id')
          .eq('receiver_id', user.id);

      final sentMessagesCount = (sentMessagesResponse as List).length;
      final receivedMessagesCount = (receivedMessagesResponse as List).length;

      // For now, set other stats to 0 (can be implemented later)
      final stats = UserSocialStats(
        id: '${user.id}_social_stats',
        userId: user.id,
        friendsCount: friendsCount,
        supportMessagesSent: sentMessagesCount,
        supportMessagesReceived: receivedMessagesCount,
        mentorsCount: 0, // TODO: Implement mentor system
        menteesCount: 0, // TODO: Implement mentor system
        likesGiven: 0, // TODO: Implement like system
        likesReceived: 0, // TODO: Implement like system
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return stats;
    } catch (e) {
      print('Error getting user social stats: $e');
      return null;
    }
  }

  // Search users for friend requests
  Future<List<Map<String, dynamic>>> searchUsersForFriends(String query) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      if (query.trim().isEmpty) return [];

      // Get current friends to exclude
      final friends = await getFriends();
      final friendIds = friends.map((f) => f.friendId).toList();
      friendIds.add(user.id); // Exclude self

      var searchQuery = _supabase
          .from('user_profiles')
          .select('id, username, display_name, avatar_url')
          .or('username.ilike.%$query%,display_name.ilike.%$query%')
          .limit(20);

      if (friendIds.isNotEmpty) {
        searchQuery = searchQuery.not('id', 'in', friendIds);
      }

      final response = await searchQuery;

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error searching users for friends: $e');
      return [];
    }
  }

  // Get friendship status between users
  Future<FriendshipStatus?> getFriendshipStatus(String otherUserId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      // Check existing friendship
      final friendship = await _supabase
          .from('friendships')
          .select('status')
          .eq('user_id', user.id)
          .eq('friend_id', otherUserId)
          .maybeSingle();

      if (friendship != null) {
        return FriendshipStatus.values.firstWhere(
          (status) => status.name == friendship['status'],
          orElse: () => FriendshipStatus.pending,
        );
      }

      // Check pending requests
      final pendingRequest = await _supabase
          .from('friend_requests')
          .select('sender_id')
          .or('and(sender_id.eq.${user.id},receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.${user.id})')
          .eq('status', 'pending')
          .maybeSingle();

      if (pendingRequest != null) {
        return FriendshipStatus.pending;
      }

      return null; // No relationship
    } catch (e) {
      print('Error getting friendship status: $e');
      return null;
    }
  }

  // Get online friends
  Future<List<Friendship>> getOnlineFriends() async {
    try {
      final friends = await getFriends();
      
      // Filter friends who were active in the last 15 minutes
      final recentThreshold = DateTime.now().subtract(const Duration(minutes: 15));
      
      return friends.where((friend) {
        return friend.friendLastActive != null &&
               friend.friendLastActive!.isAfter(recentThreshold);
      }).toList();
    } catch (e) {
      print('Error getting online friends: $e');
      return [];
    }
  }

  // Send habit encouragement
  Future<SupportMessage?> sendHabitEncouragement(String friendId, String habitName) async {
    return sendSupportMessage(
      receiverId: friendId,
      type: SupportType.encouragement,
      message: '「$habitName」の習慣、頑張ってるね！応援してるよ！',
    );
  }

  // Send congratulations
  Future<SupportMessage?> sendCongratulations(String friendId, String achievement) async {
    return sendSupportMessage(
      receiverId: friendId,
      type: SupportType.congratulations,
      message: '$achievement 達成おめでとう！素晴らしいです！',
    );
  }

  // Send general motivation
  Future<SupportMessage?> sendMotivation(String friendId, {String? customMessage}) async {
    final message = customMessage ?? '今日も一日頑張りましょう！あなたなら絶対できます！';
    
    return sendSupportMessage(
      receiverId: friendId,
      type: SupportType.motivation,
      message: message,
    );
  }

  // Get unread support messages count
  Future<int> getUnreadSupportMessagesCount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 0;

      final response = await _supabase
          .from('support_messages')
          .select('id')
          .eq('receiver_id', user.id)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      print('Error getting unread messages count: $e');
      return 0;
    }
  }

  // Stream real-time friendship updates
  Stream<List<Friendship>> watchFriends() {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value([]);

    return _supabase
        .from('friendships')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .eq('status', 'accepted')
        .order('updated_at', ascending: false)
        .map((data) => data.map((json) => Friendship.fromJson(json)).toList());
  }

  // Stream real-time friend requests
  Stream<List<FriendRequest>> watchFriendRequests() {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value([]);

    return _supabase
        .from('friend_requests')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', user.id)
        .eq('status', 'pending')
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => FriendRequest.fromJson(json)).toList());
  }

  // Stream real-time support messages
  Stream<List<SupportMessage>> watchSupportMessages() {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value([]);

    return _supabase
        .from('support_messages')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', user.id)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => SupportMessage.fromJson(json)).toList());
  }
}
