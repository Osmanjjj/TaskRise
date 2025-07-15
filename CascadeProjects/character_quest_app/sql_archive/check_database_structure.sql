-- tasksテーブルの構造を確認
SELECT 
    column_name, 
    data_type, 
    column_default,
    is_nullable
FROM 
    information_schema.columns
WHERE 
    table_name = 'tasks'
ORDER BY 
    ordinal_position;

-- charactersテーブルの構造を確認
SELECT 
    column_name, 
    data_type, 
    column_default,
    is_nullable
FROM 
    information_schema.columns
WHERE 
    table_name = 'characters'
ORDER BY 
    ordinal_position;

-- 現在のユーザーに関連するキャラクターを確認
-- ユーザーIDを実際のものに置き換えてください
-- SELECT * FROM characters WHERE user_id = 'YOUR_USER_ID';