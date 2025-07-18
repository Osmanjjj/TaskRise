-- Add image_url column to items table
ALTER TABLE items 
ADD COLUMN IF NOT EXISTS image_url VARCHAR(255);

-- Update existing items with image URLs
UPDATE items SET image_url = CASE name
    -- Common items
    WHEN '木の剣' THEN 'assets/images/items/wooden_sword.png'
    WHEN '布の帽子' THEN 'assets/images/items/cloth_hat.png'
    WHEN '革のブーツ' THEN 'assets/images/items/leather_boots.png'
    WHEN '石のリング' THEN 'assets/images/items/stone_ring.png'
    
    -- Rare items
    WHEN '鋼の剣' THEN 'assets/images/items/steel_sword.png'
    WHEN '魔法の杖' THEN 'assets/images/items/magic_staff.png'
    WHEN '羽根の帽子' THEN 'assets/images/items/feather_hat.png'
    WHEN '銀のネックレス' THEN 'assets/images/items/silver_necklace.png'
    
    -- Epic items
    WHEN '炎の剣' THEN 'assets/images/items/fire_sword.png'
    WHEN '氷の盾' THEN 'assets/images/items/ice_shield.png'
    WHEN 'ドラゴンアーマー' THEN 'assets/images/items/dragon_armor.png'
    WHEN '稲妻のブーツ' THEN 'assets/images/items/lightning_boots.png'
    
    -- Legendary items
    WHEN '伝説の剣エクスカリバー' THEN 'assets/images/items/excalibur.png'
    WHEN '不死鳥の羽根' THEN 'assets/images/items/phoenix_feather.png'
    WHEN '時空のマント' THEN 'assets/images/items/spacetime_cloak.png'
    WHEN '賢者の王冠' THEN 'assets/images/items/sage_crown.png'
END;