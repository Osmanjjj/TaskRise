-- tasksテーブルに不足しているカラムを追加

-- categoryカラムを追加
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS category VARCHAR(50) DEFAULT 'other';

-- その他の必要なカラムも確認・追加
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS experience_reward INTEGER DEFAULT 20;

ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS completed_at TIMESTAMP WITH TIME ZONE;

-- 確認クエリ
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'tasks' 
AND column_name IN ('category', 'experience_reward', 'completed_at')
ORDER BY column_name;

-- tasksテーブル全体の構造確認
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'tasks' 
ORDER BY ordinal_position;
