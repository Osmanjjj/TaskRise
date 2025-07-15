-- レベルと経験値の不整合を修正
-- 経験値に基づいて正しいレベルを設定
UPDATE characters 
SET 
    level = FLOOR(SQRT(experience / 100)) + 1,
    updated_at = NOW()
WHERE level != FLOOR(SQRT(experience / 100)) + 1;

-- 修正後の確認
SELECT 
    id,
    name,
    level,
    experience,
    (level - 1) * (level - 1) * 100 as required_min_exp,
    CASE 
        WHEN experience >= (level - 1) * (level - 1) * 100 THEN '✓ 整合性OK'
        ELSE '✗ 経験値不足'
    END as consistency_check
FROM characters
ORDER BY created_at DESC;
