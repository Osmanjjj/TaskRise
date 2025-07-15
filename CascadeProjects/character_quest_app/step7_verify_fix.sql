-- ステップ7: 修正後の状態を確認
SELECT 
    id,
    name,
    level,
    experience,
    user_id,
    CASE 
        WHEN experience >= 0 THEN '✓ 正常'
        ELSE '✗ 異常'
    END as exp_status,
    CASE 
        WHEN level >= 1 THEN '✓ 正常'
        ELSE '✗ 異常'
    END as level_status,
    CASE 
        WHEN experience >= ((level - 1) * (level - 1) * 100) THEN '✓ 整合性OK'
        ELSE '✗ 整合性NG'
    END as consistency_status
FROM characters
ORDER BY created_at DESC;
