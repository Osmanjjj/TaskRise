-- Step 1: Create basic tables without foreign key constraints
-- Run this first in Supabase console

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Characters table (without foreign keys)
CREATE TABLE IF NOT EXISTS characters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    level INTEGER DEFAULT 1 CHECK (level >= 1),
    experience INTEGER DEFAULT 0 CHECK (experience >= 0),
    health INTEGER DEFAULT 100 CHECK (health >= 0),
    attack INTEGER DEFAULT 10 CHECK (attack >= 0),
    defense INTEGER DEFAULT 5 CHECK (defense >= 0),
    avatar_url TEXT,
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

-- Guilds table (without foreign keys)
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

-- Tasks table
CREATE TABLE IF NOT EXISTS tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    difficulty VARCHAR(20) DEFAULT 'normal' CHECK (difficulty IN ('easy', 'normal', 'hard')),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed')),
    experience_reward INTEGER DEFAULT 10 CHECK (experience_reward >= 0),
    due_date TIMESTAMP WITH TIME ZONE,
    character_id UUID, -- Will add constraint in step 2
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Daily stats table
CREATE TABLE IF NOT EXISTS daily_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    character_id UUID, -- Will add constraint in step 2
    date DATE NOT NULL,
    habits_completed INTEGER DEFAULT 0 CHECK (habits_completed >= 0),
    battle_points_earned INTEGER DEFAULT 0 CHECK (battle_points_earned >= 0),
    stamina_generated INTEGER DEFAULT 0 CHECK (stamina_generated >= 0),
    experience_gained INTEGER DEFAULT 0 CHECK (experience_gained >= 0),
    crystals_earned INTEGER DEFAULT 0 CHECK (crystals_earned >= 0),
    longest_chain INTEGER DEFAULT 0 CHECK (longest_chain >= 0),
    raid_participated BOOLEAN DEFAULT false,
    guild_quest_participated BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
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

-- Other tables without foreign key constraints
CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    character_id UUID, -- Will add constraint in step 2
    subscription_type VARCHAR(50) NOT NULL CHECK (subscription_type IN ('basic_premium', 'guild', 'battle_pass', 'enterprise')),
    price_jpy INTEGER NOT NULL CHECK (price_jpy >= 0),
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    auto_renew BOOLEAN DEFAULT true,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'expired', 'pending')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS mentor_relationships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    mentor_id UUID, -- Will add constraint in step 2
    mentee_id UUID, -- Will add constraint in step 2
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'completed', 'cancelled')),
    mentor_rewards_earned INTEGER DEFAULT 0 CHECK (mentor_rewards_earned >= 0),
    mentee_progress_bonus NUMERIC(3,2) DEFAULT 1.00 CHECK (mentee_progress_bonus >= 1.00),
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ended_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS habit_completions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    character_id UUID, -- Will add constraint in step 2
    task_id UUID, -- Will add constraint in step 2
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

CREATE TABLE IF NOT EXISTS event_participations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID, -- Will add constraint in step 2
    character_id UUID, -- Will add constraint in step 2
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    progress INTEGER DEFAULT 0 CHECK (progress >= 0),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'completed', 'abandoned')),
    rewards_claimed BOOLEAN DEFAULT false,
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

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

CREATE TABLE IF NOT EXISTS raid_participations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    raid_boss_id UUID, -- Will add constraint in step 2
    character_id UUID, -- Will add constraint in step 2
    damage_dealt INTEGER DEFAULT 0 CHECK (damage_dealt >= 0),
    attacks_made INTEGER DEFAULT 0 CHECK (attacks_made >= 0),
    rewards_earned JSONB DEFAULT '[]',
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_attack_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS guild_memberships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    guild_id UUID, -- Will add constraint in step 2
    character_id UUID, -- Will add constraint in step 2
    role VARCHAR(20) DEFAULT 'member' CHECK (role IN ('leader', 'officer', 'member')),
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    contribution_points INTEGER DEFAULT 0 CHECK (contribution_points >= 0),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS guild_quests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    guild_id UUID, -- Will add constraint in step 2
    title VARCHAR(255) NOT NULL,
    description TEXT,
    target_progress INTEGER NOT NULL CHECK (target_progress > 0),
    current_progress INTEGER DEFAULT 0 CHECK (current_progress >= 0),
    rewards JSONB DEFAULT '[]',
    start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    end_date TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'completed', 'failed', 'cancelled')),
    created_by UUID, -- Will add constraint in step 2
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
