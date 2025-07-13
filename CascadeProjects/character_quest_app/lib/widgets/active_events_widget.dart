import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/character_provider.dart';
import '../models/event.dart';

class ActiveEventsWidget extends StatelessWidget {
  const ActiveEventsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final activeEvents = gameProvider.activeEvents;
        final upcomingEvents = gameProvider.upcomingEvents;
        final participations = gameProvider.eventParticipations;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'イベント',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showAllEventsDialog(context, gameProvider),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.event,
                              size: 16,
                              color: Colors.purple[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'すべて',
                              style: TextStyle(
                                color: Colors.purple[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (activeEvents.isEmpty && upcomingEvents.isEmpty)
                  _buildNoEventsMessage(context)
                else ...[
                  if (activeEvents.isNotEmpty) ...[
                    Text(
                      'アクティブイベント',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...activeEvents.take(2).map((event) => _buildEventCard(
                      context,
                      event,
                      participations.firstWhere(
                        (p) => p.eventId == event.id,
                        orElse: () => EventParticipation(
                          id: 'temp',
                          eventId: event.id,
                          characterId: '',
                          joinedAt: DateTime.now(),
                          score: 0,
                          completed: false,
                          rewardsReceived: {},
                        ),
                      ),
                      gameProvider,
                    )),
                    const SizedBox(height: 12),
                  ],

                  if (upcomingEvents.isNotEmpty) ...[
                    Text(
                      '開催予定',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...upcomingEvents.take(1).map((event) => _buildUpcomingEventCard(
                      context,
                      event,
                    )),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoEventsMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.event_busy,
              size: 40,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              '現在開催中のイベントはありません',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(
    BuildContext context,
    GameEvent event,
    EventParticipation participation,
    GameProvider gameProvider,
  ) {
    final isParticipating = participation.status != EventParticipationStatus.notJoined;
    final progress = isParticipating ? participation.progress : 0;
    final canClaimRewards = isParticipating && 
        progress >= 100 && 
        !participation.rewardsClaimed;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getEventTypeColor(event.type).withValues(alpha: 0.1),
            _getEventTypeColor(event.type).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getEventTypeColor(event.type).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getEventTypeIcon(event.type),
                color: _getEventTypeColor(event.type),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  event.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _getEventTypeColor(event.type),
                  ),
                ),
              ),
              if (canClaimRewards)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '報酬獲得可能',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.amber[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            event.description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 12,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                '${_formatDate(event.endDate)}まで',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              if (isParticipating) ...[
                Text(
                  '$progress%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _getEventTypeColor(event.type),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getEventTypeColor(event.type),
                    ),
                    minHeight: 4,
                  ),
                ),
              ] else
                GestureDetector(
                  onTap: () => _joinEvent(context, event.id, gameProvider),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getEventTypeColor(event.type),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '参加',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (canClaimRewards) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _claimRewards(context, participation.id, gameProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text(
                  '報酬を受け取る',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUpcomingEventCard(BuildContext context, GameEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            color: Colors.blue[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
                Text(
                  '${_formatDate(event.startDate)}開始予定',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAllEventsDialog(BuildContext context, GameProvider gameProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('すべてのイベント'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (gameProvider.activeEvents.isNotEmpty) ...[
                  Text(
                    'アクティブイベント',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...gameProvider.activeEvents.map((event) => _buildSimpleEventTile(
                    context,
                    event,
                    Colors.green,
                  )),
                  const SizedBox(height: 16),
                ],
                if (gameProvider.upcomingEvents.isNotEmpty) ...[
                  Text(
                    '開催予定',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...gameProvider.upcomingEvents.map((event) => _buildSimpleEventTile(
                    context,
                    event,
                    Colors.blue,
                  )),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleEventTile(BuildContext context, GameEvent event, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            _getEventTypeIcon(event.type),
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              event.title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _joinEvent(BuildContext context, String eventId, GameProvider gameProvider) async {
    // TODO: Get actual character ID
    const characterId = 'sample-character-id';
    
    final success = await gameProvider.joinEvent(characterId, eventId);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('イベントに参加しました！'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('イベント参加に失敗しました'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _claimRewards(BuildContext context, String participationId, GameProvider gameProvider) async {
    final characterProvider = Provider.of<CharacterProvider>(context, listen: false);
    final characterId = characterProvider.character?.id ?? '';
    final success = await gameProvider.claimEventRewards(participationId, characterId);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('報酬を受け取りました！'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('報酬の受け取りに失敗しました'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getEventTypeColor(EventType type) {
    switch (type) {
      case EventType.raid:
        return Color(type.color);
      case EventType.community:
        return Color(type.color);
      case EventType.challenge:
        return Color(type.color);
      case EventType.seasonal:
        return Color(type.color);
      case EventType.guild:
        return Color(type.color);
    }
  }

  IconData _getEventTypeIcon(EventType type) {
    switch (type) {
      case EventType.raid:
        return Icons.sports_kabaddi;
      case EventType.community:
        return Icons.people;
      case EventType.challenge:
        return Icons.flag;
      case EventType.seasonal:
        return Icons.calendar_today;
      case EventType.guild:
        return Icons.account_balance;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}
