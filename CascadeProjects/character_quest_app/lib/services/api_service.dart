import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'character_service.dart';
import 'habit_service.dart';
import 'guild_service.dart';
import 'raid_service.dart';
import 'gacha_service.dart';
import 'social_service.dart';
import 'subscription_service.dart';
import 'user_profile_service.dart';

/// Central API service that coordinates all other services
class ApiService extends ChangeNotifier {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Service instances
  late final CharacterService _characterService;
  late final HabitService _habitService;
  late final GuildService _guildService;
  late final RaidService _raidService;
  late final GachaService _gachaService;
  late final SocialService _socialService;
  late final SubscriptionService _subscriptionService;
  late final UserProfileService _userProfileService;

  // Getters for services
  CharacterService get character => _characterService;
  HabitService get habit => _habitService;
  GuildService get guild => _guildService;
  RaidService get raid => _raidService;
  GachaService get gacha => _gachaService;
  SocialService get social => _socialService;
  SubscriptionService get subscription => _subscriptionService;
  UserProfileService get userProfile => _userProfileService;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize all services
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _characterService = CharacterService();
      _habitService = HabitService();
      _guildService = GuildService();
      _raidService = RaidService();
      _gachaService = GachaService();
      _socialService = SocialService();
      _subscriptionService = SubscriptionService();
      _userProfileService = UserProfileService();

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error initializing API services: $e');
      rethrow;
    }
  }

  /// Current authenticated user
  User? get currentUser => _supabase.auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Sign out and clear all cached data
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      notifyListeners();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  /// Get comprehensive user dashboard data
  Future<UserDashboardData?> getUserDashboardData() async {
    if (!isAuthenticated) return null;

    try {
      final userId = currentUser!.id;

      // Fetch data from multiple services concurrently
      final results = await Future.wait([
        _userProfileService.getUserProfile(),
        _characterService.getUserCharacter(),
        _habitService.getUserHabits(),
        _habitService.getHabitsStats(),
        _guildService.getUserGuild(),
        _socialService.getFriends(),
        _socialService.getUnreadSupportMessagesCount(),
        _subscriptionService.getActiveSubscriptions(userId),
        _gachaService.getUserGachaHistory(),
      ]);

      final userProfile = results[0];
      final character = results[1];
      final habits = results[2] as List;
      final habitStats = results[3];
      final guild = results[4];
      final friends = results[5] as List;
      final unreadMessages = results[6] as int;
      final subscriptions = results[7] as List;
      final gachaHistory = results[8];

      return UserDashboardData(
        userProfile: userProfile,
        character: character,
        habitsCount: habits.length,
        habitStats: habitStats,
        guild: guild,
        friendsCount: friends.length,
        unreadMessagesCount: unreadMessages,
        activeSubscriptions: subscriptions,
        gachaHistory: gachaHistory,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      print('Error getting dashboard data: $e');
      return null;
    }
  }

  /// Get user activity summary for today
  Future<UserActivitySummary?> getTodayActivitySummary() async {
    if (!isAuthenticated) return null;

    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final results = await Future.wait([
        _habitService.getHabitsDueToday(),
        _characterService.getTodayExperienceGain(),
        _socialService.getReceivedSupportMessages(),
        _guildService.getTodayGuildActivity(),
      ]);

      final habitsDue = results[0] as List;
      final expGain = results[1] as int? ?? 0;
      final supportMessages = results[2] as List;
      final guildActivity = results[3];

      final completedHabits = habitsDue.where((h) => h.isCompletedToday).length;
      final todaySupportMessages = supportMessages
          .where((m) => m.createdAt.isAfter(startOfDay) && m.createdAt.isBefore(endOfDay))
          .length;

      return UserActivitySummary(
        date: today,
        habitsCompleted: completedHabits,
        totalHabits: habitsDue.length,
        experienceGained: expGain,
        supportMessagesReceived: todaySupportMessages,
        guildActivityScore: guildActivity?.activityScore ?? 0,
      );
    } catch (e) {
      print('Error getting today activity summary: $e');
      return null;
    }
  }

  /// Check and return pending notifications
  Future<List<AppNotification>> getPendingNotifications() async {
    if (!isAuthenticated) return [];

    try {
      final notifications = <AppNotification>[];

      // Check for pending friend requests
      final friendRequests = await _socialService.getPendingReceivedRequests();
      for (final request in friendRequests) {
        notifications.add(AppNotification(
          id: 'friend_request_${request.id}',
          type: NotificationType.friendRequest,
          title: 'フレンド申請',
          message: '${request.senderDisplayName}さんからフレンド申請が届いています',
          data: {'request_id': request.id},
          createdAt: request.createdAt,
        ));
      }

      // Check for unread support messages
      final unreadCount = await _socialService.getUnreadSupportMessagesCount();
      if (unreadCount > 0) {
        notifications.add(AppNotification(
          id: 'support_messages',
          type: NotificationType.supportMessage,
          title: '応援メッセージ',
          message: '${unreadCount}件の新しい応援メッセージがあります',
          data: {'count': unreadCount},
          createdAt: DateTime.now(),
        ));
      }

      // Check for expiring subscriptions
      if (isAuthenticated) {
        final expiring = await _subscriptionService.getExpiringSubscriptions(currentUser!.id);
        for (final sub in expiring) {
          notifications.add(AppNotification(
            id: 'subscription_expiring_${sub.id}',
            type: NotificationType.subscriptionExpiring,
            title: 'サブスクリプション期限',
            message: '${sub.type.displayName}が${sub.daysUntilExpiry}日後に期限切れになります',
            data: {'subscription_id': sub.id},
            createdAt: DateTime.now(),
          ));
        }
      }

      // Check for guild invitations
      final guildInvites = await _guildService.getGuildInvitations();
      for (final invite in guildInvites) {
        notifications.add(AppNotification(
          id: 'guild_invite_${invite.id}',
          type: NotificationType.guildInvite,
          title: 'ギルド招待',
          message: '${invite.guildName}からの招待が届いています',
          data: {'invite_id': invite.id},
          createdAt: invite.createdAt,
        ));
      }

      // Sort by creation date (newest first)
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return notifications;
    } catch (e) {
      print('Error getting pending notifications: $e');
      return [];
    }
  }

  /// Dispose and clean up resources
  @override
  void dispose() {
    super.dispose();
  }
}

