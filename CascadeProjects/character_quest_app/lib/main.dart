import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/auth_provider.dart';
import 'providers/character_provider.dart';
import 'providers/game_provider.dart';
import 'screens/dashboard_screen.dart';
import 'widgets/auth_guard.dart';
import 'services/supabase_service.dart';
import 'navigation/app_router.dart';

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
        ChangeNotifierProxyProvider<CharacterProvider, GameProvider>(
          create: (context) => GameProvider(characterProvider: Provider.of<CharacterProvider>(context, listen: false)),
          update: (context, characterProvider, gameProvider) => gameProvider ?? GameProvider(characterProvider: characterProvider),
        ),
      ],
      child: MaterialApp(
        title: 'Character Quest',
        home: const AuthGuard(child: DashboardScreen()),
        onGenerateRoute: AppRouter.generateRoute,
        navigatorKey: AppNavigator.navigatorKey,
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


