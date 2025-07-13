-- TaskRise Database Functions
-- Custom Supabase functions for complex queries and business logic

-- Function to get mentor statistics
CREATE OR REPLACE FUNCTION get_mentor_stats(mentor_id_param UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'mentor_id', mentor_id_param,
        'total_mentees', COALESCE(total_mentees, 0),
        'active_mentees', COALESCE(active_mentees, 0),
        'completed_mentorships', COALESCE(completed_mentorships, 0),
        'total_rewards_earned', COALESCE(total_rewards_earned, 0),
        'average_mentee_progress', COALESCE(average_mentee_progress, 0.0),
        'mentor_rank', COALESCE(mentor_rank, 1),
        'last_activity_date', COALESCE(last_activity_date, NOW())
    ) INTO result
    FROM (
        SELECT 
            COUNT(*) as total_mentees,
            COUNT(CASE WHEN status = 'active' THEN 1 END) as active_mentees,
            COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_mentorships,
            SUM(mentor_rewards_earned) as total_rewards_earned,
            AVG(CASE WHEN status = 'completed' THEN mentee_progress_bonus ELSE NULL END) as average_mentee_progress,
            CASE 
                WHEN COUNT(CASE WHEN status = 'completed' THEN 1 END) >= 50 THEN 5
                WHEN COUNT(CASE WHEN status = 'completed' THEN 1 END) >= 20 THEN 4
                WHEN COUNT(CASE WHEN status = 'completed' THEN 1 END) >= 10 THEN 3
                WHEN COUNT(CASE WHEN status = 'completed' THEN 1 END) >= 3 THEN 2
                ELSE 1
            END as mentor_rank,
            MAX(updated_at) as last_activity_date
        FROM mentor_relationships 
        WHERE mentor_id = mentor_id_param
    ) stats;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get available mentors
