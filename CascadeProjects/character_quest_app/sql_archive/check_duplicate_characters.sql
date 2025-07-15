-- 重複キャラクターの確認と整理

-- 1. ユーザーごとのキャラクター数を確認
SELECT 
    user_id, 
    COUNT(*) as character_count,
    STRING_AGG(name, ', ') as character_names,
    STRING_AGG(id::text, ', ') as character_ids
FROM characters
WHERE user_id IS NOT NULL
GROUP BY user_id
HAVING COUNT(*) > 1
ORDER BY character_count DESC;

-- 2. 全キャラクターを確認（作成日時順）
SELECT 
    id, 
    name, 
    user_id, 
    level, 
    experience,
    created_at,
    updated_at
FROM characters
ORDER BY user_id, created_at DESC;

-- 3. 最新のキャラクターのみを残すための確認
-- 各ユーザーの最新のキャラクターを表示
WITH latest_characters AS (
    SELECT DISTINCT ON (user_id) 
        id,
        name,
        user_id,
        level,
        experience,
        created_at
    FROM characters
    WHERE user_id IS NOT NULL
    ORDER BY user_id, created_at DESC
)
SELECT * FROM latest_characters;

-- 4. 重複を削除する前に、削除対象を確認
-- 各ユーザーの最新以外のキャラクターを表示
WITH latest_characters AS (
    SELECT DISTINCT ON (user_id) id
    FROM characters
    WHERE user_id IS NOT NULL
    ORDER BY user_id, created_at DESC
)
SELECT c.*
FROM characters c
WHERE c.user_id IS NOT NULL
  AND c.id NOT IN (SELECT id FROM latest_characters)
ORDER BY c.user_id, c.created_at DESC;

-- 5. 重複キャラクターを削除（実行前に必ずバックアップを取ってください）
-- コメントを外して実行
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