-- 経験値がマイナスになっている問題を修正

-- 1. 現在のキャラクターデータを確認
SELECT 
    id,
    name,
    level,
    experience,
    user_id,
    created_at
FROM characters
ORDER BY created_at DESC;

-- 2. 経験値がマイナスまたは異常値のキャラクターを修正
UPDATE characters 
SET 
    experience = GREATEST(0, experience),  -- 経験値を0以上に修正
    level = GREATEST(1, level),           -- レベルを1以上に修正
    updated_at = NOW()
WHERE experience < 0 OR level < 1;

-- 3. レベルと経験値の整合性を修正
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

-- 4. user_idがNULLのキャラクターを修正
-- 最初のユーザーIDを取得して設定
UPDATE characters 
SET user_id = (
    SELECT id 
    FROM auth.users 
    ORDER BY created_at 
    LIMIT 1
)
WHERE user_id IS NULL;

-- 5. 修正後の状態を確認
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
    END as level_status
FROM characters
ORDER BY created_at DESC;

-- 6. mentor_relationshipsテーブルが存在しない場合は作成
CREATE TABLE IF NOT EXISTS mentor_relationships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mentor_id UUID REFERENCES characters(id) ON DELETE CASCADE,
    mentee_id UUID REFERENCES characters(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(mentor_id, mentee_id)
);

-- 7. get_mentor_stats関数を修正
CREATE OR REPLACE FUNCTION get_mentor_stats(character_uuid UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'total_mentees', COALESCE(COUNT(mr.mentee_id), 0),
        'active_mentees', COALESCE(COUNT(CASE WHEN c.updated_at > NOW() - INTERVAL '7 days' THEN 1 END), 0),
        'total_experience_given', COALESCE(SUM(c.experience), 0)
    )
    INTO result
    FROM mentor_relationships mr
    LEFT JOIN characters c ON mr.mentee_id = c.id
    WHERE mr.mentor_id = character_uuid;
    
    RETURN COALESCE(result, '{"total_mentees": 0, "active_mentees": 0, "total_experience_given": 0}'::JSON);
END;
$$ LANGUAGE plpgsql;
