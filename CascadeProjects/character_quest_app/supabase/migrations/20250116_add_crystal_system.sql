-- Crystal types enum
CREATE TYPE crystal_type AS ENUM ('blue', 'green', 'gold', 'rainbow');

-- Crystal inventory table
CREATE TABLE IF NOT EXISTS crystal_inventory (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    character_id UUID REFERENCES characters(id) ON DELETE CASCADE,
    blue_crystals INTEGER DEFAULT 0 CHECK (blue_crystals >= 0),
    green_crystals INTEGER DEFAULT 0 CHECK (green_crystals >= 0),
    gold_crystals INTEGER DEFAULT 0 CHECK (gold_crystals >= 0),
    rainbow_crystals INTEGER DEFAULT 0 CHECK (rainbow_crystals >= 0),
    storage_limit INTEGER DEFAULT 100 CHECK (storage_limit > 0),
    conversion_rate_bonus DECIMAL(3,2) DEFAULT 1.0 CHECK (conversion_rate_bonus >= 1.0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(character_id)
);

-- Crystal transactions log
CREATE TABLE IF NOT EXISTS crystal_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    character_id UUID REFERENCES characters(id) ON DELETE CASCADE,
    crystal_type crystal_type NOT NULL,
    amount INTEGER NOT NULL,
    transaction_type VARCHAR(50) NOT NULL CHECK (transaction_type IN ('earned', 'spent', 'converted', 'bonus')),
    source VARCHAR(100) NOT NULL, -- 'task_completion', 'streak_7', 'streak_30', 'help_friend', etc.
    source_id UUID, -- Reference to task_id, friend_id, etc.
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_crystal_inventory_character_id ON crystal_inventory(character_id);
CREATE INDEX idx_crystal_transactions_character_id ON crystal_transactions(character_id);
CREATE INDEX idx_crystal_transactions_created_at ON crystal_transactions(created_at);

-- Function to award crystals
CREATE OR REPLACE FUNCTION award_crystals(
    p_character_id UUID,
    p_crystal_type crystal_type,
    p_amount INTEGER,
    p_source VARCHAR(100),
    p_source_id UUID DEFAULT NULL,
    p_description TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_inventory_id UUID;
    v_current_amount INTEGER;
    v_storage_limit INTEGER;
    v_new_total INTEGER;
    v_result JSONB;
BEGIN
    -- Ensure crystal inventory exists
    INSERT INTO crystal_inventory (character_id)
    VALUES (p_character_id)
    ON CONFLICT (character_id) DO NOTHING;
    
    -- Get current inventory
    SELECT id, storage_limit,
        CASE p_crystal_type
            WHEN 'blue' THEN blue_crystals
            WHEN 'green' THEN green_crystals
            WHEN 'gold' THEN gold_crystals
            WHEN 'rainbow' THEN rainbow_crystals
        END
    INTO v_inventory_id, v_storage_limit, v_current_amount
    FROM crystal_inventory
    WHERE character_id = p_character_id;
    
    -- Calculate new total
    v_new_total := LEAST(v_current_amount + p_amount, v_storage_limit);
    
    -- Update inventory
    UPDATE crystal_inventory
    SET 
        blue_crystals = CASE WHEN p_crystal_type = 'blue' THEN v_new_total ELSE blue_crystals END,
        green_crystals = CASE WHEN p_crystal_type = 'green' THEN v_new_total ELSE green_crystals END,
        gold_crystals = CASE WHEN p_crystal_type = 'gold' THEN v_new_total ELSE gold_crystals END,
        rainbow_crystals = CASE WHEN p_crystal_type = 'rainbow' THEN v_new_total ELSE rainbow_crystals END,
        updated_at = NOW()
    WHERE id = v_inventory_id;
    
    -- Log transaction
    INSERT INTO crystal_transactions (
        character_id,
        crystal_type,
        amount,
        transaction_type,
        source,
        source_id,
        description
    ) VALUES (
        p_character_id,
        p_crystal_type,
        v_new_total - v_current_amount,
        'earned',
        p_source,
        p_source_id,
        p_description
    );
    
    -- Return result
    v_result := jsonb_build_object(
        'success', true,
        'crystals_earned', v_new_total - v_current_amount,
        'crystal_type', p_crystal_type,
        'total_crystals', v_new_total,
        'hit_limit', v_new_total < v_current_amount + p_amount
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- Function to check and award streak milestone crystals
CREATE OR REPLACE FUNCTION check_streak_milestone_crystals(
    p_character_id UUID,
    p_streak_count INTEGER,
    p_task_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
    v_crystals_awarded JSONB[] = '{}';
BEGIN
    -- 7-day streak milestone
    IF p_streak_count = 7 THEN
        v_crystals_awarded := array_append(
            v_crystals_awarded,
            award_crystals(p_character_id, 'green', 5, 'streak_7', p_task_id, '7日連続達成ボーナス')
        );
    END IF;
    
    -- 30-day streak milestone
    IF p_streak_count = 30 THEN
        v_crystals_awarded := array_append(
            v_crystals_awarded,
            award_crystals(p_character_id, 'gold', 20, 'streak_30', p_task_id, '30日連続達成ボーナス')
        );
    END IF;
    
    -- Every 7 days after 7 (14, 21, 28, etc.)
    IF p_streak_count > 7 AND p_streak_count % 7 = 0 THEN
        v_crystals_awarded := array_append(
            v_crystals_awarded,
            award_crystals(p_character_id, 'green', 3, 'streak_weekly', p_task_id, p_streak_count || '日連続達成')
        );
    END IF;
    
    v_result := jsonb_build_object(
        'milestone_reached', array_length(v_crystals_awarded, 1) > 0,
        'crystals_awarded', v_crystals_awarded
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- Update task completion to award crystals
CREATE OR REPLACE FUNCTION update_task_completion_with_crystals()
RETURNS TRIGGER AS $$
DECLARE
    v_character_id UUID;
    v_crystal_result JSONB;
    v_milestone_result JSONB;
BEGIN
    -- Only process completed tasks
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        -- Get character ID
        v_character_id := NEW.character_id;
        
        IF v_character_id IS NOT NULL THEN
            -- Award blue crystal for task completion
            v_crystal_result := award_crystals(
                v_character_id,
                'blue',
                1,
                'task_completion',
                NEW.id,
                'タスク完了: ' || NEW.title
            );
            
            -- Check streak milestones for habit tasks
            IF NEW.is_habit = true AND NEW.streak_count IS NOT NULL THEN
                v_milestone_result := check_streak_milestone_crystals(
                    v_character_id,
                    NEW.streak_count,
                    NEW.id
                );
            END IF;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for crystal awards
DROP TRIGGER IF EXISTS task_completion_crystal_trigger ON tasks;
CREATE TRIGGER task_completion_crystal_trigger
    AFTER UPDATE OF status ON tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_task_completion_with_crystals();

-- Initialize crystal inventory for existing characters
INSERT INTO crystal_inventory (character_id)
SELECT id FROM characters
ON CONFLICT (character_id) DO NOTHING;