-- Extended Character Quest App Database Schema
-- This includes all features: auth, habits, battles, guilds, social, monetization

-- Clean install - Drop existing tables and recreate
-- WARNING: This will delete all existing data!

-- Drop existing tables in correct order
DROP TABLE IF EXISTS friend_requests CASCADE;
DROP TABLE IF EXISTS friendships CASCADE;
DROP TABLE IF EXISTS guild_members CASCADE;
DROP TABLE IF EXISTS guild_quests CASCADE;
DROP TABLE IF EXISTS guilds CASCADE;
DROP TABLE IF EXISTS gacha_pulls CASCADE;
DROP TABLE IF EXISTS character_inventory CASCADE;
DROP TABLE IF EXISTS raid_participations CASCADE;
DROP TABLE IF EXISTS raid_bosses CASCADE;
DROP TABLE IF EXISTS event_participations CASCADE;
DROP TABLE IF EXISTS game_events CASCADE;
DROP TABLE IF EXISTS habit_completions CASCADE;
DROP TABLE IF EXISTS habits CASCADE;
DROP TABLE IF EXISTS subscriptions CASCADE;
DROP TABLE IF EXISTS user_profiles CASCADE;
DROP TABLE IF EXISTS daily_stats CASCADE;
DROP TABLE IF EXISTS characters CASCADE;

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================
-- USER AUTHENTICATION & PROFILES
-- =====================================

-- User profiles (extends Supabase auth.users)
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username VARCHAR(20) UNIQUE NOT NULL,
    display_name VARCHAR(50),
    avatar_url TEXT,
    bio TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    -- Settings
    notification_enabled BOOLEAN DEFAULT true,
    private_profile BOOLEAN DEFAULT false,
    -- Stats
    total_habits_completed INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    total_crystals_earned INTEGER DEFAULT 0
);

-- Characters (linked to user profiles)
CREATE TABLE characters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    name VARCHAR(30) NOT NULL DEFAULT 'Player',
    character_type VARCHAR(20) DEFAULT 'starter_1',
    level INTEGER DEFAULT 1 CHECK (level >= 1 AND level <= 100),
    experience INTEGER DEFAULT 0 CHECK (experience >= 0),
    health INTEGER DEFAULT 100 CHECK (health >= 0 AND health <= 999999),
    attack INTEGER DEFAULT 10 CHECK (attack >= 0),
    defense INTEGER DEFAULT 5 CHECK (defense >= 0),
    battle_points INTEGER DEFAULT 0 CHECK (battle_points >= 0),
    stamina INTEGER DEFAULT 100 CHECK (stamina >= 0 AND stamina <= 200),
    max_stamina INTEGER DEFAULT 100 CHECK (max_stamina >= 100 AND max_stamina <= 200),
    -- Crystals
    blue_crystals INTEGER DEFAULT 0 CHECK (blue_crystals >= 0),
    green_crystals INTEGER DEFAULT 0 CHECK (green_crystals >= 0),
    gold_crystals INTEGER DEFAULT 0 CHECK (gold_crystals >= 0),
    rainbow_crystals INTEGER DEFAULT 0 CHECK (rainbow_crystals >= 0),
    -- Guild
    guild_id UUID,
    guild_joined_at TIMESTAMP WITH TIME ZONE,
    -- Mentorship
    mentor_id UUID,
    mentor_joined_at TIMESTAMP WITH TIME ZONE,
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_activity_date TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================
-- HABIT MANAGEMENT SYSTEM
-- =====================================

-- Habit categories
CREATE TYPE habit_category AS ENUM ('exercise', 'study', 'health', 'work', 'hobby', 'lifestyle');
CREATE TYPE habit_frequency AS ENUM ('daily', 'weekly', 'custom');
CREATE TYPE habit_difficulty AS ENUM ('easy', 'normal', 'hard');

-- Habits table
CREATE TABLE habits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    title VARCHAR(30) NOT NULL,
    description TEXT,
    category habit_category NOT NULL,
    difficulty habit_difficulty DEFAULT 'normal',
    frequency habit_frequency DEFAULT 'daily',
    -- For weekly: how many times per week
    weekly_target INTEGER CHECK (weekly_target >= 1 AND weekly_target <= 7),
    -- For custom: specific weekdays (0=Sunday, 6=Saturday)
    custom_weekdays INTEGER[] CHECK (array_length(custom_weekdays, 1) <= 7),
    -- Reminder settings
    reminder_enabled BOOLEAN DEFAULT false,
    reminder_time TIME,
    -- Rewards
    base_points INTEGER DEFAULT 10 CHECK (base_points > 0),
    crystal_reward INTEGER DEFAULT 1 CHECK (crystal_reward >= 0),
    -- Status
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Habit completions
CREATE TABLE habit_completions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    habit_id UUID NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    -- Rewards earned
    points_earned INTEGER DEFAULT 0,
    experience_earned INTEGER DEFAULT 0,
    crystals_earned INTEGER DEFAULT 0,
    -- Bonus multipliers
    streak_bonus DECIMAL(3,2) DEFAULT 1.0,
    time_bonus DECIMAL(3,2) DEFAULT 1.0,
    -- Note
    note TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Daily statistics
