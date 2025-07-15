# EXP追加問題の修正手順

## 問題の原因
`characters`テーブルに`user_id`カラムが存在しないため、キャラクターの検索・更新ができず、タスク完了時にEXPが追加されていませんでした。

## 修正手順

### 1. データベーススキーマの修正（完了済み）
`fix_exp_issue.sql`を実行して、以下の変更を適用しました：
- `user_id`カラムの追加
- `total_crystals_earned`カラムの追加
- インデックスの作成

### 2. 既存のキャラクターとユーザーの関連付け
Supabaseのダッシュボードで`link_existing_characters.sql`を実行して：

1. 現在の状態を確認
2. user_idがNULLのキャラクターを特定
3. 適切なユーザーIDを設定

**開発環境で1人のユーザーしかいない場合：**
```sql
UPDATE characters 
SET user_id = (SELECT id FROM auth.users LIMIT 1)
WHERE user_id IS NULL;
```

### 3. 動作確認
1. アプリにログイン
2. 新しいタスクを作成
3. タスクを完了
4. EXPが正しく追加されることを確認
5. レベルアップ時にダイアログが表示されることを確認

## トラブルシューティング

### EXPがまだ追加されない場合
1. ブラウザの開発者ツールでコンソールエラーを確認
2. Supabaseのダッシュボードで以下を確認：
   - charactersテーブルのuser_idが正しく設定されているか
   - tasksテーブルのcharacter_idが正しいか

### 確認用SQLクエリ
```sql
-- ユーザーとキャラクターの関連を確認
SELECT 
    c.id as character_id,
    c.name,
    c.level,
    c.experience,
    c.user_id,
    u.email
FROM characters c
JOIN auth.users u ON c.user_id = u.id;

-- 最近のタスクとEXP報酬を確認
SELECT 
    t.title,
    t.experience_reward,
    t.status,
    t.completed_at,
    c.name as character_name
FROM tasks t
JOIN characters c ON t.character_id = c.id
ORDER BY t.created_at DESC
LIMIT 10;
```