-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Item rarity enum
CREATE TYPE item_rarity AS ENUM ('common', 'rare', 'epic', 'legendary');

-- Item type enum
CREATE TYPE item_type AS ENUM ('avatar', 'decoration', 'skin', 'effect');

-- Master items table (defines all possible items)
CREATE TABLE IF NOT EXISTS items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    item_type item_type NOT NULL,
    rarity item_rarity NOT NULL,
    icon VARCHAR(50), -- Material icon name
    color VARCHAR(20), -- Hex color code
    effects JSONB, -- Any special effects or bonuses
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Character inventory (items owned by characters)
CREATE TABLE IF NOT EXISTS character_inventory (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    character_id UUID REFERENCES characters(id) ON DELETE CASCADE,
    item_id UUID REFERENCES items(id) ON DELETE CASCADE,
    quantity INTEGER DEFAULT 1 CHECK (quantity > 0),
    obtained_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_new BOOLEAN DEFAULT true,
    is_equipped BOOLEAN DEFAULT false,
    UNIQUE(character_id, item_id)
);

-- Gacha pools (different gacha types)
CREATE TABLE IF NOT EXISTS gacha_pools (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    crystal_type crystal_type NOT NULL,
    crystal_cost INTEGER NOT NULL CHECK (crystal_cost > 0),
    pull_count INTEGER DEFAULT 1 CHECK (pull_count > 0),
    guaranteed_rarity item_rarity, -- Guaranteed minimum rarity
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Gacha pool items (items available in each pool)
CREATE TABLE IF NOT EXISTS gacha_pool_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pool_id UUID REFERENCES gacha_pools(id) ON DELETE CASCADE,
    item_id UUID REFERENCES items(id) ON DELETE CASCADE,
    weight INTEGER DEFAULT 100 CHECK (weight > 0), -- Higher weight = higher chance
    UNIQUE(pool_id, item_id)
);

-- Gacha history (record of all pulls)
CREATE TABLE IF NOT EXISTS gacha_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    character_id UUID REFERENCES characters(id) ON DELETE CASCADE,
    pool_id UUID REFERENCES gacha_pools(id),
    item_id UUID REFERENCES items(id),
    pulled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_character_inventory_character_id ON character_inventory(character_id);
CREATE INDEX idx_character_inventory_item_id ON character_inventory(item_id);
CREATE INDEX idx_gacha_history_character_id ON gacha_history(character_id);
CREATE INDEX idx_gacha_history_pulled_at ON gacha_history(pulled_at);
CREATE INDEX idx_gacha_pool_items_pool_id ON gacha_pool_items(pool_id);

