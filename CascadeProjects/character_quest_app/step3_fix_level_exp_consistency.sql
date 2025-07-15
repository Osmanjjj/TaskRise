-- ステップ3: レベルと経験値の整合性を修正
-- レベル5なら経験値は最低でも1600必要 (level = sqrt(experience / 100) + 1)
UPDATE characters 
SET 
    experience = CASE 
        WHEN level = 1 THEN 0
        WHEN level = 2 THEN 100
        WHEN level = 3 THEN 400
        WHEN level = 4 THEN 900
        WHEN level = 5 THEN 1600
        WHEN level = 6 THEN 2500
        WHEN level = 7 THEN 3600
        WHEN level = 8 THEN 4900
        WHEN level = 9 THEN 6400
        WHEN level = 10 THEN 8100
        ELSE (level - 1) * (level - 1) * 100
    END,
    updated_at = NOW()
WHERE experience < ((level - 1) * (level - 1) * 100);
