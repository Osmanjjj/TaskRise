-- ===============================================
-- TaskRise Advanced Database Schema
-- Habitica-inspired habit formation app with raid battles
-- ===============================================

-- ===== CORE EXTENSIONS =====

-- Extend characters table
ALTER TABLE characters ADD COLUMN IF NOT EXISTS battle_points INTEGER DEFAULT 0;
ALTER TABLE characters ADD COLUMN IF NOT EXISTS stamina INTEGER DEFAULT 0;
ALTER TABLE characters ADD COLUMN IF NOT EXISTS max_stamina INTEGER DEFAULT 100;
ALTER TABLE characters ADD COLUMN IF NOT EXISTS guild_id UUID;
ALTER TABLE characters ADD COLUMN IF NOT EXISTS mentor_id UUID;
ALTER TABLE characters ADD COLUMN IF NOT EXISTS total_crystals_earned INTEGER DEFAULT 0;
ALTER TABLE characters ADD COLUMN IF NOT EXISTS consecutive_days INTEGER DEFAULT 0;
ALTER TABLE characters ADD COLUMN IF NOT EXISTS last_activity_date DATE DEFAULT CURRENT_DATE;

-- ===== CRYSTAL SYSTEM =====

-- Crystal types and inventory
CREATE TABLE crystals (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    character_id UUID REFERENCES characters(id) ON DELETE CASCADE,
    crystal_type VARCHAR(20) NOT NULL CHECK (crystal_type IN ('blue', 'green', 'gold', 'rainbow')),
    quantity INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Gacha/Collection system
CREATE TABLE collectibles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    rarity VARCHAR(20) NOT NULL CHECK (rarity IN ('common', 'rare', 'epic', 'legendary', 'mythic')),
    type VARCHAR(30) NOT NULL CHECK (type IN ('character', 'weapon', 'armor', 'pet', 'mount', 'skill')),
    image_url TEXT,
    description TEXT,
    stats JSONB, -- Store character stats, skill effects, etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User's collection
CREATE TABLE user_collectibles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    character_id UUID REFERENCES characters(id) ON DELETE CASCADE,
    collectible_id UUID REFERENCES collectibles(id) ON DELETE CASCADE,
    quantity INTEGER DEFAULT 1,
    obtained_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(character_id, collectible_id)
);

-- ===== RAID BATTLE SYSTEM =====

-- Raid bosses
CREATE TABLE raid_bosses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    image_url TEXT,
    max_hp INTEGER NOT NULL,
    current_hp INTEGER NOT NULL,
    reward_crystals JSONB, -- {"blue": 5, "green": 2, "gold": 1}
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'defeated', 'expired')),
    max_participants INTEGER DEFAULT 100,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Raid battle participation
CREATE TABLE raid_participations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    raid_boss_id UUID REFERENCES raid_bosses(id) ON DELETE CASCADE,
    character_id UUID REFERENCES characters(id) ON DELETE CASCADE,
    damage_dealt INTEGER DEFAULT 0,
    battle_points_used INTEGER DEFAULT 0,
    rewards_claimed BOOLEAN DEFAULT FALSE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(raid_boss_id, character_id)
);

-- ===== GUILD SYSTEM =====

