-- Step 2: Add foreign key constraints and indexes  
-- Run this AFTER step 1 is completed successfully

-- Add foreign key constraints
ALTER TABLE characters 
    ADD CONSTRAINT fk_characters_guild FOREIGN KEY (guild_id) REFERENCES guilds(id),
    ADD CONSTRAINT fk_characters_mentor FOREIGN KEY (mentor_id) REFERENCES characters(id);

ALTER TABLE guilds
    ADD CONSTRAINT fk_guilds_leader FOREIGN KEY (leader_id) REFERENCES characters(id);

ALTER TABLE tasks
    ADD CONSTRAINT fk_tasks_character FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE;

ALTER TABLE subscriptions
    ADD CONSTRAINT fk_subscriptions_character FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE;

ALTER TABLE mentor_relationships
    ADD CONSTRAINT fk_mentor_relationships_mentor FOREIGN KEY (mentor_id) REFERENCES characters(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_mentor_relationships_mentee FOREIGN KEY (mentee_id) REFERENCES characters(id) ON DELETE CASCADE,
    ADD CONSTRAINT uq_mentor_mentee UNIQUE(mentor_id, mentee_id);

ALTER TABLE habit_completions
    ADD CONSTRAINT fk_habit_completions_character FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_habit_completions_task FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE;

ALTER TABLE daily_stats
    ADD CONSTRAINT fk_daily_stats_character FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE,
    ADD CONSTRAINT uq_daily_stats_character_date UNIQUE(character_id, date);

ALTER TABLE event_participations
    ADD CONSTRAINT fk_event_participations_event FOREIGN KEY (event_id) REFERENCES game_events(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_event_participations_character FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE,
    ADD CONSTRAINT uq_event_participations UNIQUE(event_id, character_id);

ALTER TABLE raid_participations
    ADD CONSTRAINT fk_raid_participations_boss FOREIGN KEY (raid_boss_id) REFERENCES raid_bosses(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_raid_participations_character FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE,
    ADD CONSTRAINT uq_raid_participations UNIQUE(raid_boss_id, character_id);

ALTER TABLE guild_memberships
    ADD CONSTRAINT fk_guild_memberships_guild FOREIGN KEY (guild_id) REFERENCES guilds(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_guild_memberships_character FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE,
    ADD CONSTRAINT uq_guild_memberships UNIQUE(guild_id, character_id);

ALTER TABLE guild_quests
    ADD CONSTRAINT fk_guild_quests_guild FOREIGN KEY (guild_id) REFERENCES guilds(id) ON DELETE CASCADE,
    ADD CONSTRAINT fk_guild_quests_creator FOREIGN KEY (created_by) REFERENCES characters(id);

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
