-- データベース状態確認
-- 1. テーブル一覧
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- 2. charactersテーブル構造
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'characters' 
ORDER BY ordinal_position;

-- 3. 現在のデータ確認
SELECT COUNT(*) as total_characters FROM characters;
SELECT * FROM characters LIMIT 3;

-- 4. サンプルデータ確認
SELECT 
    c.name, 
    c.level, 
    c.experience,
    COUNT(ds.id) as daily_stats_count
FROM characters c
LEFT JOIN daily_stats ds ON c.id = ds.character_id
GROUP BY c.id, c.name, c.level, c.experience;
