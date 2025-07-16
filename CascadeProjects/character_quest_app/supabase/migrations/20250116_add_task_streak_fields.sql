-- Add streak tracking fields to tasks table
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS is_habit BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS streak_count INTEGER DEFAULT 0 CHECK (streak_count >= 0),
ADD COLUMN IF NOT EXISTS last_completed_date DATE,
ADD COLUMN IF NOT EXISTS streak_bonus_multiplier DECIMAL(3,2) DEFAULT 1.0 CHECK (streak_bonus_multiplier >= 1.0),
ADD COLUMN IF NOT EXISTS max_streak INTEGER DEFAULT 0 CHECK (max_streak >= 0),
ADD COLUMN IF NOT EXISTS completed_at TIMESTAMP WITH TIME ZONE;

-- Add index for habit tasks
CREATE INDEX IF NOT EXISTS idx_tasks_is_habit ON tasks(is_habit);
CREATE INDEX IF NOT EXISTS idx_tasks_last_completed ON tasks(last_completed_date);

-- Create function to calculate streak bonus multiplier
CREATE OR REPLACE FUNCTION calculate_streak_multiplier(streak_days INTEGER)
RETURNS DECIMAL(3,2) AS $$
BEGIN
    -- Base multiplier is 1.0
    -- Every 3 days: +0.1x (max 2.0x at 30 days)
    -- Every 7 days: additional +0.1x
    -- Every 30 days: additional +0.2x
    
    IF streak_days <= 0 THEN
        RETURN 1.0;
    END IF;
    
    DECLARE
        base_multiplier DECIMAL(3,2) := 1.0;
        three_day_bonus DECIMAL(3,2) := (streak_days / 3) * 0.1;
        weekly_bonus DECIMAL(3,2) := (streak_days / 7) * 0.1;
        monthly_bonus DECIMAL(3,2) := (streak_days / 30) * 0.2;
        total_multiplier DECIMAL(3,2);
    BEGIN
        total_multiplier := base_multiplier + three_day_bonus + weekly_bonus + monthly_bonus;
        
        -- Cap at 2.0x
        IF total_multiplier > 2.0 THEN
            RETURN 2.0;
        END IF;
        
        RETURN total_multiplier;
    END;
END;
$$ LANGUAGE plpgsql;

-- Create function to update streak when task is completed
CREATE OR REPLACE FUNCTION update_task_streak()
RETURNS TRIGGER AS $$
BEGIN
    -- Only process if task is marked as completed and is a habit
    IF NEW.status = 'completed' AND NEW.is_habit = true THEN
        -- Check if this is consecutive (completed yesterday or first completion)
        IF OLD.last_completed_date IS NULL OR 
           OLD.last_completed_date = CURRENT_DATE - INTERVAL '1 day' THEN
            -- Increment streak
            NEW.streak_count := COALESCE(OLD.streak_count, 0) + 1;
            NEW.last_completed_date := CURRENT_DATE;
            
            -- Update max streak if needed
            IF NEW.streak_count > COALESCE(NEW.max_streak, 0) THEN
                NEW.max_streak := NEW.streak_count;
            END IF;
            
            -- Calculate bonus multiplier
            NEW.streak_bonus_multiplier := calculate_streak_multiplier(NEW.streak_count);
        ELSIF OLD.last_completed_date < CURRENT_DATE - INTERVAL '1 day' THEN
            -- Streak broken, reset to 1
            NEW.streak_count := 1;
            NEW.last_completed_date := CURRENT_DATE;
            NEW.streak_bonus_multiplier := 1.0;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for streak updates
DROP TRIGGER IF EXISTS update_task_streak_trigger ON tasks;
CREATE TRIGGER update_task_streak_trigger
    BEFORE UPDATE OF status ON tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_task_streak();

-- Add function to get actual experience with streak bonus
CREATE OR REPLACE FUNCTION get_task_experience_with_bonus(
    base_experience INTEGER,
    streak_multiplier DECIMAL(3,2)
)
RETURNS INTEGER AS $$
BEGIN
    RETURN ROUND(base_experience * streak_multiplier);
END;
$$ LANGUAGE plpgsql;