import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initializeAuth();
  }

  // 認証状態の初期化
  void _initializeAuth() {
    _user = AuthService.currentUser;
    if (_user != null) {
      _loadUserProfile();
    }

    // 認証状態の変更を監視
    AuthService.authStateChanges.listen((AuthState data) {
      _user = data.session?.user;
      if (_user != null) {
        _loadUserProfile();
      } else {
        _userProfile = null;
      }
      notifyListeners();
    });
  }

  // ユーザープロファイル読み込み
  Future<void> _loadUserProfile() async {
    try {
      _userProfile = await AuthService.getUserProfile();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'プロファイルの読み込みに失敗しました: $e';
      notifyListeners();
    }
  }

  // サインアップ
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await AuthService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );

      if (response.user != null) {
        _user = response.user;
        await _loadUserProfile();
        _setLoading(false);
        return true;
      } else {
        _setError('サインアップに失敗しました');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      print('AuthProvider signup error: $e');
      if (e.toString().contains('email_not_confirmed')) {
        _setError('メールアドレスの確認が必要です。メールを確認してください。');
      } else {
        _setError('サインアップエラー: $e');
      }
      _setLoading(false);
      return false;
    }
  }

  // サインイン
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await AuthService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _user = response.user;
        await _loadUserProfile();
        _setLoading(false);
        return true;
      } else {
        _setError('サインインに失敗しました');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      print('AuthProvider signin error: $e');
      if (e.toString().contains('Invalid login credentials')) {
        _setError('メールアドレスまたはパスワードが間違っています');
      } else if (e.toString().contains('Email not confirmed')) {
        _setError('メールアドレスの確認が必要です');
      } else {
        _setError('サインインエラー: $e');
      }
      _setLoading(false);
      return false;
    }
  }

  // Googleサインイン
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final success = await AuthService.signInWithGoogle();
      if (success) {
        // 認証状態の変更は自動的に監視される
        _setLoading(false);
        return true;
      } else {
        _setError('Googleサインインに失敗しました');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Googleサインインエラー: $e');
      _setLoading(false);
      return false;
    }
  }

  // Appleサインイン
  Future<bool> signInWithApple() async {
    _setLoading(true);
    _clearError();

    try {
      final success = await AuthService.signInWithApple();
      if (success) {
        _setLoading(false);
        return true;
      } else {
        _setError('Appleサインインに失敗しました');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Appleサインインエラー: $e');
      _setLoading(false);
      return false;
    }
  }

  // パスワードリセット
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await AuthService.resetPassword(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('パスワードリセットエラー: $e');
      _setLoading(false);
      return false;
    }
  }

  // サインアウト
  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      await AuthService.signOut();
      _user = null;
      _userProfile = null;
      _setLoading(false);
    } catch (e) {
      _setError('サインアウトエラー: $e');
      _setLoading(false);
    }
  }

  // プロファイル更新
  Future<bool> updateProfile(UserProfile profile) async {
    _setLoading(true);
    _clearError();

    try {
      await AuthService.updateUserProfile(profile);
      _userProfile = profile;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('プロファイル更新エラー: $e');
      _setLoading(false);
      return false;
    }
  }

  // ヘルパーメソッド
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // エラーメッセージをクリア
  void clearError() {
    _clearError();
  }
}
