-- charactersテーブルに不足しているカラムを追加
-- エラー: Could not find the 'total_crystals_earned' column

-- 1. まず現在のcharactersテーブルの構造を確認
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'characters'
ORDER BY ordinal_position;

-- 2. 不足しているカラムを追加
ALTER TABLE characters 
ADD COLUMN IF NOT EXISTS total_crystals_earned INTEGER DEFAULT 0;

ALTER TABLE characters 
ADD COLUMN IF NOT EXISTS consecutive_days INTEGER DEFAULT 0;

ALTER TABLE characters 
ADD COLUMN IF NOT EXISTS last_activity_date TIMESTAMP WITH TIME ZONE DEFAULT NOW();

ALTER TABLE characters 
ADD COLUMN IF NOT EXISTS battle_points INTEGER DEFAULT 0;

ALTER TABLE characters 
ADD COLUMN IF NOT EXISTS stamina INTEGER DEFAULT 100;

ALTER TABLE characters 
ADD COLUMN IF NOT EXISTS max_stamina INTEGER DEFAULT 100;

ALTER TABLE characters 
ADD COLUMN IF NOT EXISTS guild_id TEXT;

ALTER TABLE characters 
ADD COLUMN IF NOT EXISTS mentor_id TEXT;

-- 3. user_idカラムが存在しない場合は追加
ALTER TABLE characters 
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id);

-- 4. 追加後の構造を確認
SELECT column_name, data_type, column_default
FROM information_schema.columns 
WHERE table_name = 'characters'
ORDER BY ordinal_position;