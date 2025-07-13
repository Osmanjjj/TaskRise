import 'package:flutter/foundation.dart';
import '../models/character.dart';
import '../models/subscription.dart';
import '../models/mentor.dart' as mentor;
import '../services/services.dart';
import '../services/subscription_service.dart';
import '../services/mentor_service.dart';

class CharacterProvider extends ChangeNotifier {
  Character? _character;
  List<Subscription> _activeSubscriptions = [];
  SubscriptionBenefits? _subscriptionBenefits;
  List<mentor.MentorRelationship> _mentorships = [];
  mentor.MentorStats? _mentorStats;
  bool _isLoading = false;
  String? _error;

  // Services
  final SubscriptionService _subscriptionService = SubscriptionService();
  final MentorService _mentorService = MentorService();

  // Getters
  Character? get character => _character;
  List<Subscription> get activeSubscriptions => _activeSubscriptions;
  SubscriptionBenefits? get subscriptionBenefits => _subscriptionBenefits;
  List<mentor.MentorRelationship> get mentorships => _mentorships;
  mentor.MentorStats? get mentorStats => _mentorStats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Character status getters
  bool get hasCharacter => _character != null;
  bool get isPremiumUser => _subscriptionBenefits?.hasBasic ?? false;
  bool get hasGuildSubscription => _subscriptionBenefits?.hasGuild ?? false;
  bool get hasBattlePass => _subscriptionBenefits?.hasBattlePass ?? false;
  bool get hasEnterprise => _subscriptionBenefits?.hasEnterprise ?? false;
  bool get canCreateGuild => _subscriptionBenefits?.canCreateFixedGuild ?? false;
  bool get isMentor => (_mentorStats?.totalMentees ?? 0) > 0;
  bool get hasMentor => _character?.mentorId != null;

  // Experience and level info
  int get experienceForCurrentLevel => _character?.experienceForCurrentLevel ?? 0;
  int get experienceForNextLevel => _character?.experienceForNextLevel ?? 0;
  double get levelProgress => _character?.levelProgress ?? 0.0;
  
  // Resources
  int get battlePoints => _character?.battlePoints ?? 0;
  int get stamina => _character?.stamina ?? 0;
  int get maxStamina => _character?.maxStamina ?? 100;
  double get staminaPercentage => _character?.staminaPercentage ?? 0.0;
  String get rankDisplay => _character?.rank.displayName ?? 'Novice';

