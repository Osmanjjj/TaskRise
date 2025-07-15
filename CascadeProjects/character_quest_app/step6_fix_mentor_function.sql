-- ステップ6: get_mentor_stats関数を修正
-- 既存の関数を削除
DROP FUNCTION IF EXISTS get_mentor_stats(UUID);

-- 新しい関数を作成
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
