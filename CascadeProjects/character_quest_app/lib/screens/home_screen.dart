import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/character_card.dart';
import '../widgets/task_list.dart';
import '../widgets/create_character_dialog.dart';
import '../widgets/create_task_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      provider.loadCharacters().then((_) {
        if (provider.selectedCharacter != null) {
          provider.loadTasks();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Character Quest',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            elevation: 0,
            actions: [
              if (_currentIndex == 0)
                IconButton(
                  onPressed: () => _showCreateCharacterDialog(context),
                  icon: const Icon(Icons.add),
                  tooltip: 'Create Character',
                ),
              if (_currentIndex == 1)
                IconButton(
                  onPressed: provider.selectedCharacter != null
                      ? () => _showCreateTaskDialog(context)
                      : null,
                  icon: const Icon(Icons.add_task),
                  tooltip: 'Create Task',
                ),
            ],
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : IndexedStack(
                  index: _currentIndex,
                  children: [
                    _buildCharacterTab(provider),
                    _buildTaskTab(provider),
                  ],
                ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.person),
                label: 'Character',
              ),
              NavigationDestination(
                icon: Icon(Icons.task_alt),
                label: 'Tasks',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCharacterTab(AppProvider provider) {
    if (provider.characters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No characters yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first character to start your quest!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showCreateCharacterDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Character'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Characters',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: provider.characters.length,
              itemBuilder: (context, index) {
                final character = provider.characters[index];
                return CharacterCard(
                  character: character,
                  isSelected: provider.selectedCharacter?.id == character.id,
                  onTap: () => provider.selectCharacter(character),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTab(AppProvider provider) {
    if (provider.selectedCharacter == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No character selected',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Select a character from the Character tab to manage tasks',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${provider.selectedCharacter!.name}\'s Tasks',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TaskList(tasks: provider.tasks),
          ),
        ],
      ),
    );
  }

  void _showCreateCharacterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateCharacterDialog(),
    );
  }

  void _showCreateTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateTaskDialog(),
    );
  }
}
