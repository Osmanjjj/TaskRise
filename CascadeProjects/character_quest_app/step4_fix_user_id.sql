-- ステップ4: user_idがNULLのキャラクターを修正
-- 最初のユーザーIDを取得して設定
UPDATE characters 
SET user_id = (
    SELECT id 
    FROM auth.users 
    ORDER BY created_at 
    LIMIT 1
)
WHERE user_id IS NULL;