-- Function to perform gacha
CREATE OR REPLACE FUNCTION perform_gacha(
    p_character_id UUID,
    p_pool_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_pool gacha_pools%ROWTYPE;
    v_crystal_type crystal_type;
    v_crystal_cost INTEGER;
    v_pull_count INTEGER;
    v_guaranteed_rarity item_rarity;
    v_current_crystals INTEGER;
    v_results JSONB[] := '{}';
    v_pulled_items UUID[] := '{}';
    v_spend_result JSONB;
    i INTEGER;
BEGIN
    -- Get pool information
    SELECT * INTO v_pool FROM gacha_pools WHERE id = p_pool_id AND is_active = true;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Invalid or inactive gacha pool');
    END IF;
    
    v_crystal_type := v_pool.crystal_type;
    v_crystal_cost := v_pool.crystal_cost;
    v_pull_count := v_pool.pull_count;
    v_guaranteed_rarity := v_pool.guaranteed_rarity;
    
    -- Check crystal balance
    SELECT 
        CASE v_crystal_type
            WHEN 'blue' THEN blue_crystals
            WHEN 'green' THEN green_crystals
            WHEN 'gold' THEN gold_crystals
            WHEN 'rainbow' THEN rainbow_crystals
        END
    INTO v_current_crystals
    FROM crystal_inventory
    WHERE character_id = p_character_id;
    
    IF v_current_crystals IS NULL OR v_current_crystals < v_crystal_cost THEN
        RETURN jsonb_build_object('success', false, 'error', 'Insufficient crystals');
    END IF;
    
    -- Deduct crystals
    UPDATE crystal_inventory
    SET 
        blue_crystals = CASE WHEN v_crystal_type = 'blue' THEN blue_crystals - v_crystal_cost ELSE blue_crystals END,
        green_crystals = CASE WHEN v_crystal_type = 'green' THEN green_crystals - v_crystal_cost ELSE green_crystals END,
        gold_crystals = CASE WHEN v_crystal_type = 'gold' THEN gold_crystals - v_crystal_cost ELSE gold_crystals END,
        rainbow_crystals = CASE WHEN v_crystal_type = 'rainbow' THEN rainbow_crystals - v_crystal_cost ELSE rainbow_crystals END,
        updated_at = NOW()
    WHERE character_id = p_character_id;
    
    -- Log crystal transaction
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
        v_crystal_type,
        -v_crystal_cost,
        'spent',
        'gacha',
        p_pool_id,
        'ガチャ: ' || v_pool.name
    );
    
    -- Perform pulls
    FOR i IN 1..v_pull_count LOOP
        DECLARE
            v_item_id UUID;
            v_item items%ROWTYPE;
            v_is_new BOOLEAN;
            v_is_guaranteed BOOLEAN := false;
        BEGIN
            -- Check if this pull should be guaranteed rarity
            IF v_guaranteed_rarity IS NOT NULL AND i = v_pull_count THEN
                v_is_guaranteed := true;
            END IF;
            
            -- Select random item based on weights
            IF v_is_guaranteed THEN
                -- Select from items of guaranteed rarity or higher
                SELECT i.id INTO v_item_id
                FROM items i
                JOIN gacha_pool_items gpi ON i.id = gpi.item_id
                WHERE gpi.pool_id = p_pool_id
                AND i.rarity >= v_guaranteed_rarity
                ORDER BY RANDOM() * gpi.weight DESC
                LIMIT 1;
            ELSE
                -- Normal weighted random selection
                SELECT i.id INTO v_item_id
                FROM items i
                JOIN gacha_pool_items gpi ON i.id = gpi.item_id
                WHERE gpi.pool_id = p_pool_id
                ORDER BY RANDOM() * gpi.weight DESC
                LIMIT 1;
            END IF;
            
            -- Get item details
            SELECT * INTO v_item FROM items WHERE id = v_item_id;
            
            -- Add to inventory or increase quantity
            INSERT INTO character_inventory (character_id, item_id, quantity, is_new)
            VALUES (p_character_id, v_item_id, 1, true)
            ON CONFLICT (character_id, item_id) DO UPDATE
            SET quantity = character_inventory.quantity + 1,
                is_new = true;
            
            -- Check if item is new
            SELECT is_new INTO v_is_new
            FROM character_inventory
            WHERE character_id = p_character_id AND item_id = v_item_id;
            
            -- Record in history
            INSERT INTO gacha_history (character_id, pool_id, item_id)
            VALUES (p_character_id, p_pool_id, v_item_id);
            
            -- Add to results
            v_results := array_append(v_results, jsonb_build_object(
                'item_id', v_item.id,
                'name', v_item.name,
                'description', v_item.description,
                'item_type', v_item.item_type,
                'rarity', v_item.rarity,
                'icon', v_item.icon,
                'color', v_item.color,
                'is_new', v_is_new
            ));
            
            v_pulled_items := array_append(v_pulled_items, v_item_id);
        END;
    END LOOP;
    
    RETURN jsonb_build_object(
        'success', true,
        'items', v_results,
        'crystal_spent', v_crystal_cost,
        'crystal_type', v_crystal_type
    );
END;
$$ LANGUAGE plpgsql;

