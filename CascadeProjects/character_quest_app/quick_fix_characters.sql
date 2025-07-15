-- 既存のキャラクターを現在のユーザーに関連付ける簡単な修正

-- 1. 現在の状態を確認
SELECT 
    'Total Characters' as status,
    COUNT(*) as count
FROM characters
UNION ALL
SELECT 
    'Characters with user_id' as status,
    COUNT(*) as count
FROM characters
WHERE user_id IS NOT NULL
UNION ALL
SELECT 
    'Characters without user_id' as status,
    COUNT(*) as count
FROM characters
WHERE user_id IS NULL;

-- 2. user_idがNULLの全てのキャラクターを最初のユーザーに関連付ける
-- （開発環境用：本番環境では適切なマッピングが必要）
UPDATE characters 
SET user_id = (SELECT id FROM auth.users ORDER BY created_at LIMIT 1)
WHERE user_id IS NULL;

-- 3. 更新結果を確認
SELECT 
    c.id,
    c.name,
    c.level,
    c.experience,
    c.user_id,
    u.email
FROM characters c
LEFT JOIN auth.users u ON c.user_id = u.id
ORDER BY c.created_at DESC;