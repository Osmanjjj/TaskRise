-- テーブル構造確認
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'characters' 
ORDER BY ordinal_position;

-- 全キャラクターデータ確認
SELECT * FROM characters LIMIT 5;

-- 重複キャラクター確認（user_idが存在する場合）
SELECT 
    user_id, 
    COUNT(*) as count,
    STRING_AGG(name, ', ') as names
FROM characters
WHERE user_id IS NOT NULL
GROUP BY user_id
HAVING COUNT(*) > 1;

-- 重複削除（各ユーザーの最新キャラクターのみ保持）
/*
WITH latest_characters AS (
    SELECT DISTINCT ON (user_id) id
    FROM characters
    WHERE user_id IS NOT NULL
    ORDER BY user_id, created_at DESC
)
DELETE FROM characters
WHERE user_id IS NOT NULL
  AND id NOT IN (SELECT id FROM latest_characters);
*/