-- Function to get character collection
CREATE OR REPLACE FUNCTION get_character_collection(
    p_character_id UUID,
    p_item_type item_type DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_owned_items JSONB;
    v_all_items JSONB;
BEGIN
    -- Get owned items
    SELECT jsonb_agg(
        jsonb_build_object(
            'item_id', i.id,
            'name', i.name,
            'description', i.description,
            'item_type', i.item_type,
            'rarity', i.rarity,
            'icon', i.icon,
            'color', i.color,
            'quantity', ci.quantity,
            'is_new', ci.is_new,
            'is_equipped', ci.is_equipped,
            'obtained_at', ci.obtained_at
        )
    )
    INTO v_owned_items
    FROM character_inventory ci
    JOIN items i ON ci.item_id = i.id
    WHERE ci.character_id = p_character_id
    AND (p_item_type IS NULL OR i.item_type = p_item_type);
    
    -- Get all items (for showing locked items)
    SELECT jsonb_agg(
        jsonb_build_object(
            'item_id', i.id,
            'name', i.name,
            'description', i.description,
            'item_type', i.item_type,
            'rarity', i.rarity,
            'icon', i.icon,
            'color', i.color,
            'owned', EXISTS (
                SELECT 1 FROM character_inventory ci 
                WHERE ci.character_id = p_character_id 
                AND ci.item_id = i.id
            )
        )
    )
    INTO v_all_items
    FROM items i
    WHERE p_item_type IS NULL OR i.item_type = p_item_type;
    
    RETURN jsonb_build_object(
        'owned_items', COALESCE(v_owned_items, '[]'::jsonb),
        'all_items', COALESCE(v_all_items, '[]'::jsonb)
    );
END;
$$ LANGUAGE plpgsql;

-- Insert default items
INSERT INTO items (name, description, item_type, rarity, icon, color) VALUES
-- Common items
('木の剣', 'シンプルな木製の剣', 'decoration', 'common', 'sports_martial_arts', '#8B4513'),
('布の帽子', '基本的な布製の帽子', 'avatar', 'common', 'person', '#A0522D'),
('革のブーツ', '丈夫な革製のブーツ', 'avatar', 'common', 'directions_walk', '#654321'),
('石のリング', 'シンプルな石のリング', 'decoration', 'common', 'radio_button_unchecked', '#808080'),

-- Rare items
('鋼の剣', '鋭い刃を持つ鋼鉄の剣', 'decoration', 'rare', 'flash_on', '#4682B4'),
('魔法の杖', '魔力を帯びた神秘的な杖', 'decoration', 'rare', 'auto_fix_high', '#9370DB'),
('羽根の帽子', '軽くて優雅な羽根付き帽子', 'avatar', 'rare', 'flight', '#32CD32'),
('銀のネックレス', '輝く銀製のネックレス', 'decoration', 'rare', 'stars', '#C0C0C0'),

-- Epic items
('炎の剣', '燃え盛る炎を纏った剣', 'decoration', 'epic', 'whatshot', '#FF4500'),
('氷の盾', '凍てつく冷気を放つ盾', 'decoration', 'epic', 'ac_unit', '#00CED1'),
('ドラゴンアーマー', '竜の鱗で作られた鎧', 'avatar', 'epic', 'shield', '#8B008B'),
('稲妻のブーツ', '電撃を纏った高速ブーツ', 'avatar', 'epic', 'bolt', '#FFD700'),

-- Legendary items
('伝説の剣エクスカリバー', '選ばれし者のみが扱える聖剣', 'decoration', 'legendary', 'star', '#FFD700'),
('不死鳥の羽根', '永遠の命を象徴する羽根', 'decoration', 'legendary', 'local_fire_department', '#FF6347'),
('時空のマント', '時間と空間を操る神秘のマント', 'avatar', 'legendary', 'schedule', '#4B0082'),
('賢者の王冠', '無限の知恵を授ける王冠', 'avatar', 'legendary', 'psychology', '#FFD700');

-- Insert default gacha pools
INSERT INTO gacha_pools (name, description, crystal_type, crystal_cost, pull_count, guaranteed_rarity) VALUES
('単発ガチャ', 'シンプルな装飾品やアバターパーツが手に入る', 'blue', 1, 1, NULL),
('5連ガチャ', 'レア装飾品やスキンが手に入りやすい', 'green', 1, 5, NULL),
('20連ガチャ', 'エピック装飾品が1つ以上確定！', 'gold', 1, 20, 'epic'),
('レインボーガチャ', 'レジェンダリーアイテムが確定！', 'rainbow', 1, 1, 'legendary');

-- Add all items to pools with appropriate weights
-- Single pull pool (all items, common weighted higher)
INSERT INTO gacha_pool_items (pool_id, item_id, weight)
SELECT 
    (SELECT id FROM gacha_pools WHERE name = '単発ガチャ'),
    i.id,
    CASE i.rarity
        WHEN 'common' THEN 700
        WHEN 'rare' THEN 250
        WHEN 'epic' THEN 45
        WHEN 'legendary' THEN 5
    END
FROM items i;

-- 5-pull pool (same as single)
INSERT INTO gacha_pool_items (pool_id, item_id, weight)
SELECT 
    (SELECT id FROM gacha_pools WHERE name = '5連ガチャ'),
    i.id,
    CASE i.rarity
        WHEN 'common' THEN 700
        WHEN 'rare' THEN 250
        WHEN 'epic' THEN 45
        WHEN 'legendary' THEN 5
    END
FROM items i;

-- 20-pull pool (same weights, but guaranteed epic)
INSERT INTO gacha_pool_items (pool_id, item_id, weight)
SELECT 
    (SELECT id FROM gacha_pools WHERE name = '20連ガチャ'),
    i.id,
    CASE i.rarity
        WHEN 'common' THEN 700
        WHEN 'rare' THEN 250
        WHEN 'epic' THEN 45
        WHEN 'legendary' THEN 5
    END
FROM items i;

-- Rainbow pool (only legendary items)
INSERT INTO gacha_pool_items (pool_id, item_id, weight)
SELECT 
    (SELECT id FROM gacha_pools WHERE name = 'レインボーガチャ'),
    i.id,
    100
FROM items i
WHERE i.rarity = 'legendary';