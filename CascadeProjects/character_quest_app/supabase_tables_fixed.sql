-- TaskRise Database Schema (Fixed)
-- Complete schema for Habitica-inspired habit and quest management app
-- Fixes circular reference issues

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Characters table (without foreign keys first)
CREATE TABLE IF NOT EXISTS characters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    level INTEGER DEFAULT 1 CHECK (level >= 1),
    experience INTEGER DEFAULT 0 CHECK (experience >= 0),
    health INTEGER DEFAULT 100 CHECK (health >= 0),
    attack INTEGER DEFAULT 10 CHECK (attack >= 0),
    defense INTEGER DEFAULT 5 CHECK (defense >= 0),
    avatar_url TEXT,
    -- TaskRise specific fields
    battle_points INTEGER DEFAULT 0 CHECK (battle_points >= 0),
    stamina INTEGER DEFAULT 100 CHECK (stamina >= 0),
    max_stamina INTEGER DEFAULT 100 CHECK (max_stamina >= 0),
    guild_id UUID, -- No constraint yet
    mentor_id UUID, -- No constraint yet
    crystal_inventory JSONB DEFAULT '{}',
    equipped_items JSONB DEFAULT '{}',
    consecutive_days INTEGER DEFAULT 0 CHECK (consecutive_days >= 0),
    last_activity_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    rank VARCHAR(20) DEFAULT 'novice',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Guilds table (without foreign keys first)
CREATE TABLE IF NOT EXISTS guilds (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    guild_type VARCHAR(20) DEFAULT 'weekly' CHECK (guild_type IN ('weekly', 'fixed')),
    max_members INTEGER DEFAULT 10 CHECK (max_members > 0),
    current_members INTEGER DEFAULT 0 CHECK (current_members >= 0),
    leader_id UUID, -- No constraint yet
    join_code VARCHAR(20) UNIQUE,
    is_private BOOLEAN DEFAULT false,
    weekly_reset_day INTEGER DEFAULT 1 CHECK (weekly_reset_day BETWEEN 1 AND 7),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Now add foreign key constraints for the circular references
ALTER TABLE characters 
    ADD CONSTRAINT fk_characters_guild FOREIGN KEY (guild_id) REFERENCES guilds(id),
    ADD CONSTRAINT fk_characters_mentor FOREIGN KEY (mentor_id) REFERENCES characters(id);

ALTER TABLE guilds
    ADD CONSTRAINT fk_guilds_leader FOREIGN KEY (leader_id) REFERENCES characters(id);

-- Tasks table
CREATE TABLE IF NOT EXISTS tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    difficulty VARCHAR(20) DEFAULT 'normal' CHECK (difficulty IN ('easy', 'normal', 'hard')),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed')),
    experience_reward INTEGER DEFAULT 10 CHECK (experience_reward >= 0),
    due_date TIMESTAMP WITH TIME ZONE,
    character_id UUID REFERENCES characters(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Subscriptions table
CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    character_id UUID REFERENCES characters(id) ON DELETE CASCADE,
    subscription_type VARCHAR(50) NOT NULL CHECK (subscription_type IN ('basic_premium', 'guild', 'battle_pass', 'enterprise')),
    price_jpy INTEGER NOT NULL CHECK (price_jpy >= 0),
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    auto_renew BOOLEAN DEFAULT true,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'expired', 'pending')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Mentor relationships table
CREATE TABLE IF NOT EXISTS mentor_relationships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    mentor_id UUID REFERENCES characters(id) ON DELETE CASCADE,
    mentee_id UUID REFERENCES characters(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'completed', 'cancelled')),
    mentor_rewards_earned INTEGER DEFAULT 0 CHECK (mentor_rewards_earned >= 0),
    mentee_progress_bonus NUMERIC(3,2) DEFAULT 1.00 CHECK (mentee_progress_bonus >= 1.00),
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ended_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(mentor_id, mentee_id)
);

-- Habit completions table
CREATE TABLE IF NOT EXISTS habit_completions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    character_id UUID REFERENCES characters(id) ON DELETE CASCADE,
    task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    battle_points_earned INTEGER DEFAULT 0 CHECK (battle_points_earned >= 0),
    stamina_earned INTEGER DEFAULT 0 CHECK (stamina_earned >= 0),
    experience_earned INTEGER DEFAULT 0 CHECK (experience_earned >= 0),
    crystals_earned JSONB DEFAULT '[]',
    is_chain_bonus BOOLEAN DEFAULT false,
    chain_length INTEGER DEFAULT 1 CHECK (chain_length >= 1),
    difficulty_multiplier NUMERIC(3,2) DEFAULT 1.00 CHECK (difficulty_multiplier >= 1.00),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Daily stats table