/// Dashboard data aggregator
class UserDashboardData {
  final dynamic userProfile;
  final dynamic character;
  final int habitsCount;
  final dynamic habitStats;
  final dynamic guild;
  final int friendsCount;
  final int unreadMessagesCount;
  final List activeSubscriptions;
  final dynamic gachaHistory;
  final DateTime lastUpdated;

  UserDashboardData({
    required this.userProfile,
    required this.character,
    required this.habitsCount,
    required this.habitStats,
    required this.guild,
    required this.friendsCount,
    required this.unreadMessagesCount,
    required this.activeSubscriptions,
    required this.gachaHistory,
    required this.lastUpdated,
  });

  bool get hasActiveSubscription => activeSubscriptions.isNotEmpty;
  bool get isInGuild => guild != null;
  bool get hasUnreadMessages => unreadMessagesCount > 0;
}

/// Activity summary for a specific day
class UserActivitySummary {
  final DateTime date;
  final int habitsCompleted;
  final int totalHabits;
  final int experienceGained;
  final int supportMessagesReceived;
  final int guildActivityScore;

  UserActivitySummary({
    required this.date,
    required this.habitsCompleted,
    required this.totalHabits,
    required this.experienceGained,
    required this.supportMessagesReceived,
    required this.guildActivityScore,
  });

  double get habitCompletionRate => 
      totalHabits > 0 ? habitsCompleted / totalHabits : 0.0;

  String get habitCompletionRateDisplay => 
      '${(habitCompletionRate * 100).toStringAsFixed(1)}%';

  bool get isActiveDay => 
      habitsCompleted > 0 || 
      experienceGained > 0 || 
      supportMessagesReceived > 0 || 
      guildActivityScore > 0;
}

/// App notification data
class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.data,
    required this.createdAt,
  });
}

/// Types of notifications
enum NotificationType {
  friendRequest,
  supportMessage,
  subscriptionExpiring,
  guildInvite,
  habitReminder,
  raidBattle,
  gachaUpdate,
}

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.friendRequest:
        return 'フレンド申請';
      case NotificationType.supportMessage:
        return '応援メッセージ';
      case NotificationType.subscriptionExpiring:
        return 'サブスク期限';
      case NotificationType.guildInvite:
        return 'ギルド招待';
      case NotificationType.habitReminder:
        return '習慣リマインダー';
      case NotificationType.raidBattle:
        return 'レイドバトル';
      case NotificationType.gachaUpdate:
        return 'ガチャ更新';
    }
  }
}
