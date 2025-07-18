import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../widgets/widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize character when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final characterProvider = Provider.of<CharacterProvider>(context, listen: false);
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      await characterProvider.initializeCharacterByUserId(authProvider.user!.id);
      await gameProvider.loadData();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Consumer2<CharacterProvider, GameProvider>(
      builder: (context, characterProvider, gameProvider, child) {
        final character = characterProvider.character;
        
        return Scaffold(
          drawer: _buildDrawer(context),
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
                        if (characterProvider.character != null)
                          CrystalInventoryWidget(characterId: characterProvider.character!.id),
                        if (characterProvider.character != null)
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

  Widget _buildDrawer(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final characterProvider = Provider.of<CharacterProvider>(context);
    final character = characterProvider.character;
    
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    character?.name.substring(0, 1).toUpperCase() ?? 'P',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  character?.name ?? 'プレイヤー',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  authProvider.user?.email ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('ダッシュボード'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('プロフィール'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text('習慣'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/habits');
            },
          ),
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text('イベント'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/events');
            },
          ),
          ListTile(
            leading: const Icon(Icons.casino),
            title: const Text('ガチャ'),
            onTap: () {
              print('Gacha button tapped');
              Navigator.pop(context);
              print('Drawer closed, navigating to /gacha');
              Navigator.pushNamed(context, '/gacha').then((value) {
                print('Navigation completed');
              }).catchError((error) {
                print('Navigation error: $error');
              });
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('設定'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
