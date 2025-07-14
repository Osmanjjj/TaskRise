# iOS認証表示問題の修正ガイド

## 問題の概要

Xcodeでアプリを開いた際に認証画面が表示されない問題について。

## 原因と解決方法

### 1. user_profilesテーブルのカラム名の不一致

**問題**: データベースのカラム名がsnake_case（avatar_url）だが、DartモデルがcamelCase（avatarUrl）を使用していた。

**解決方法**: 
```dart
@JsonSerializable(fieldRename: FieldRename.snake)
class UserProfile {
  // ...
}
```

### 2. iOS用のURL Scheme設定

**問題**: iOSアプリでOAuth認証のリダイレクトが正しく設定されていない。

**解決方法**:
1. Info.plistにURL Schemeを追加
2. プラットフォーム別のリダイレクトURL設定

### 3. 初期化タイミングの問題

**問題**: 認証状態の初期化が完了する前に画面が表示される。

**解決方法**: AuthGuardにローディング状態を追加

## 実装した修正

### 1. UserProfileモデルの修正
```dart
// lib/models/user_profile.dart
@JsonSerializable(fieldRename: FieldRename.snake)  // snake_case変換を自動化
class UserProfile {
  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;  // avatar_url として送信される
  // ...
}
```

### 2. プラットフォーム別リダイレクト
```dart
// lib/services/auth_service.dart
redirectTo: kIsWeb 
    ? 'http://localhost:8080/#/auth-callback'
    : 'com.example.characterquestapp://login-callback',
```

### 3. AuthGuardの改善
```dart
// lib/widgets/auth_guard.dart
if (authProvider.isLoading && authProvider.user == null) {
  return const Scaffold(
    body: Center(
      child: CircularProgressIndicator(),
    ),
  );
}
```

### 4. エラーハンドリングの改善
- 既存プロファイルのチェック追加
- プロファイルが存在しない場合の自動作成
- 詳細なエラーログ出力

## テスト手順

### iOSシミュレータでのテスト

1. クリーンビルド
```bash
flutter clean
cd ios
pod install
cd ..
```

2. シミュレータで実行
```bash
flutter run -d "iPhone 16"
```

3. 確認項目
- [ ] 認証画面が表示される
- [ ] 新規登録が可能
- [ ] ログインが可能
- [ ] ログイン後ダッシュボードに遷移

### デバッグ方法

1. **Xcodeコンソール**
   - エラーメッセージを確認
   - print文の出力を確認

2. **Flutter Inspector**
   ```bash
   flutter inspector
   ```

3. **ネットワークログ**
   - Supabase APIへのリクエストを確認

## よくある問題と対処法

### 「認証画面が表示されない」
- Supabase初期化が完了しているか確認
- AuthProviderが正しく初期化されているか確認

### 「ログイン後に画面が切り替わらない」
- AuthGuardが認証状態を監視しているか確認
- ナビゲーションルートが正しく設定されているか確認

### 「プロファイル作成エラー」
- データベーススキーマが最新か確認
- RLSポリシーが正しく設定されているか確認

## 推奨事項

1. **開発時の設定**
   - メール確認を無効化
   - デバッグログを有効化

2. **本番環境への準備**
   - 適切なBundle Identifierを設定
   - セキュアなリダイレクトURLを設定
   - エラーログを適切に処理