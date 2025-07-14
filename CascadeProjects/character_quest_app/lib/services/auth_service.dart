import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // 現在のユーザー取得
  static User? get currentUser => _supabase.auth.currentUser;
  
  // 認証状態の監視
  static Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // サインアップ
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      print('Attempting signup for email: $email');
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'display_name': displayName,
        },
      );

      print('Signup response: ${response.user?.id}');
      
      // サインアップ成功時にユーザープロファイルを作成
      if (response.user != null) {
        print('Creating user profile...');
        await _createUserProfile(response.user!, displayName);
      }

      return response;
    } catch (e) {
      print('Signup error: $e');
      rethrow;
    }
  }

  // サインイン
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('Attempting signin for email: $email');
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      print('Signin response: ${response.user?.id}');
      return response;
    } catch (e) {
      print('Signin error: $e');
      rethrow;
    }
  }

  // Googleサインイン
  static Future<bool> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb 
            ? 'http://localhost:8080/#/auth-callback'
            : 'com.example.characterquestapp://login-callback',
      );
      return true;
    } catch (e) {
      print('Google signin error: $e');
      return false;
    }
  }

  // Appleサインイン
  static Future<bool> signInWithApple() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: kIsWeb 
            ? 'http://localhost:8080/#/auth-callback'
            : 'com.example.characterquestapp://login-callback',
      );
      return true;
    } catch (e) {
      print('Apple signin error: $e');
      return false;
    }
  }

  // パスワードリセット
  static Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  // サインアウト
  static Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // ユーザープロファイル作成
  static Future<void> _createUserProfile(User user, String displayName) async {
    try {
      // 既存のプロファイルをチェック
      final existing = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existing != null) {
        print('User profile already exists');
        return;
      }

      final userProfile = UserProfile(
        id: user.id,
        username: user.email ?? 'user_${user.id.substring(0, 8)}',
        displayName: displayName,
        avatarUrl: user.userMetadata?['avatar_url'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _supabase.from('user_profiles').insert(userProfile.toJson());
      print('User profile created successfully');
    } catch (e) {
      print('Error creating user profile: $e');
    }
  }

  // ユーザープロファイル取得
  static Future<UserProfile?> getUserProfile() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        // プロファイルが存在しない場合は作成
        print('User profile not found, creating...');
        await _createUserProfile(user, user.email ?? 'User');
        
        // 再度取得
        final newResponse = await _supabase
            .from('user_profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();
            
        if (newResponse != null) {
          return UserProfile.fromJson(newResponse);
        }
        return null;
      }

      return UserProfile.fromJson(response);
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // ユーザープロファイル更新
  static Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await _supabase
          .from('user_profiles')
          .update(profile.toJson())
          .eq('id', profile.id);
    } catch (e) {
      rethrow;
    }
  }

  // 認証状態チェック
  static bool get isAuthenticated => currentUser != null;

  // ユーザーID取得
  static String? get userId => currentUser?.id;

  // ユーザーメール取得
  static String? get userEmail => currentUser?.email;
}
