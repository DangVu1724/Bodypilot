-- 1. Create Allergy Master Table
CREATE TABLE IF NOT EXISTS allergy_masters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL UNIQUE,
    code VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Seed Predefined Allergy Options
INSERT INTO allergy_masters (name, code, description) VALUES
('Sữa (Milk)', 'MILK', 'Dị ứng sữa và các sản phẩm từ sữa / Allergy to milk and dairy products'),
('Trứng (Egg)', 'EGG', 'Dị ứng trứng / Allergy to eggs'),
('Cá (Fish)', 'FISH', 'Dị ứng các loại cá / Allergy to fish'),
('Động vật có vỏ (Shellfish)', 'SHELLFISH', 'Dị ứng tôm, cua, sò, nghêu... / Allergy to shellfish (shrimp, crab, clams, etc.)'),
('Đậu phộng (Peanut)', 'PEANUT', 'Dị ứng đậu phộng / Allergy to peanuts'),
('Hạt cây (Tree Nut)', 'TREE_NUT', 'Dị ứng quả hạch (hạnh nhân, óc chó, hạt điều...) / Allergy to tree nuts (almonds, walnuts, cashews, etc.)'),
('Đậu nành (Soy)', 'SOY', 'Dị ứng đậu nành và các sản phẩm từ đậu nành / Allergy to soy and soy products'),
('Gluten', 'GLUTEN', 'Dị ứng gluten (lúa mì, lúa mạch...) / Allergy to gluten (wheat, barley, etc.)'),
('Vừng/Mè (Sesame)', 'SESAME', 'Dị ứng hạt vừng/mè / Allergy to sesame seeds')
ON CONFLICT (code) DO NOTHING;

-- 3. Modify Mapping Table user_allergies
-- Note: In a production run, run a data migration before dropping food_id constraint.
-- Here, we drop the existing foreign key constraint to foods, add allergy_master_id, and alter unique constraints.

-- Drop existing unique constraints and FK referencing foods
ALTER TABLE user_allergies DROP CONSTRAINT IF EXISTS user_allergies_user_id_food_id_key;
ALTER TABLE user_allergies DROP CONSTRAINT IF EXISTS fk_user_allergies_food;

-- Add allergy_master_id column if not exists
ALTER TABLE user_allergies ADD COLUMN IF NOT EXISTS allergy_master_id UUID;

-- Add foreign key referencing allergy_masters
ALTER TABLE user_allergies 
    ADD CONSTRAINT fk_user_allergies_allergy_master 
    FOREIGN KEY (allergy_master_id) REFERENCES allergy_masters(id) ON DELETE CASCADE;

-- Add unique constraint on (user_id, allergy_master_id)
ALTER TABLE user_allergies 
    ADD CONSTRAINT user_allergies_user_id_allergy_master_id_key 
    UNIQUE (user_id, allergy_master_id);

-- Optional: Drop food_id column once safe to proceed
-- ALTER TABLE user_allergies DROP COLUMN IF EXISTS food_id;
