# Character Quest App 🎮

タスク完遂でキャラクター育成！シンプルなゲーミフィケーション・タスク管理アプリです。

## 特徴 ✨

- **キャラクター育成**: タスクを完了して経験値を獲得
- **レベルアップシステム**: 経験値に応じてキャラクターがレベルアップ
- **難易度別タスク**: Easy/Normal/Hardの3段階で経験値が変動
- **美しいUI**: Material Design 3とGoogle Fontsを使用
- **リアルタイムデータ**: Supabaseによるクラウド同期

## 技術スタック 🛠️

- **Frontend**: Flutter (Dart)
- **Backend**: Supabase (PostgreSQL)
- **状態管理**: Provider
- **UI**: Material Design 3 + Google Fonts
- **アニメーション**: Flutter Animate

## セットアップ 🚀

### 1. 依存関係のインストール
```bash
flutter pub get
```

### 2. Supabaseテーブルのセットアップ
1. Supabaseプロジェクトのダッシュボードを開く
2. "SQL Editor"に移動
3. `supabase_tables.sql`の内容をコピー＆実行

### 3. アプリの実行
```bash
flutter run
```

## 機能 📱

### キャラクター管理
- キャラクター作成（名前設定）
- ステータス表示（Level, HP, ATK, DEF）
- 経験値バーによる進捗可視化

### タスク管理
- タスク作成（タイトル、説明、難易度、期限）
- タスク完了（経験値獲得）
- タスク削除
- Pending/Completedタブでの整理

### ゲーミフィケーション
- 難易度別経験値システム:
  - Easy: +10 XP
  - Normal: +25 XP
  - Hard: +50 XP
- レベルアップ（100 XPごと）
- 視覚的な進捗表示

## データベース設計 📊

### Characters Table
- `id`: UUID (Primary Key)
- `name`: VARCHAR(100)
- `level`: INTEGER
- `experience`: INTEGER
- `health`: INTEGER
- `attack`: INTEGER
- `defense`: INTEGER
- `avatar_url`: TEXT
- `created_at`: TIMESTAMP
- `updated_at`: TIMESTAMP

### Tasks Table
- `id`: UUID (Primary Key)
- `title`: VARCHAR(200)
- `description`: TEXT
- `difficulty`: ENUM('easy', 'normal', 'hard')
- `status`: ENUM('pending', 'completed', 'failed')
- `experience_reward`: INTEGER
- `due_date`: TIMESTAMP
- `character_id`: UUID (Foreign Key)
- `created_at`: TIMESTAMP
- `updated_at`: TIMESTAMP

## 今後の拡張予定 🔮

- [ ] オンライン対戦システム
- [ ] フレンド機能
- [ ] ギルドシステム
- [ ] アチーブメント
- [ ] アイテム・装備システム
- [ ] キャラクターアバターカスタマイズ
- [ ] 通知機能
- [ ] ダークモード

## 開発者向け 🔧

### プロジェクト構成
```
lib/
├── config/          # 設定ファイル
├── models/          # データモデル
├── providers/       # 状態管理
├── screens/         # 画面
├── services/        # Supabase連携
└── widgets/         # UIコンポーネント
```

### 主要パッケージ
- `supabase_flutter`: バックエンド連携
- `provider`: 状態管理
- `google_fonts`: フォント
- `flutter_animate`: アニメーション

## ライセンス 📄

MIT License
