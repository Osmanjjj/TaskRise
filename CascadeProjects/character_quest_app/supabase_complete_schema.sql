-- Complete Supabase schema for Character Quest App
-- WARNING: This will delete all existing data!

-- Drop existing tables if they exist (in correct order to avoid foreign key issues)
DROP TABLE IF EXISTS subscriptions CASCADE;
DROP TABLE IF EXISTS daily_stats CASCADE;
DROP TABLE IF EXISTS tasks CASCADE;
DROP TABLE IF EXISTS game_events CASCADE;
DROP TABLE IF EXISTS characters CASCADE;
DROP TABLE IF EXISTS user_profiles CASCADE;

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- User profiles table (for authentication)
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username VARCHAR(255) UNIQUE NOT NULL,
    display_name VARCHAR(255),
    avatar_url TEXT,
    bio TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notification_enabled BOOLEAN DEFAULT true,
    private_profile BOOLEAN DEFAULT false,
    total_habits_completed INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    total_crystals_earned INTEGER DEFAULT 0
);

-- Characters table (complete version)
CREATE TABLE characters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
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
    rank VARCHAR(20) DEFAULT 'beginner' CHECK (rank IN ('beginner', 'intermediate', 'advanced', 'epic', 'legendary')),
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
CREATE INDEX idx_characters_user_id ON characters(user_id);
CREATE INDEX idx_daily_stats_character_date ON daily_stats(character_id, date);
CREATE INDEX idx_subscriptions_character_id ON subscriptions(character_id);
CREATE INDEX idx_game_events_active_dates ON game_events(is_active, start_date, end_date);
CREATE INDEX idx_user_profiles_username ON user_profiles(username);

-- Row Level Security (RLS) policies
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE characters ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- User profiles policies
CREATE POLICY "Users can view their own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Characters policies
CREATE POLICY "Users can view their own characters" ON characters
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own characters" ON characters
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own characters" ON characters
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own characters" ON characters
    FOR DELETE USING (auth.uid() = user_id);

-- Tasks policies
CREATE POLICY "Users can view tasks of their characters" ON tasks
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM characters 
            WHERE characters.id = tasks.character_id 
            AND characters.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can manage tasks of their characters" ON tasks
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM characters 
            WHERE characters.id = tasks.character_id 
            AND characters.user_id = auth.uid()
        )
    );

-- Daily stats policies
CREATE POLICY "Users can view stats of their characters" ON daily_stats
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM characters 
            WHERE characters.id = daily_stats.character_id 
            AND characters.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can manage stats of their characters" ON daily_stats
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM characters 
            WHERE characters.id = daily_stats.character_id 
            AND characters.user_id = auth.uid()
        )
    );

-- Subscriptions policies
CREATE POLICY "Users can view subscriptions of their characters" ON subscriptions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM characters 
            WHERE characters.id = subscriptions.character_id 
            AND characters.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can manage subscriptions of their characters" ON subscriptions
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM characters 
            WHERE characters.id = subscriptions.character_id 
            AND characters.user_id = auth.uid()
        )
    );

-- Game events are public (read-only)
CREATE POLICY "Everyone can view active game events" ON game_events
    FOR SELECT USING (is_active = true);

-- Functions
CREATE OR REPLACE FUNCTION handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_profiles (id, username, display_name)
    VALUES (
        new.id,
        COALESCE(new.raw_user_meta_data->>'username', new.email),
        COALESCE(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1))
    );
    
    -- Create default character for new user
    INSERT INTO characters (user_id, name)
    VALUES (new.id, COALESCE(new.raw_user_meta_data->>'display_name', 'Player'));
    
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user signup
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Essential function for mentor stats (placeholder)
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

-- Function to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_characters_updated_at BEFORE UPDATE ON characters
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_game_events_updated_at BEFORE UPDATE ON game_events
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscriptions_updated_at BEFORE UPDATE ON subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();