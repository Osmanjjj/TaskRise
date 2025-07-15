-- ステップ2: 経験値がマイナスまたは異常値のキャラクターを修正
UPDATE characters 
SET 
    experience = GREATEST(0, experience),  -- 経験値を0以上に修正
    level = GREATEST(1, level),           -- レベルを1以上に修正
    updated_at = NOW()
WHERE experience < 0 OR level < 1;
