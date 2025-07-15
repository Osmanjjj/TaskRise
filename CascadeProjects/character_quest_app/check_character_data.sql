-- 現在のキャラクターデータを詳細確認
SELECT 
    id,
    name,
    level,
    experience,
    user_id,
    -- レベルに必要な最小経験値を計算
    (level - 1) * (level - 1) * 100 as required_min_exp,
    -- 経験値が足りているかチェック
    CASE 
        WHEN experience >= (level - 1) * (level - 1) * 100 THEN '✓ 整合性OK'
        ELSE '✗ 経験値不足'
    END as consistency_check,
    -- 経験値に基づく正しいレベルを計算
    FLOOR(SQRT(experience / 100)) + 1 as correct_level_for_exp
FROM characters
ORDER BY created_at DESC;
