-- 1. Modify Table user_food_preferences
-- Drop existing constraints
ALTER TABLE user_food_preferences DROP CONSTRAINT IF EXISTS user_food_preferences_user_id_food_id_preference_type_key;
ALTER TABLE user_food_preferences DROP CONSTRAINT IF EXISTS fk_user_food_preferences_food;

-- Remove columns not needed
ALTER TABLE user_food_preferences DROP COLUMN IF EXISTS food_id;
ALTER TABLE user_food_preferences DROP COLUMN IF EXISTS preference_type;
ALTER TABLE user_food_preferences DROP COLUMN IF EXISTS strength;

-- Add disliked_food_group column
ALTER TABLE user_food_preferences ADD COLUMN IF NOT EXISTS disliked_food_group VARCHAR(100) NOT NULL;

-- Add unique constraint on (user_id, disliked_food_group)
ALTER TABLE user_food_preferences 
    ADD CONSTRAINT user_food_preferences_user_id_disliked_food_group_key 
    UNIQUE (user_id, disliked_food_group);

-- 2. Modify Table user_profiles
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS food_budget VARCHAR(50);

-- 3. Seed diet_tags
INSERT INTO diet_tags (id, name, description) VALUES
(gen_random_uuid(), 'Keto', 'Chế độ ăn giàu chất béo, cực ít carbohydrate / High fat, very low carb diet'),
(gen_random_uuid(), 'Vegan', 'Chế độ ăn chay thuần, loại bỏ tất cả sản phẩm động vật / Strict plant-based diet'),
(gen_random_uuid(), 'Vegetarian', 'Chế độ ăn chay có thể ăn sữa, trứng / Plant-based diet including dairy and eggs'),
(gen_random_uuid(), 'Low-Carb', 'Hạn chế tối đa lượng tinh bột nạp vào / Low carbohydrate dietary intake'),
(gen_random_uuid(), 'Clean Eating', 'Tập trung thực phẩm tự nhiên, nguyên bản / Focuses on whole, unprocessed foods'),
(gen_random_uuid(), 'Mediterranean', 'Chế độ ăn giàu rau củ, cá, dầu oliu / Diet rich in veggies, fish, and olive oil')
ON CONFLICT (name) DO NOTHING;