CREATE OR REPLACE FUNCTION get_available_mentors(limit_param INTEGER DEFAULT 20)
RETURNS TABLE (
    id UUID,
    name VARCHAR,
    level INTEGER,
    avatar_url TEXT,
    mentor_rank INTEGER,
    completed_mentorships INTEGER,
    active_mentees INTEGER,
    max_mentees INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.name,
        c.level,
        c.avatar_url,
        CASE 
            WHEN COALESCE(ms.completed_mentorships, 0) >= 50 THEN 5
            WHEN COALESCE(ms.completed_mentorships, 0) >= 20 THEN 4
            WHEN COALESCE(ms.completed_mentorships, 0) >= 10 THEN 3
            WHEN COALESCE(ms.completed_mentorships, 0) >= 3 THEN 2
            ELSE 1
        END as mentor_rank,
        COALESCE(ms.completed_mentorships, 0) as completed_mentorships,
        COALESCE(ms.active_mentees, 0) as active_mentees,
        CASE 
            WHEN COALESCE(ms.completed_mentorships, 0) >= 50 THEN 20
            WHEN COALESCE(ms.completed_mentorships, 0) >= 20 THEN 15
            WHEN COALESCE(ms.completed_mentorships, 0) >= 10 THEN 10
            WHEN COALESCE(ms.completed_mentorships, 0) >= 3 THEN 5
            ELSE 2
        END as max_mentees
    FROM characters c
    LEFT JOIN (
        SELECT 
            mentor_id,
            COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_mentorships,
            COUNT(CASE WHEN status = 'active' THEN 1 END) as active_mentees
        FROM mentor_relationships 
        GROUP BY mentor_id
    ) ms ON c.id = ms.mentor_id
    WHERE c.level >= 15
    AND COALESCE(ms.active_mentees, 0) < CASE 
        WHEN COALESCE(ms.completed_mentorships, 0) >= 50 THEN 20
        WHEN COALESCE(ms.completed_mentorships, 0) >= 20 THEN 15
        WHEN COALESCE(ms.completed_mentorships, 0) >= 10 THEN 10
        WHEN COALESCE(ms.completed_mentorships, 0) >= 3 THEN 5
        ELSE 2
    END
    ORDER BY c.level DESC, COALESCE(ms.completed_mentorships, 0) DESC
    LIMIT limit_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get mentor leaderboard
CREATE OR REPLACE FUNCTION get_mentor_leaderboard(limit_param INTEGER DEFAULT 50)
RETURNS TABLE (
    mentor_id UUID,
    mentor_name VARCHAR,
    avatar_url TEXT,
    level INTEGER,
    completed_mentorships INTEGER,
    total_rewards_earned INTEGER,
    average_mentee_progress NUMERIC,
    rank INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.name,
        c.avatar_url,
        c.level,
        COALESCE(ms.completed_mentorships, 0),
        COALESCE(ms.total_rewards_earned, 0),
        COALESCE(ms.average_mentee_progress, 0.0),
        ROW_NUMBER() OVER (ORDER BY COALESCE(ms.completed_mentorships, 0) DESC, COALESCE(ms.total_rewards_earned, 0) DESC)::INTEGER
    FROM characters c
    LEFT JOIN (
        SELECT 
            mentor_id,
            COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_mentorships,
            SUM(mentor_rewards_earned) as total_rewards_earned,
            AVG(CASE WHEN status = 'completed' THEN mentee_progress_bonus ELSE NULL END) as average_mentee_progress
        FROM mentor_relationships 
        GROUP BY mentor_id
    ) ms ON c.id = ms.mentor_id
    WHERE c.level >= 15 AND COALESCE(ms.completed_mentorships, 0) > 0
    ORDER BY COALESCE(ms.completed_mentorships, 0) DESC, COALESCE(ms.total_rewards_earned, 0) DESC
    LIMIT limit_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get event leaderboard
CREATE OR REPLACE FUNCTION get_event_leaderboard(event_id_param UUID, limit_param INTEGER DEFAULT 50)
RETURNS TABLE (
    character_id UUID,
    character_name VARCHAR,
    avatar_url TEXT,
    level INTEGER,
    progress INTEGER,
    rank INTEGER,
    last_activity TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.name,
        c.avatar_url,
        c.level,
        ep.progress,
        ROW_NUMBER() OVER (ORDER BY ep.progress DESC, ep.last_activity DESC)::INTEGER,
        ep.last_activity
    FROM event_participations ep
    JOIN characters c ON ep.character_id = c.id
    WHERE ep.event_id = event_id_param
    ORDER BY ep.progress DESC, ep.last_activity DESC
    LIMIT limit_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get event statistics
CREATE OR REPLACE FUNCTION get_event_statistics(event_id_param UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'total_participants', COUNT(*),
        'active_participants', COUNT(CASE WHEN status = 'active' THEN 1 END),
        'completed_participants', COUNT(CASE WHEN status = 'completed' THEN 1 END),
        'average_progress', COALESCE(AVG(progress), 0),
        'total_rewards_claimed', COUNT(CASE WHEN rewards_claimed = true THEN 1 END),
        'progress_distribution', json_build_object(
            '0-25', COUNT(CASE WHEN progress BETWEEN 0 AND 25 THEN 1 END),
            '26-50', COUNT(CASE WHEN progress BETWEEN 26 AND 50 THEN 1 END),
            '51-75', COUNT(CASE WHEN progress BETWEEN 51 AND 75 THEN 1 END),
            '76-100', COUNT(CASE WHEN progress >= 76 THEN 1 END)
        )
    ) INTO result
    FROM event_participations
    WHERE event_id = event_id_param;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get revenue analytics
CREATE OR REPLACE FUNCTION get_revenue_analytics(start_date TIMESTAMP WITH TIME ZONE, end_date TIMESTAMP WITH TIME ZONE)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'total_revenue', COALESCE(SUM(price_jpy), 0),
        'total_subscriptions', COUNT(*),
        'revenue_by_type', json_object_agg(subscription_type, type_revenue),
        'subscriptions_by_type', json_object_agg(subscription_type, type_count),
        'new_subscriptions', COUNT(CASE WHEN created_at BETWEEN start_date AND end_date THEN 1 END),
        'cancelled_subscriptions', COUNT(CASE WHEN status = 'cancelled' AND updated_at BETWEEN start_date AND end_date THEN 1 END),
        'churn_rate', CASE 
            WHEN COUNT(*) > 0 THEN 
                COUNT(CASE WHEN status = 'cancelled' AND updated_at BETWEEN start_date AND end_date THEN 1 END)::NUMERIC / COUNT(*)::NUMERIC
            ELSE 0
        END
    ) INTO result
    FROM (
        SELECT 
            subscription_type,
            price_jpy,
            status,
            created_at,
            updated_at,
            SUM(price_jpy) OVER (PARTITION BY subscription_type) as type_revenue,
            COUNT(*) OVER (PARTITION BY subscription_type) as type_count
        FROM subscriptions
        WHERE created_at BETWEEN start_date AND end_date
    ) sub_data;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate level from experience
CREATE OR REPLACE FUNCTION calculate_level_from_experience(exp INTEGER)
RETURNS INTEGER AS $$
BEGIN
    -- Experience formula: level = floor(sqrt(exp / 100)) + 1
    RETURN GREATEST(1, FLOOR(SQRT(exp / 100.0)) + 1);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to calculate experience needed for next level
CREATE OR REPLACE FUNCTION experience_for_next_level(current_level INTEGER)
RETURNS INTEGER AS $$
BEGIN
    -- Experience formula: exp_needed = (level^2) * 100
    RETURN (current_level * current_level) * 100;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to update character level based on experience
CREATE OR REPLACE FUNCTION update_character_level()
RETURNS TRIGGER AS $$
DECLARE
    new_level INTEGER;
BEGIN
    new_level := calculate_level_from_experience(NEW.experience);
    
    -- Only update if level actually changed
    IF new_level != NEW.level THEN
        NEW.level := new_level;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-update character level when experience changes
CREATE TRIGGER update_character_level_trigger
    BEFORE UPDATE OF experience ON characters
    FOR EACH ROW
    EXECUTE FUNCTION update_character_level();

-- Function to generate raid boss rewards
CREATE OR REPLACE FUNCTION generate_raid_rewards(boss_level INTEGER, damage_contribution NUMERIC)
RETURNS JSONB AS $$
DECLARE
    base_rewards JSONB;
    scaled_rewards JSONB;
BEGIN
    -- Base rewards structure
    base_rewards := jsonb_build_object(
        'experience', 50 + (boss_level * 10),
        'battle_points', 10 + (boss_level * 2),
        'crystals', jsonb_build_array(
            jsonb_build_object('type', 'blue', 'amount', 2 + FLOOR(boss_level / 5)),
            jsonb_build_object('type', 'green', 'amount', 1 + FLOOR(boss_level / 10))
        )
    );
    
    -- Scale rewards based on damage contribution (0.1 to 2.0 multiplier)
    scaled_rewards := jsonb_build_object(
        'experience', FLOOR((base_rewards->>'experience')::INTEGER * GREATEST(0.1, LEAST(2.0, damage_contribution))),
        'battle_points', FLOOR((base_rewards->>'battle_points')::INTEGER * GREATEST(0.1, LEAST(2.0, damage_contribution))),
        'crystals', base_rewards->'crystals'
    );
    
    RETURN scaled_rewards;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to clean up expired subscriptions
CREATE OR REPLACE FUNCTION cleanup_expired_subscriptions()
RETURNS INTEGER AS $$
DECLARE
    updated_count INTEGER;
BEGIN
    UPDATE subscriptions 
    SET status = 'expired'
    WHERE end_date < NOW() 
    AND status = 'active';
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RETURN updated_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get character statistics
CREATE OR REPLACE FUNCTION get_character_stats(character_id_param UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'total_tasks_completed', COALESCE(task_stats.completed_tasks, 0),
        'total_experience_earned', COALESCE(habit_stats.total_experience, 0),
        'total_battle_points_earned', COALESCE(habit_stats.total_battle_points, 0),
        'total_crystals_earned', COALESCE(habit_stats.total_crystals, 0),
        'current_streak', COALESCE(c.consecutive_days, 0),
        'longest_chain', COALESCE(habit_stats.longest_chain, 0),
        'raids_participated', COALESCE(raid_stats.raids_count, 0),
        'guild_quests_completed', COALESCE(guild_stats.quests_completed, 0),
        'events_participated', COALESCE(event_stats.events_count, 0),
        'mentorships_completed', COALESCE(mentor_stats.mentorships_completed, 0)
    ) INTO result
    FROM characters c
    LEFT JOIN (
        SELECT 
            character_id,
            COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_tasks
        FROM tasks 
        WHERE character_id = character_id_param
        GROUP BY character_id
    ) task_stats ON c.id = task_stats.character_id
    LEFT JOIN (
        SELECT 
            character_id,
            SUM(experience_earned) as total_experience,
            SUM(battle_points_earned) as total_battle_points,
            SUM(JSONB_ARRAY_LENGTH(crystals_earned)) as total_crystals,
            MAX(chain_length) as longest_chain
        FROM habit_completions 
        WHERE character_id = character_id_param
        GROUP BY character_id
    ) habit_stats ON c.id = habit_stats.character_id
    LEFT JOIN (
        SELECT 
            character_id,
            COUNT(*) as raids_count
        FROM raid_participations 
        WHERE character_id = character_id_param
        GROUP BY character_id
    ) raid_stats ON c.id = raid_stats.character_id
    LEFT JOIN (
        SELECT 
            gm.character_id,
            COUNT(gq.id) as quests_completed
        FROM guild_memberships gm
        JOIN guild_quests gq ON gm.guild_id = gq.guild_id
        WHERE gm.character_id = character_id_param AND gq.status = 'completed'
        GROUP BY gm.character_id
    ) guild_stats ON c.id = guild_stats.character_id
    LEFT JOIN (
        SELECT 
            character_id,
            COUNT(*) as events_count
        FROM event_participations 
        WHERE character_id = character_id_param
        GROUP BY character_id
    ) event_stats ON c.id = event_stats.character_id
    LEFT JOIN (
        SELECT 
            mentor_id as character_id,
            COUNT(CASE WHEN status = 'completed' THEN 1 END) as mentorships_completed
        FROM mentor_relationships 
        WHERE mentor_id = character_id_param
        GROUP BY mentor_id
    ) mentor_stats ON c.id = mentor_stats.character_id
    WHERE c.id = character_id_param;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