CREATE TABLE daily_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    habits_completed INTEGER DEFAULT 0,
    habits_total INTEGER DEFAULT 0,
    points_earned INTEGER DEFAULT 0,
    experience_gained INTEGER DEFAULT 0,
    crystals_earned INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    battle_points_earned INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, date)
);

-- =====================================
-- GAME FEATURES
-- =====================================

-- Game events (including raids)
CREATE TYPE event_type AS ENUM ('raid', 'tournament', 'seasonal', 'weekly', 'special');
CREATE TYPE event_status AS ENUM ('upcoming', 'active', 'completed', 'cancelled');

CREATE TABLE game_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(50) NOT NULL,
    description TEXT,
    event_type event_type NOT NULL,
    status event_status DEFAULT 'upcoming',
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    -- Raid specific
    boss_name VARCHAR(30),
    boss_health INTEGER DEFAULT 1000000,
    current_health INTEGER,
    max_participants INTEGER DEFAULT 100,
    current_participants INTEGER DEFAULT 0,
    -- Rewards
    participation_reward JSONB,
    damage_rewards JSONB,
    mvp_rewards JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Event participations
CREATE TABLE event_participations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES game_events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    character_id UUID NOT NULL REFERENCES characters(id) ON DELETE CASCADE,
    -- Participation data
    damage_dealt INTEGER DEFAULT 0,
    battle_points_used INTEGER DEFAULT 0,
    rank INTEGER,
    -- Rewards
    rewards_claimed BOOLEAN DEFAULT false,
    rewards_data JSONB,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_action_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(event_id, user_id)
);

-- Raid bosses (for detailed raid mechanics)
CREATE TABLE raid_bosses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES game_events(id) ON DELETE CASCADE,
    name VARCHAR(30) NOT NULL,
    max_health INTEGER NOT NULL,
    current_health INTEGER NOT NULL,
    defense INTEGER DEFAULT 0,
    special_abilities JSONB,
    weakness_types JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Raid participations (detailed raid actions)
CREATE TABLE raid_participations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    raid_boss_id UUID NOT NULL REFERENCES raid_bosses(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    character_id UUID NOT NULL REFERENCES characters(id) ON DELETE CASCADE,
    damage_dealt INTEGER DEFAULT 0,
    battle_points_spent INTEGER DEFAULT 0,
    attacks_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(raid_boss_id, user_id)
);

-- Character inventory (gacha items, equipment)
CREATE TYPE item_type AS ENUM ('character', 'equipment', 'consumable', 'crystal');
CREATE TYPE item_rarity AS ENUM ('N', 'R', 'SR', 'SSR');

CREATE TABLE character_inventory (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    item_type item_type NOT NULL,
    item_id VARCHAR(50) NOT NULL, -- Reference to item definition
    item_name VARCHAR(50) NOT NULL,
    rarity item_rarity NOT NULL,
    quantity INTEGER DEFAULT 1 CHECK (quantity > 0),
    is_equipped BOOLEAN DEFAULT false,
    obtained_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB -- Additional item properties
);

