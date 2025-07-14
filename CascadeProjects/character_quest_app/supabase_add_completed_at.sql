-- tasksテーブルにcompleted_atカラムを追加
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS completed_at TIMESTAMP WITH TIME ZONE;

-- categoryカラムも追加（まだない場合）
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS category VARCHAR(50) DEFAULT 'daily';

-- categoryカラムにCHECK制約を追加
ALTER TABLE tasks
DROP CONSTRAINT IF EXISTS tasks_category_check;

ALTER TABLE tasks
ADD CONSTRAINT tasks_category_check 
CHECK (category IN ('habit', 'daily', 'work', 'exercise', 'study', 'other'));