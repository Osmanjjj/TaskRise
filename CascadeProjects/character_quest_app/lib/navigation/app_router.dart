import 'package:flutter/material.dart';
import '../screens/screens.dart';

class AppRouter {
  static const String dashboard = '/';
  static const String habits = '/habits';
  static const String events = '/events';
  static const String guilds = '/guilds';
  static const String gacha = '/gacha';
  static const String mentor = '/mentor';
  static const String profile = '/profile';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case habits:
        return MaterialPageRoute(builder: (_) => const HabitsScreen());
      case events:
        return MaterialPageRoute(builder: (_) => const EventsScreen());
      case guilds:
        return MaterialPageRoute(builder: (_) => const GuildsScreen());
      case gacha:
        return MaterialPageRoute(builder: (_) => const GachaScreen());
      case mentor:
        return MaterialPageRoute(builder: (_) => const MentorScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('エラー')),
            body: const Center(
              child: Text('ページが見つかりません'),
            ),
          ),
        );
    }
  }
}

class AppNavigator {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static BuildContext? get context => navigatorKey.currentContext;

  static void push(String routeName, {Object? arguments}) {
    navigatorKey.currentState?.pushNamed(routeName, arguments: arguments);
  }

  static void pushReplacement(String routeName, {Object? arguments}) {
    navigatorKey.currentState?.pushReplacementNamed(routeName, arguments: arguments);
  }

  static void pop() {
    navigatorKey.currentState?.pop();
  }

  static void popUntil(String routeName) {
    navigatorKey.currentState?.popUntil(ModalRoute.withName(routeName));
  }

  static void pushAndClearStack(String routeName, {Object? arguments}) {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }
}
