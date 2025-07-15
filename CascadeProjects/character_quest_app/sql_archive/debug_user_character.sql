-- 現在のユーザー情報を確認（ログインしているユーザー）
-- SupabaseのダッシュボードでAuthentication > Usersセクションから
-- 現在ログインしているユーザーのIDを確認してください

-- 1. 全てのキャラクターを確認
SELECT id, name, user_id, created_at FROM characters;

-- 2. 特定のユーザーIDでキャラクターを検索（YOUR_USER_IDを実際のIDに置き換えてください）
-- SELECT * FROM characters WHERE user_id = 'YOUR_USER_ID';

-- 3. tasksテーブルにcategoryカラムが存在するか確認
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'tasks' AND column_name = 'category';

-- 4. 既存のタスクを確認
SELECT id, title, character_id, category, created_at FROM tasks LIMIT 10;

-- 5. user_profilesテーブルの確認（もし存在する場合）
SELECT * FROM user_profiles LIMIT 5;