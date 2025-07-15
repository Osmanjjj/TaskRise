-- 段階的に経験値問題を修正するSQL

-- ステップ1: 現在のキャラクターデータを確認
SELECT 
    id,
    name,
    level,
    experience,
    user_id,
    created_at,
    CASE 
        WHEN experience >= 0 THEN '✓ 正常'
        ELSE '✗ 異常'
    END as exp_status
FROM characters
ORDER BY created_at DESC;
