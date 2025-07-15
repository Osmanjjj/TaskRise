-- アプリに合わせてテーブル構造を修正

-- charactersテーブルに不足しているカラムを追加
ALTER TABLE characters 
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE characters 
ADD COLUMN IF NOT EXISTS total_crystals_earned INTEGER DEFAULT 0 CHECK (total_crystals_earned >= 0);

-- 既存のサンプルデータを更新（必要に応じて）
UPDATE characters 
SET total_crystals_earned = 0 
WHERE total_crystals_earned IS NULL;

-- 確認クエリ
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'characters' 
AND column_name IN ('user_id', 'total_crystals_earned')
ORDER BY column_name;
