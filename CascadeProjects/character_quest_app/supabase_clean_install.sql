-- Clean install - Drop existing tables and recreate
-- WARNING: This will delete all existing data!

-- Drop existing tables if they exist (in correct order to avoid foreign key issues)
DROP TABLE IF EXISTS subscriptions CASCADE;
DROP TABLE IF EXISTS daily_stats CASCADE;
DROP TABLE IF EXISTS tasks CASCADE;
DROP TABLE IF EXISTS game_events CASCADE;
DROP TABLE IF EXISTS characters CASCADE;

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Characters table (complete version)
CREATE TABLE characters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL DEFAULT 'Player',
    level INTEGER DEFAULT 1 CHECK (level >= 1),
    experience INTEGER DEFAULT 0 CHECK (experience >= 0),
    health INTEGER DEFAULT 100 CHECK (health >= 0),
    attack INTEGER DEFAULT 10 CHECK (attack >= 0),
    defense INTEGER DEFAULT 5 CHECK (defense >= 0),
    avatar_url TEXT,
    battle_points INTEGER DEFAULT 0 CHECK (battle_points >= 0),
    stamina INTEGER DEFAULT 100 CHECK (stamina >= 0),
    max_stamina INTEGER DEFAULT 100 CHECK (max_stamina >= 0),
    crystal_inventory JSONB DEFAULT '{}',
    equipped_items JSONB DEFAULT '{}',
    consecutive_days INTEGER DEFAULT 0 CHECK (consecutive_days >= 0),
    last_activity_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    rank VARCHAR(20) DEFAULT 'novice',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tasks table
CREATE TABLE tasks (
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

-- Daily stats table
CREATE TABLE daily_stats (
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
CREATE TABLE game_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    event_type VARCHAR(50) NOT NULL CHECK (event_type IN ('raid', 'community_challenge', 'seasonal', 'guild_quest', 'special', 'weekly')),
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

-- Subscriptions table
CREATE TABLE subscriptions (
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

-- Basic indexes
CREATE INDEX idx_tasks_character_id ON tasks(character_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_characters_level ON characters(level);
CREATE INDEX idx_daily_stats_character_date ON daily_stats(character_id, date);
CREATE INDEX idx_subscriptions_character_id ON subscriptions(character_id);
CREATE INDEX idx_game_events_active_dates ON game_events(is_active, start_date, end_date);

-- Essential function for mentor stats
CREATE OR REPLACE FUNCTION get_mentor_stats(mentor_id_param UUID DEFAULT NULL)
RETURNS TABLE(
    total_mentees INTEGER,
    active_mentees INTEGER,
    completed_mentorships INTEGER,
    total_rewards_earned INTEGER
) AS $$
BEGIN
    -- Return dummy data for now since we don't have mentor tables yet
    RETURN QUERY
    SELECT 
        0 as total_mentees,
        0 as active_mentees,
        0 as completed_mentorships,
        0 as total_rewards_earned;
END;
$$ LANGUAGE plpgsql;

-- Insert sample data for testing
INSERT INTO characters (id, name, level, experience, battle_points, consecutive_days) 
VALUES ('550e8400-e29b-41d4-a716-446655440000', 'Test Player', 5, 250, 150, 7);

INSERT INTO daily_stats (character_id, date, habits_completed, battle_points_earned, experience_gained)
VALUES ('550e8400-e29b-41d4-a716-446655440000', CURRENT_DATE, 3, 30, 50);

INSERT INTO game_events (title, description, event_type, start_date, end_date, is_active)
VALUES ('Weekly Challenge', 'Complete 5 tasks this week', 'weekly', NOW(), NOW() + interval '7 days', true);

INSERT INTO subscriptions (character_id, subscription_type, price_jpy, start_date, end_date, status)
VALUES ('550e8400-e29b-41d4-a716-446655440000', 'basic_premium', 500, NOW(), NOW() + interval '30 days', 'active');
