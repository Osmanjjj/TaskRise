-- 既存のキャラクターをユーザーに関連付けるSQL

-- 1. 現在のユーザーとキャラクターの状態を確認
SELECT 
    'Users' as table_type,
    COUNT(*) as count
FROM auth.users
UNION ALL
SELECT 
    'Characters with user_id' as table_type,
    COUNT(*) as count
FROM characters
WHERE user_id IS NOT NULL
UNION ALL
SELECT 
    'Characters without user_id' as table_type,
    COUNT(*) as count
FROM characters
WHERE user_id IS NULL;

-- 2. user_idがNULLのキャラクターを確認
SELECT 
    id,
    name,
    level,
    experience,
    created_at
FROM characters
WHERE user_id IS NULL
ORDER BY created_at;

-- 3. 現在のユーザーを確認
SELECT 
    id,
    email,
    created_at
FROM auth.users
ORDER BY created_at;

-- 4. 既存のキャラクターをユーザーに関連付ける
-- 以下のクエリを実際のユーザーIDとキャラクターIDで実行してください
-- UPDATE characters 
-- SET user_id = 'ユーザーのUUID'
-- WHERE id = 'キャラクターのUUID';

-- 5. もし全てのキャラクターを最初のユーザーに関連付ける場合
-- （開発環境でユーザーが1人しかいない場合）
-- UPDATE characters 
-- SET user_id = (SELECT id FROM auth.users LIMIT 1)
-- WHERE user_id IS NULL;