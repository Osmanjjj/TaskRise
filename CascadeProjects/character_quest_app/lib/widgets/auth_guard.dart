import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth_screen.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // ローディング中はスプラッシュ画面を表示
        if (authProvider.isLoading && authProvider.user == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // 認証状態をチェック
        if (authProvider.isAuthenticated) {
          return child;
        } else {
          return const AuthScreen();
        }
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final Widget authenticatedChild;
  final Widget? unauthenticatedChild;

  const AuthWrapper({
    super.key,
    required this.authenticatedChild,
    this.unauthenticatedChild,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isAuthenticated) {
          return authenticatedChild;
        } else {
          return unauthenticatedChild ?? const AuthScreen();
        }
      },
    );
  }
}