-- Guilds
CREATE TABLE guilds (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    type VARCHAR(20) DEFAULT 'free' CHECK (type IN ('free', 'premium', 'enterprise')),
    max_members INTEGER DEFAULT 50,
    current_members INTEGER DEFAULT 0,
    guild_master_id UUID REFERENCES characters(id),
    weekly_goal INTEGER DEFAULT 1000,
    current_progress INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Guild memberships
CREATE TABLE guild_memberships (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    guild_id UUID REFERENCES guilds(id) ON DELETE CASCADE,
    character_id UUID REFERENCES characters(id) ON DELETE CASCADE,
    role VARCHAR(20) DEFAULT 'member' CHECK (role IN ('master', 'officer', 'member')),
    contribution_points INTEGER DEFAULT 0,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(guild_id, character_id)
);

-- Guild quests
CREATE TABLE guild_quests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    guild_id UUID REFERENCES guilds(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    goal_type VARCHAR(30) NOT NULL, -- 'total_tasks', 'collective_exercise', etc.
    goal_value INTEGER NOT NULL,
    current_progress INTEGER DEFAULT 0,
    reward_crystals JSONB,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'completed', 'failed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===== MENTOR SYSTEM =====

-- Mentor relationships
CREATE TABLE mentor_relationships (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    mentor_id UUID REFERENCES characters(id) ON DELETE CASCADE,
    mentee_id UUID REFERENCES characters(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('pending', 'active', 'completed', 'cancelled')),
    mentor_rewards_earned INTEGER DEFAULT 0,
    mentee_progress_bonus NUMERIC(3,2) DEFAULT 1.0, -- 1.0 = 100%, 1.2 = 120%
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ended_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(mentor_id, mentee_id)
);

-- ===== SUBSCRIPTION SYSTEM =====

-- User subscriptions
CREATE TABLE subscriptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    character_id UUID REFERENCES characters(id) ON DELETE CASCADE,
    subscription_type VARCHAR(30) NOT NULL CHECK (subscription_type IN ('basic', 'guild', 'battle_pass', 'enterprise')),
    price_jpy INTEGER NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    auto_renew BOOLEAN DEFAULT TRUE,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'expired')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===== EXTENDED TASK SYSTEM =====

-- Add habit tracking fields to tasks
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS task_type VARCHAR(20) DEFAULT 'task' CHECK (task_type IN ('task', 'habit', 'daily'));
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS streak_count INTEGER DEFAULT 0;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS battle_points_reward INTEGER DEFAULT 10;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS stamina_cost INTEGER DEFAULT 0;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS crystal_reward_type VARCHAR(20) CHECK (crystal_reward_type IN ('blue', 'green', 'gold', 'rainbow'));
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS is_guild_quest BOOLEAN DEFAULT FALSE;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS guild_quest_id UUID REFERENCES guild_quests(id);

-- Habit completion history
CREATE TABLE habit_completions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
    character_id UUID REFERENCES characters(id) ON DELETE CASCADE,
    completion_date DATE NOT NULL,
    battle_points_earned INTEGER DEFAULT 0,
    crystals_earned JSONB, -- {"blue": 1, "green": 0}
    streak_count INTEGER DEFAULT 1,
    completion_time TIME,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(task_id, character_id, completion_date)
);

-- ===== EVENTS AND COMPETITIONS =====

