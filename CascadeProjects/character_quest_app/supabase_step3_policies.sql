-- Step 3: Add Row Level Security and functions
-- Run this AFTER step 2 is completed successfully

-- Row Level Security (RLS)
ALTER TABLE characters ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE mentor_relationships ENABLE ROW LEVEL SECURITY;
ALTER TABLE habit_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_participations ENABLE ROW LEVEL SECURITY;
ALTER TABLE raid_bosses ENABLE ROW LEVEL SECURITY;
ALTER TABLE raid_participations ENABLE ROW LEVEL SECURITY;
ALTER TABLE guilds ENABLE ROW LEVEL SECURITY;
ALTER TABLE guild_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE guild_quests ENABLE ROW LEVEL SECURITY;

-- RLS Policies (basic policies - adjust based on your auth requirements)
CREATE POLICY "Users can view all characters" ON characters FOR SELECT USING (true);
CREATE POLICY "Users can update own character" ON characters FOR UPDATE USING (auth.uid()::text = id::text);
CREATE POLICY "Users can view all tasks" ON tasks FOR SELECT USING (true);
CREATE POLICY "Users can manage own tasks" ON tasks FOR ALL USING (auth.uid()::text = character_id::text);
CREATE POLICY "Users can view own subscriptions" ON subscriptions FOR SELECT USING (auth.uid()::text = character_id::text);
CREATE POLICY "Users can manage own subscriptions" ON subscriptions FOR ALL USING (auth.uid()::text = character_id::text);
CREATE POLICY "Users can view mentor relationships" ON mentor_relationships FOR SELECT USING (auth.uid()::text = mentor_id::text OR auth.uid()::text = mentee_id::text);
CREATE POLICY "Users can manage own habit completions" ON habit_completions FOR ALL USING (auth.uid()::text = character_id::text);
CREATE POLICY "Users can view own daily stats" ON daily_stats FOR SELECT USING (auth.uid()::text = character_id::text);
CREATE POLICY "Users can view all game events" ON game_events FOR SELECT USING (true);
CREATE POLICY "Users can view own event participations" ON event_participations FOR SELECT USING (auth.uid()::text = character_id::text);
CREATE POLICY "Users can view all raid bosses" ON raid_bosses FOR SELECT USING (true);
CREATE POLICY "Users can view own raid participations" ON raid_participations FOR SELECT USING (auth.uid()::text = character_id::text);
CREATE POLICY "Users can view all guilds" ON guilds FOR SELECT USING (true);
CREATE POLICY "Users can view guild memberships" ON guild_memberships FOR SELECT USING (true);
CREATE POLICY "Users can view guild quests" ON guild_quests FOR SELECT USING (true);

-- Triggers for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_characters_updated_at BEFORE UPDATE ON characters
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscriptions_updated_at BEFORE UPDATE ON subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_mentor_relationships_updated_at BEFORE UPDATE ON mentor_relationships
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_game_events_updated_at BEFORE UPDATE ON game_events
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_raid_bosses_updated_at BEFORE UPDATE ON raid_bosses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_guilds_updated_at BEFORE UPDATE ON guilds
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_guild_memberships_updated_at BEFORE UPDATE ON guild_memberships
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_guild_quests_updated_at BEFORE UPDATE ON guild_quests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Mentor stats function
CREATE OR REPLACE FUNCTION get_mentor_stats(mentor_id_param UUID)
RETURNS TABLE(
    total_mentees INTEGER,
    active_mentees INTEGER,
    completed_mentorships INTEGER,
    total_rewards_earned INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as total_mentees,
        COUNT(CASE WHEN mr.status = 'active' THEN 1 END)::INTEGER as active_mentees,
        COUNT(CASE WHEN mr.status = 'completed' THEN 1 END)::INTEGER as completed_mentorships,
        COALESCE(SUM(mr.mentor_rewards_earned), 0)::INTEGER as total_rewards_earned
    FROM mentor_relationships mr
    WHERE mr.mentor_id = mentor_id_param;
END;
$$ LANGUAGE plpgsql;
