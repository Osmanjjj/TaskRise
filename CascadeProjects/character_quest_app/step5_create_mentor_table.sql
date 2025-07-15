-- ステップ5: mentor_relationshipsテーブルが存在しない場合は作成
CREATE TABLE IF NOT EXISTS mentor_relationships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mentor_id UUID REFERENCES characters(id) ON DELETE CASCADE,
    mentee_id UUID REFERENCES characters(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(mentor_id, mentee_id)
);
