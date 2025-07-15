-- EXPが追加されない問題を修正するSQL

-- 1. charactersテーブルに不足しているカラムを追加
ALTER TABLE characters 
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE characters 
ADD COLUMN IF NOT EXISTS total_crystals_earned INTEGER DEFAULT 0 CHECK (total_crystals_earned >= 0);

-- 2. 既存のキャラクターとユーザーを関連付ける
-- 注意: 既存のキャラクターがある場合は、適切なuser_idを設定する必要があります
-- 例: UPDATE characters SET user_id = 'your-user-uuid' WHERE id = 'character-id';

-- 3. user_idにインデックスを追加してパフォーマンスを向上
CREATE INDEX IF NOT EXISTS idx_characters_user_id ON characters(user_id);

-- 4. 確認クエリ - テーブル構造を確認
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'characters' 
ORDER BY ordinal_position;

-- 5. 確認クエリ - ユーザーとキャラクターの関連を確認
SELECT 
    c.id as character_id,
    c.name as character_name,
    c.level,
    c.experience,
    c.user_id,
    u.email as user_email
FROM characters c
LEFT JOIN auth.users u ON c.user_id = u.id;

-- 6. タスク完了時のEXP更新をテストするクエリ
-- 特定のキャラクターのEXPを手動で更新してテスト
-- UPDATE characters 
-- SET experience = experience + 25,
--     updated_at = NOW()
-- WHERE user_id = 'your-user-uuid';