-- Gacha pulls history
CREATE TABLE gacha_pulls (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    pull_type VARCHAR(20) NOT NULL, -- 'single', '10pull'
    crystals_used INTEGER NOT NULL,
    crystal_type VARCHAR(20) NOT NULL, -- 'blue', 'green', 'gold', 'rainbow'
    items_obtained JSONB NOT NULL, -- Array of obtained items
    is_guaranteed BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================
-- GUILD SYSTEM
-- =====================================

CREATE TABLE guilds (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(30) UNIQUE NOT NULL,
    description TEXT,
    leader_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    max_members INTEGER DEFAULT 30,
    current_members INTEGER DEFAULT 1,
    -- Requirements
    min_level INTEGER DEFAULT 1,
    is_public BOOLEAN DEFAULT true,
    join_password VARCHAR(20),
    -- Guild stats
    total_points INTEGER DEFAULT 0,
    weekly_points INTEGER DEFAULT 0,
    guild_rank INTEGER DEFAULT 0,
    -- Settings
    chat_enabled BOOLEAN DEFAULT true,
    quest_enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Guild members
CREATE TYPE guild_role AS ENUM ('member', 'officer', 'leader');

CREATE TABLE guild_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    guild_id UUID NOT NULL REFERENCES guilds(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    role guild_role DEFAULT 'member',
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    -- Contribution stats
    weekly_contribution INTEGER DEFAULT 0,
    total_contribution INTEGER DEFAULT 0,
    last_active_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(guild_id, user_id)
);

-- Guild quests
CREATE TYPE quest_status AS ENUM ('active', 'completed', 'failed', 'expired');

CREATE TABLE guild_quests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    guild_id UUID NOT NULL REFERENCES guilds(id) ON DELETE CASCADE,
    title VARCHAR(50) NOT NULL,
    description TEXT,
    -- Quest requirements
    target_type VARCHAR(20) NOT NULL, -- 'habits_completed', 'total_points', etc.
    target_value INTEGER NOT NULL,
    current_progress INTEGER DEFAULT 0,
    -- Duration
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status quest_status DEFAULT 'active',
    -- Rewards
    rewards JSONB,
    rewards_distributed BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================
-- SOCIAL FEATURES
-- =====================================

-- Friendships
CREATE TABLE friendships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user1_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    user2_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    -- Ensure unique friendship regardless of order
    CONSTRAINT unique_friendship UNIQUE (LEAST(user1_id, user2_id), GREATEST(user1_id, user2_id))
);

-- Friend requests
CREATE TYPE request_status AS ENUM ('pending', 'accepted', 'declined', 'cancelled');

CREATE TABLE friend_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    status request_status DEFAULT 'pending',
    message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    responded_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(sender_id, receiver_id)
);

-- =====================================
-- MONETIZATION
-- =====================================

-- Subscription types
CREATE TYPE subscription_type AS ENUM ('basic_premium', 'guild_premium', 'battle_pass');
CREATE TYPE subscription_status AS ENUM ('active', 'expired', 'cancelled', 'pending');

CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    subscription_type subscription_type NOT NULL,
    status subscription_status DEFAULT 'pending',
    -- Pricing
    monthly_price INTEGER NOT NULL, -- in cents
    duration_months INTEGER DEFAULT 1,
    -- Dates
    start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    auto_renew BOOLEAN DEFAULT true,
    -- Payment
    payment_method VARCHAR(50),
    last_payment_at TIMESTAMP WITH TIME ZONE,
    next_payment_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================
-- INDEXES FOR PERFORMANCE
-- =====================================

-- User profiles
CREATE INDEX idx_user_profiles_username ON user_profiles(username);
CREATE INDEX idx_user_profiles_created_at ON user_profiles(created_at);

-- Characters
CREATE INDEX idx_characters_user_id ON characters(user_id);
CREATE INDEX idx_characters_guild_id ON characters(guild_id);
CREATE INDEX idx_characters_level ON characters(level);
CREATE INDEX idx_characters_last_activity ON characters(last_activity_date);

-- Habits
CREATE INDEX idx_habits_user_id ON habits(user_id);
CREATE INDEX idx_habits_category ON habits(category);
CREATE INDEX idx_habits_active ON habits(is_active);
CREATE INDEX idx_habits_created_at ON habits(created_at);

-- Habit completions
CREATE INDEX idx_habit_completions_habit_id ON habit_completions(habit_id);
CREATE INDEX idx_habit_completions_user_id ON habit_completions(user_id);
CREATE INDEX idx_habit_completions_date ON habit_completions(completed_at);

-- Daily stats
CREATE INDEX idx_daily_stats_user_date ON daily_stats(user_id, date);
CREATE INDEX idx_daily_stats_date ON daily_stats(date);

-- Game events
CREATE INDEX idx_game_events_type ON game_events(event_type);
CREATE INDEX idx_game_events_status ON game_events(status);
CREATE INDEX idx_game_events_start_time ON game_events(start_time);

-- Event participations
CREATE INDEX idx_event_participations_event_id ON event_participations(event_id);
CREATE INDEX idx_event_participations_user_id ON event_participations(user_id);

-- Guild members
CREATE INDEX idx_guild_members_guild_id ON guild_members(guild_id);
CREATE INDEX idx_guild_members_user_id ON guild_members(user_id);

-- Friendships
CREATE INDEX idx_friendships_user1 ON friendships(user1_id);
CREATE INDEX idx_friendships_user2 ON friendships(user2_id);

-- Subscriptions
CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);
CREATE INDEX idx_subscriptions_end_date ON subscriptions(end_date);

-- =====================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================

