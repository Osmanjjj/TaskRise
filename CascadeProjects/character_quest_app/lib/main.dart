import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/auth_provider.dart';
import 'providers/character_provider.dart';
import 'providers/game_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/habits_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/auth_guard.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const CharacterQuestApp());
}

class CharacterQuestApp extends StatelessWidget {
  const CharacterQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CharacterProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
      ],
      child: MaterialApp(
        title: 'Character Quest',
        home: const AuthGuard(child: DashboardScreen()),
        routes: {
          '/auth': (context) => const AuthScreen(),
          '/dashboard': (context) => const AuthGuard(child: DashboardScreen()),
          '/profile': (context) => const AuthGuard(child: ProfileScreen()),
          '/habits': (context) => const AuthGuard(child: HabitsScreen()),
          '/settings': (context) => const AuthGuard(child: SettingsScreen()),
        },
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF667eea),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.notoSansJpTextTheme(),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF667eea),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.notoSansJpTextTheme(ThemeData.dark().textTheme),
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}


