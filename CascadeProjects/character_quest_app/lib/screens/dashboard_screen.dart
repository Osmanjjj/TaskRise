import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../widgets/widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer2<CharacterProvider, GameProvider>(
      builder: (context, characterProvider, gameProvider, child) {
        final character = characterProvider.character;
        
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const Icon(Icons.castle_outlined, size: 24),
                const SizedBox(width: 8),
                const Text('キャラクタークエスト'),
                const Spacer(),
                if (character != null) ...[
                  Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                  Text('Lv.${character.level}', style: const TextStyle(fontSize: 14)),
                ],
              ],
            ),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await characterProvider.loadCharacter();
              await gameProvider.loadData();
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Character Stats Card
                        CharacterStatsCard(),
                        const SizedBox(height: 16),
                        
                        // Crystal Inventory
                        CrystalInventoryWidget(),
                        const SizedBox(height: 16),
                        
                        // Active Events
                        ActiveEventsWidget(),
                        const SizedBox(height: 16),
                        
                        // Raid Boss Widget
                        RaidBossWidget(),
                        const SizedBox(height: 16),
                        
                        // Habit/Task Progress
                        HabitListWidget(),
                        const SizedBox(height: 16),
                        
                        // Mentor Status
                        MentorStatusWidget(),
                        const SizedBox(height: 16),
                        
                        // Subscription Status
                        SubscriptionStatusWidget(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