-- Enable RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE characters ENABLE ROW LEVEL SECURITY;
ALTER TABLE habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE habit_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- User profiles policies
CREATE POLICY "Users can view their own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update their own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Public profiles are viewable" ON user_profiles
    FOR SELECT USING (NOT private_profile);

-- Characters policies
CREATE POLICY "Users can manage their own characters" ON characters
    FOR ALL USING (user_id = auth.uid());

-- Habits policies
CREATE POLICY "Users can manage their own habits" ON habits
    FOR ALL USING (user_id = auth.uid());

-- Habit completions policies
CREATE POLICY "Users can manage their own completions" ON habit_completions
    FOR ALL USING (user_id = auth.uid());

-- Daily stats policies
CREATE POLICY "Users can view their own stats" ON daily_stats
    FOR SELECT USING (user_id = auth.uid());

-- Subscriptions policies
CREATE POLICY "Users can view their own subscriptions" ON subscriptions
    FOR SELECT USING (user_id = auth.uid());

-- =====================================
-- FUNCTIONS
-- =====================================

-- Function to update character level based on experience
CREATE OR REPLACE FUNCTION update_character_level()
RETURNS TRIGGER AS $$
BEGIN
    -- Simple level calculation: level = floor(experience / 100) + 1
    NEW.level = LEAST(FLOOR(NEW.experience / 100.0) + 1, 100);
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_character_level_trigger
    BEFORE UPDATE OF experience ON characters
    FOR EACH ROW
    EXECUTE FUNCTION update_character_level();

-- Function to calculate streak bonus
CREATE OR REPLACE FUNCTION calculate_streak_bonus(user_uuid UUID, habit_uuid UUID)
RETURNS DECIMAL AS $$
DECLARE
    consecutive_days INTEGER := 0;
    bonus_multiplier DECIMAL := 1.0;
BEGIN
    -- Calculate consecutive days for this habit
    SELECT COUNT(*) INTO consecutive_days
    FROM habit_completions hc
    WHERE hc.user_id = user_uuid 
    AND hc.habit_id = habit_uuid
    AND hc.completed_at >= CURRENT_DATE - INTERVAL '30 days'
    AND DATE(hc.completed_at) >= CURRENT_DATE - consecutive_days;
    
    -- Apply bonus based on streak
    IF consecutive_days >= 30 THEN
        bonus_multiplier := 2.0;
    ELSIF consecutive_days >= 14 THEN
        bonus_multiplier := 1.75;
    ELSIF consecutive_days >= 7 THEN
        bonus_multiplier := 1.5;
    ELSIF consecutive_days >= 3 THEN
        bonus_multiplier := 1.25;
    END IF;
    
    RETURN bonus_multiplier;
END;
$$ LANGUAGE plpgsql;

-- Function to get user stats
CREATE OR REPLACE FUNCTION get_user_stats(user_uuid UUID)
RETURNS TABLE(
    total_habits INTEGER,
    active_habits INTEGER,
    today_completed INTEGER,
    current_streak INTEGER,
    total_crystals INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*)::INTEGER FROM habits WHERE user_id = user_uuid),
        (SELECT COUNT(*)::INTEGER FROM habits WHERE user_id = user_uuid AND is_active = true),
        (SELECT COALESCE(habits_completed, 0)::INTEGER FROM daily_stats WHERE user_id = user_uuid AND date = CURRENT_DATE),
        (SELECT COALESCE(MAX(longest_streak), 0)::INTEGER FROM daily_stats WHERE user_id = user_uuid),
        (SELECT COALESCE(SUM(blue_crystals + green_crystals + gold_crystals + rainbow_crystals), 0)::INTEGER FROM characters WHERE user_id = user_uuid);
END;
$$ LANGUAGE plpgsql;

-- =====================================
-- SAMPLE DATA
-- =====================================

-- Insert sample user profile (will be created via auth signup)
-- This is just for reference - actual users will be created through authentication

-- Sample game events
INSERT INTO game_events (title, description, event_type, status, start_time, end_time, boss_name, boss_health, current_health) VALUES
('Daily Raid: Dragon King', 'Defeat the mighty Dragon King with your guild members!', 'raid', 'active', NOW(), NOW() + INTERVAL '2 hours', 'Dragon King', 1000000, 750000),
('Weekly Tournament', 'Compete with other players for exclusive rewards', 'tournament', 'upcoming', NOW() + INTERVAL '1 day', NOW() + INTERVAL '8 days', NULL, NULL, NULL),
('Spring Festival Event', 'Special seasonal event with unique rewards', 'seasonal', 'upcoming', NOW() + INTERVAL '7 days', NOW() + INTERVAL '21 days', NULL, NULL, NULL);