CREATE TABLE IF NOT EXISTS daily_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    character_id UUID REFERENCES characters(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    habits_completed INTEGER DEFAULT 0 CHECK (habits_completed >= 0),
    battle_points_earned INTEGER DEFAULT 0 CHECK (battle_points_earned >= 0),
    stamina_generated INTEGER DEFAULT 0 CHECK (stamina_generated >= 0),
    experience_gained INTEGER DEFAULT 0 CHECK (experience_gained >= 0),
    crystals_earned INTEGER DEFAULT 0 CHECK (crystals_earned >= 0),
    longest_chain INTEGER DEFAULT 0 CHECK (longest_chain >= 0),
    raid_participated BOOLEAN DEFAULT false,
    guild_quest_participated BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(character_id, date)
);

-- Game events table
CREATE TABLE IF NOT EXISTS game_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    event_type VARCHAR(50) NOT NULL CHECK (event_type IN ('raid', 'community_challenge', 'seasonal', 'guild_quest', 'special')),
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    objectives JSONB NOT NULL DEFAULT '{}',
    rewards JSONB NOT NULL DEFAULT '[]',
    min_level INTEGER DEFAULT 1 CHECK (min_level >= 1),
    priority INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Event participations table
CREATE TABLE IF NOT EXISTS event_participations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID REFERENCES game_events(id) ON DELETE CASCADE,
    character_id UUID REFERENCES characters(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    progress INTEGER DEFAULT 0 CHECK (progress >= 0),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'completed', 'abandoned')),
    rewards_claimed BOOLEAN DEFAULT false,
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(event_id, character_id)
);

-- Raid bosses table
CREATE TABLE IF NOT EXISTS raid_bosses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    max_health INTEGER NOT NULL CHECK (max_health > 0),
    current_health INTEGER NOT NULL CHECK (current_health >= 0),
    defense INTEGER DEFAULT 0 CHECK (defense >= 0),
    level INTEGER DEFAULT 1 CHECK (level >= 1),
    rewards JSONB DEFAULT '[]',
    spawn_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    defeat_time TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Raid participations table
CREATE TABLE IF NOT EXISTS raid_participations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    raid_boss_id UUID REFERENCES raid_bosses(id) ON DELETE CASCADE,
    character_id UUID REFERENCES characters(id) ON DELETE CASCADE,
    damage_dealt INTEGER DEFAULT 0 CHECK (damage_dealt >= 0),
    attacks_made INTEGER DEFAULT 0 CHECK (attacks_made >= 0),
    rewards_earned JSONB DEFAULT '[]',
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_attack_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(raid_boss_id, character_id)
);

-- Guild memberships table
CREATE TABLE IF NOT EXISTS guild_memberships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    guild_id UUID REFERENCES guilds(id) ON DELETE CASCADE,
    character_id UUID REFERENCES characters(id) ON DELETE CASCADE,
    role VARCHAR(20) DEFAULT 'member' CHECK (role IN ('leader', 'officer', 'member')),
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    contribution_points INTEGER DEFAULT 0 CHECK (contribution_points >= 0),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(guild_id, character_id)
);

-- Guild quests table
CREATE TABLE IF NOT EXISTS guild_quests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    guild_id UUID REFERENCES guilds(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    target_progress INTEGER NOT NULL CHECK (target_progress > 0),
    current_progress INTEGER DEFAULT 0 CHECK (current_progress >= 0),
    rewards JSONB DEFAULT '[]',
    start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    end_date TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'completed', 'failed', 'cancelled')),
    created_by UUID REFERENCES characters(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_tasks_character_id ON tasks(character_id);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON tasks(due_date);
CREATE INDEX IF NOT EXISTS idx_characters_level ON characters(level);
CREATE INDEX IF NOT EXISTS idx_characters_guild_id ON characters(guild_id);
CREATE INDEX IF NOT EXISTS idx_characters_last_activity ON characters(last_activity_date);
CREATE INDEX IF NOT EXISTS idx_subscriptions_character_id ON subscriptions(character_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_end_date ON subscriptions(end_date);
CREATE INDEX IF NOT EXISTS idx_mentor_relationships_mentor_id ON mentor_relationships(mentor_id);
CREATE INDEX IF NOT EXISTS idx_mentor_relationships_mentee_id ON mentor_relationships(mentee_id);
CREATE INDEX IF NOT EXISTS idx_habit_completions_character_id ON habit_completions(character_id);
CREATE INDEX IF NOT EXISTS idx_habit_completions_completed_at ON habit_completions(completed_at);
CREATE INDEX IF NOT EXISTS idx_daily_stats_character_date ON daily_stats(character_id, date);
CREATE INDEX IF NOT EXISTS idx_event_participations_event_id ON event_participations(event_id);
CREATE INDEX IF NOT EXISTS idx_event_participations_character_id ON event_participations(character_id);
CREATE INDEX IF NOT EXISTS idx_raid_participations_raid_boss_id ON raid_participations(raid_boss_id);
CREATE INDEX IF NOT EXISTS idx_guild_memberships_guild_id ON guild_memberships(guild_id);
CREATE INDEX IF NOT EXISTS idx_guild_memberships_character_id ON guild_memberships(character_id);
CREATE INDEX IF NOT EXISTS idx_guild_quests_guild_id ON guild_quests(guild_id);
CREATE INDEX IF NOT EXISTS idx_game_events_active_dates ON game_events(is_active, start_date, end_date);

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