  /// Initialize character data
  Future<void> initializeCharacter(String characterId) async {
    _setLoading(true);
    _clearError();

    try {
      // Load character data, subscriptions, and mentorships in parallel
      await Future.wait([
        _loadCharacterData(characterId),
        _loadSubscriptions(characterId),
        _loadMentorships(characterId),
      ]);
    } catch (e) {
      _setError('Failed to initialize character: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load character basic data
  Future<void> _loadCharacterData(String characterId) async {
    // This would typically come from a character service
    // For now, we'll create a placeholder
    _character = Character(
      id: characterId,
      name: 'Player',
      level: 1,
      experience: 0,
      health: 100,
      attack: 10,
      defense: 5,
      battlePoints: 0,
      stamina: 100,
      maxStamina: 100,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lastActivityDate: DateTime.now(),
    );
    notifyListeners();
  }

  /// Load active subscriptions
  Future<void> _loadSubscriptions(String characterId) async {
    _activeSubscriptions = await _subscriptionService.getActiveSubscriptions(characterId);
    _subscriptionBenefits = await _subscriptionService.getSubscriptionBenefits(characterId);
    notifyListeners();
  }

  /// Load mentorship relationships
  Future<void> _loadMentorships(String characterId) async {
    _mentorships = await _mentorService.getCharacterMentorships(characterId);
    _mentorStats = await _mentorService.getMentorStats(characterId);
    notifyListeners();
  }

  /// Subscribe to a plan
  Future<bool> subscribe(SubscriptionType type, int durationMonths) async {
    if (_character == null) return false;

    _setLoading(true);
    try {
      final subscription = await _subscriptionService.createSubscription(
        characterId: _character!.id,
        type: type,
        durationMonths: durationMonths,
      );

      if (subscription != null) {
        await _loadSubscriptions(_character!.id);
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to subscribe: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Cancel subscription
  Future<bool> cancelSubscription(String subscriptionId) async {
    _setLoading(true);
    try {
      final success = await _subscriptionService.cancelSubscription(subscriptionId);
      if (success && _character != null) {
        await _loadSubscriptions(_character!.id);
      }
      return success;
    } catch (e) {
      _setError('Failed to cancel subscription: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Request mentorship
  Future<bool> requestMentorship(String mentorId) async {
    if (_character == null) return false;

    _setLoading(true);
    try {
      final relationship = await _mentorService.requestMentorship(_character!.id, mentorId);
      if (relationship != null) {
        await _loadMentorships(_character!.id);
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to request mentorship: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Accept mentorship request
  Future<bool> acceptMentorshipRequest(String relationshipId) async {
    _setLoading(true);
    try {
      final success = await _mentorService.acceptMentorship(relationshipId);
      if (success && _character != null) {
        await _loadMentorships(_character!.id);
      }
      return success;
    } catch (e) {
      _setError('Failed to accept mentorship: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Decline mentorship request
  Future<bool> declineMentorshipRequest(String relationshipId) async {
    _setLoading(true);
    try {
      final success = await _mentorService.declineMentorship(relationshipId);
      if (success && _character != null) {
        await _loadMentorships(_character!.id);
      }
      return success;
    } catch (e) {
      _setError('Failed to decline mentorship: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get premium features
  Future<PremiumFeatures?> getPremiumFeatures() async {
    if (_character == null) return null;

    try {
      return await _subscriptionService.getPremiumFeatures(_character!.id);
    } catch (e) {
      _setError('Failed to get premium features: $e');
      return null;
    }
  }

  /// Get expiring subscriptions
  Future<List<Subscription>> getExpiringSubscriptions() async {
    if (_character == null) return [];

    try {
      return await _subscriptionService.getExpiringSubscriptions(_character!.id);
    } catch (e) {
      _setError('Failed to get expiring subscriptions: $e');
      return [];
    }
  }

  /// Update character stats (called after habit completion, etc.)
  void updateCharacterStats({
    int? experienceGain,
    int? battlePointsGain,
    int? staminaGain,
  }) {
    if (_character == null) return;

    _character = _character!.copyWith(
      experience: experienceGain != null ? _character!.experience + experienceGain : null,
      battlePoints: battlePointsGain != null ? _character!.battlePoints + battlePointsGain : null,
      stamina: staminaGain != null 
          ? (_character!.stamina + staminaGain).clamp(0, _character!.maxStamina)
          : null,
      lastActivityDate: DateTime.now(),
    );
    notifyListeners();
  }

  /// Refresh all character data
  Future<void> refresh() async {
    if (_character == null) return;
    await initializeCharacter(_character!.id);
  }

  /// Get subscription display info
  String getSubscriptionDisplayText() {
    if (_activeSubscriptions.isEmpty) return 'フリープラン';
    
    final types = _activeSubscriptions.map((s) => s.type.displayName).toList();
    return types.join(' + ');
  }

  /// Get total monthly cost
  Future<int> getTotalMonthlyCost() async {
    if (_character == null) return 0;
    return await _subscriptionService.calculateTotalMonthlyCost(_character!.id);
  }

  /// Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  /// Load character data
  Future<void> loadCharacter() async {
    _setLoading(true);
    try {
      // Mock character loading - replace with actual implementation
      await Future.delayed(const Duration(milliseconds: 500));
      // Load character, subscriptions, mentorships, etc.
      // Mock loading subscriptions and mentorships
      await Future.delayed(const Duration(milliseconds: 300));
      // Replace with actual service calls when implemented
    } catch (e) {
      _setError('Failed to load character: $e');
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
