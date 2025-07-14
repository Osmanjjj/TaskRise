# Supabase Database Setup Guide

このガイドでは、Character Quest AppのSupabaseデータベースをセットアップする手順を説明します。

## 前提条件

- Supabaseアカウントを作成済み
- Supabaseプロジェクトを作成済み（URL: https://eumoeaflrukwfpiskbdd.supabase.co）

## セットアップ手順

### 1. Supabaseダッシュボードにログイン

1. [Supabase Dashboard](https://app.supabase.com)にアクセス
2. プロジェクトを選択

### 2. SQLエディタでスキーマを実行

1. 左側のメニューから「SQL Editor」を選択
2. 「New query」ボタンをクリック
3. `supabase_complete_schema.sql`の内容をコピーして貼り付け
4. 「Run」ボタンをクリックして実行

**警告**: このSQLは既存のテーブルをすべて削除します。本番環境で実行する場合は注意してください。

### 3. 認証設定の確認

1. 「Authentication」→「Providers」に移動
2. 以下のプロバイダーを有効化:
   - Email/Password
   - Google（オプション）
   - Apple（オプション）

### 4. Row Level Security (RLS)の確認

スキーマには既にRLSポリシーが含まれています。以下のテーブルでRLSが有効になっていることを確認：

- user_profiles
- characters
- tasks
- daily_stats
- subscriptions

### 5. 環境変数の設定

Flutter側で以下の環境変数が正しく設定されていることを確認：

```dart
// lib/config/supabase_config.dart
class SupabaseConfig {
  static const String url = 'YOUR_SUPABASE_URL';
  static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

## テーブル構造

### user_profiles
- ユーザーの基本プロファイル情報
- auth.usersテーブルと連携

### characters
- ゲーム内キャラクター情報
- レベル、経験値、ステータスなど

### tasks
- 習慣タスクの管理
- 難易度、報酬、期限など

### daily_stats
- 日次の統計情報
- 完了したタスク数、獲得ポイントなど

### game_events
- ゲーム内イベント
- レイド、チャレンジ、シーズナルイベントなど

### subscriptions
- サブスクリプション管理
- プレミアム、ギルド、バトルパスなど

## トリガーとファンクション

### handle_new_user()
新規ユーザー登録時に自動的に：
- user_profilesレコードを作成
- デフォルトのcharacterを作成

### update_updated_at_column()
各テーブルのupdated_atを自動更新

### get_mentor_stats()
メンター機能用のプレースホルダー関数

## トラブルシューティング

### エラー: "relation "auth.users" does not exist"
→ Supabaseの認証機能が有効になっていることを確認

### エラー: "permission denied for schema public"
→ データベースの権限設定を確認

### RLSポリシーが機能しない
→ 各テーブルでRLSが有効になっていることを確認

## 次のステップ

1. Flutterアプリを起動して認証フローをテスト
2. 新規ユーザー登録を行い、自動的にプロファイルとキャラクターが作成されることを確認
3. タスクの作成・完了機能をテスト