-- Special events
CREATE TABLE events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    event_type VARCHAR(30) NOT NULL CHECK (event_type IN ('raid_tournament', 'guild_war', 'crystal_festival', 'mentor_appreciation')),
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    rewards JSONB, -- Special event rewards
    status VARCHAR(20) DEFAULT 'upcoming' CHECK (status IN ('upcoming', 'active', 'completed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Event participations
CREATE TABLE event_participations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    event_id UUID REFERENCES events(id) ON DELETE CASCADE,
    character_id UUID REFERENCES characters(id) ON DELETE CASCADE,
    score INTEGER DEFAULT 0,
    rank INTEGER,
    rewards_claimed BOOLEAN DEFAULT FALSE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(event_id, character_id)
);

-- ===== ANALYTICS AND STATS =====

-- Daily user stats
CREATE TABLE daily_stats (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    character_id UUID REFERENCES characters(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    tasks_completed INTEGER DEFAULT 0,
    battle_points_earned INTEGER DEFAULT 0,
    crystals_earned JSONB DEFAULT '{}',
    stamina_used INTEGER DEFAULT 0,
    guild_contribution INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(character_id, date)
);

-- ===== INDEXES FOR PERFORMANCE =====

-- Crystal system indexes
CREATE INDEX idx_crystals_character_id ON crystals(character_id);
CREATE INDEX idx_crystals_type ON crystals(crystal_type);

-- Raid battle indexes
CREATE INDEX idx_raid_bosses_status_time ON raid_bosses(status, start_time, end_time);
CREATE INDEX idx_raid_participations_boss_id ON raid_participations(raid_boss_id);
CREATE INDEX idx_raid_participations_character_id ON raid_participations(character_id);

-- Guild system indexes
CREATE INDEX idx_guild_memberships_guild_id ON guild_memberships(guild_id);
CREATE INDEX idx_guild_memberships_character_id ON guild_memberships(character_id);
CREATE INDEX idx_guild_quests_guild_id ON guild_quests(guild_id);

-- Habit tracking indexes
CREATE INDEX idx_habit_completions_character_date ON habit_completions(character_id, completion_date);
CREATE INDEX idx_habit_completions_task_id ON habit_completions(task_id);
CREATE INDEX idx_daily_stats_character_date ON daily_stats(character_id, date);

-- ===== FUNCTIONS AND TRIGGERS =====

-- Function to update crystal inventory
CREATE OR REPLACE FUNCTION update_crystal_inventory(
    p_character_id UUID,
    p_crystal_type VARCHAR(20),
    p_quantity INTEGER
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO crystals (character_id, crystal_type, quantity)
    VALUES (p_character_id, p_crystal_type, p_quantity)
    ON CONFLICT (character_id, crystal_type) 
    DO UPDATE SET 
        quantity = crystals.quantity + p_quantity,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- Function to calculate streak and rewards
CREATE OR REPLACE FUNCTION complete_habit_task(
    p_task_id UUID,
    p_character_id UUID
)
RETURNS TABLE(
    battle_points INTEGER,
    crystals_earned JSONB,
    new_streak INTEGER
) AS $$
DECLARE
    v_streak INTEGER;
    v_last_completion DATE;
    v_battle_points INTEGER;
    v_crystals JSONB DEFAULT '{}';
BEGIN
    -- Get last completion date and current streak
    SELECT completion_date, streak_count INTO v_last_completion, v_streak
    FROM habit_completions 
    WHERE task_id = p_task_id AND character_id = p_character_id 
    ORDER BY completion_date DESC LIMIT 1;
    
    -- Calculate new streak
    IF v_last_completion IS NULL OR v_last_completion < CURRENT_DATE - INTERVAL '1 day' THEN
        v_streak := 1;
    ELSIF v_last_completion = CURRENT_DATE - INTERVAL '1 day' THEN
        v_streak := COALESCE(v_streak, 0) + 1;
    ELSE
        -- Already completed today, return existing values
        RETURN QUERY SELECT 0, '{}'::JSONB, v_streak;
        RETURN;
    END IF;
    
    -- Calculate battle points (base + streak bonus)
    v_battle_points := 10 + (v_streak - 1) * 2;
    
    -- Calculate crystal rewards based on streak
    v_crystals := jsonb_build_object('blue', 1);
    IF v_streak % 7 = 0 THEN
        v_crystals := v_crystals || jsonb_build_object('green', 1);
    END IF;
    IF v_streak % 30 = 0 THEN
        v_crystals := v_crystals || jsonb_build_object('gold', 1);
    END IF;
    
    -- Insert completion record
    INSERT INTO habit_completions (
        task_id, character_id, completion_date, 
        battle_points_earned, crystals_earned, streak_count
    ) VALUES (
        p_task_id, p_character_id, CURRENT_DATE,
        v_battle_points, v_crystals, v_streak
    ) ON CONFLICT (task_id, character_id, completion_date) DO NOTHING;
    
    -- Update character stats
    UPDATE characters SET 
        battle_points = battle_points + v_battle_points,
        experience = experience + v_battle_points,
        updated_at = NOW()
    WHERE id = p_character_id;
    
    -- Update crystal inventory
    PERFORM update_crystal_inventory(p_character_id, 'blue', (v_crystals->>'blue')::INTEGER);
    IF v_crystals ? 'green' THEN
        PERFORM update_crystal_inventory(p_character_id, 'green', (v_crystals->>'green')::INTEGER);
    END IF;
    IF v_crystals ? 'gold' THEN
        PERFORM update_crystal_inventory(p_character_id, 'gold', (v_crystals->>'gold')::INTEGER);
    END IF;
    
    RETURN QUERY SELECT v_battle_points, v_crystals, v_streak;
END;
$$ LANGUAGE plpgsql;

-- ===== FOREIGN KEY CONSTRAINTS =====

-- Add foreign key for guild membership in characters
ALTER TABLE characters ADD CONSTRAINT fk_characters_guild 
    FOREIGN KEY (guild_id) REFERENCES guilds(id) ON DELETE SET NULL;

-- Add foreign key for mentor relationship
ALTER TABLE characters ADD CONSTRAINT fk_characters_mentor 
    FOREIGN KEY (mentor_id) REFERENCES characters(id) ON DELETE SET NULL;

-- ===== ROW LEVEL SECURITY =====

-- Enable RLS on new tables
ALTER TABLE crystals ENABLE ROW LEVEL SECURITY;
ALTER TABLE collectibles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_collectibles ENABLE ROW LEVEL SECURITY;
ALTER TABLE raid_bosses ENABLE ROW LEVEL SECURITY;
ALTER TABLE raid_participations ENABLE ROW LEVEL SECURITY;
ALTER TABLE guilds ENABLE ROW LEVEL SECURITY;
ALTER TABLE guild_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE guild_quests ENABLE ROW LEVEL SECURITY;
ALTER TABLE mentor_relationships ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE habit_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_participations ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_stats ENABLE ROW LEVEL SECURITY;

-- Create policies (simplified for development - in production, implement proper auth-based policies)
CREATE POLICY "Allow all operations on crystals" ON crystals FOR ALL USING (true);
CREATE POLICY "Allow all operations on collectibles" ON collectibles FOR ALL USING (true);
CREATE POLICY "Allow all operations on user_collectibles" ON user_collectibles FOR ALL USING (true);
CREATE POLICY "Allow all operations on raid_bosses" ON raid_bosses FOR ALL USING (true);
CREATE POLICY "Allow all operations on raid_participations" ON raid_participations FOR ALL USING (true);
CREATE POLICY "Allow all operations on guilds" ON guilds FOR ALL USING (true);
CREATE POLICY "Allow all operations on guild_memberships" ON guild_memberships FOR ALL USING (true);
CREATE POLICY "Allow all operations on guild_quests" ON guild_quests FOR ALL USING (true);
CREATE POLICY "Allow all operations on mentor_relationships" ON mentor_relationships FOR ALL USING (true);
CREATE POLICY "Allow all operations on subscriptions" ON subscriptions FOR ALL USING (true);
CREATE POLICY "Allow all operations on habit_completions" ON habit_completions FOR ALL USING (true);
CREATE POLICY "Allow all operations on events" ON events FOR ALL USING (true);
CREATE POLICY "Allow all operations on event_participations" ON event_participations FOR ALL USING (true);
CREATE POLICY "Allow all operations on daily_stats" ON daily_stats FOR ALL USING (true);

-- ===== SAMPLE DATA FOR TESTING =====

-- Insert sample collectibles
INSERT INTO collectibles (name, rarity, type, description) VALUES
('初心者の剣', 'common', 'weapon', '冒険を始めたばかりの勇者が手にする基本的な剣'),
('炎の精霊', 'rare', 'character', '火の力を操る美しい精霊'),
('竜の鎧', 'epic', 'armor', '古代竜の鱗で作られた強固な鎧'),
('光の騎士', 'legendary', 'character', '正義の心を持つ伝説の騎士'),
('時空の支配者', 'mythic', 'character', '時間と空間を操る究極の存在');

-- Insert sample raid boss
INSERT INTO raid_bosses (name, description, max_hp, current_hp, reward_crystals, start_time, end_time) VALUES
('ダークドラゴン', '闇の力に支配された古代の竜', 10000, 10000, 
 '{"blue": 10, "green": 5, "gold": 2, "rainbow": 1}',
 NOW() + INTERVAL '1 hour',
 NOW() + INTERVAL '3 hours');

-- Create triggers for updated_at
CREATE TRIGGER update_crystals_updated_at BEFORE UPDATE ON crystals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_guilds_updated_at BEFORE UPDATE ON guilds
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscriptions_updated_at BEFORE UPDATE ON subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
