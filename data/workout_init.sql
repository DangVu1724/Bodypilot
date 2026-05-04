-- ==========================================
-- SCRIPT TẠO BẢNG VÀ INSERT DỮ LIỆU MẪU (WORKOUT)
-- Dành cho PostgreSQL / Supabase
-- ==========================================

-- 1. TẠO CÁC BẢNG (TABLES)

CREATE TABLE IF NOT EXISTS workout_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    workout_type VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID REFERENCES workout_categories(id) ON DELETE CASCADE,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    media_url TEXT,
    difficulty VARCHAR(50) NOT NULL,
    met_value DOUBLE PRECISION,
    equipment JSONB,
    target_muscles JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS workout_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    goal VARCHAR(50) NOT NULL,
    difficulty VARCHAR(50) NOT NULL,
    total_days INTEGER NOT NULL,
    thumbnail_url TEXT,
    is_premium BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS workout_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id UUID REFERENCES workout_plans(id) ON DELETE CASCADE,
    day_number INTEGER NOT NULL,
    name VARCHAR(255) NOT NULL,
    exercise_items JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS workout_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL, -- Thêm REFERENCES users(id) nếu bạn đã có bảng users
    session_id UUID REFERENCES workout_sessions(id) ON DELETE SET NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    total_calories DOUBLE PRECISION,
    mood_rating INTEGER,
    actual_performance JSONB,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ==========================================
-- 2. INSERT DỮ LIỆU MẪU (SEED DATA)
-- ==========================================

-- Seed: Workout Categories
INSERT INTO workout_categories (id, code, name, description, workout_type) VALUES
('11111111-1111-1111-1111-111111111111', 'GYM', 'Gym & Strength', 'Luyện tập sức mạnh với tạ, phát triển cơ bắp', 'STRENGTH'),
('22222222-2222-2222-2222-222222222222', 'CARDIO', 'Cardio & HIIT', 'Tăng cường hệ tim mạch và đốt mỡ toàn thân', 'CARDIO'),
('33333333-3333-3333-3333-333333333333', 'YOGA', 'Yoga & Stretching', 'Cải thiện sự dẻo dai, thư giãn và tĩnh tâm', 'FLEXIBILITY')
ON CONFLICT (code) DO UPDATE SET 
    name = EXCLUDED.name, 
    description = EXCLUDED.description, 
    workout_type = EXCLUDED.workout_type;

-- Seed: Exercises
INSERT INTO exercises (id, category_id, code, name, description, media_url, difficulty, met_value, equipment, target_muscles) VALUES
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'BENCH_PRESS', 'Barbell Bench Press', 'Nằm ghế đẩy tạ đòn. Bài tập phức hợp tập trung vào ngực giữa, tay sau và vai trước.', 'https://example.com/videos/bench-press.mp4', 'INTERMEDIATE', 5.0, '["BARBELL", "BENCH"]', '["CHEST", "TRICEPS", "SHOULDERS"]'),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111', 'SQUAT', 'Barbell Back Squat', 'Gánh tạ đòn ngồi xổm. Bài tập "vua" phát triển toàn diện sức mạnh thân dưới.', 'https://example.com/videos/squat.mp4', 'INTERMEDIATE', 6.0, '["BARBELL", "SQUAT_RACK"]', '["QUADS", "GLUTES", "HAMSTRINGS", "CORE"]'),
('cccccccc-cccc-cccc-cccc-cccccccccccc', '22222222-2222-2222-2222-222222222222', 'JUMPING_JACKS', 'Jumping Jacks', 'Bài tập cardio bật nhảy tại chỗ, khởi động toàn thân rất tốt.', 'https://example.com/videos/jumping-jacks.mp4', 'BEGINNER', 8.0, '["NONE"]', '["FULL_BODY"]'),
('dddddddd-dddd-dddd-dddd-dddddddddddd', '11111111-1111-1111-1111-111111111111', 'DUMBBELL_CURL', 'Dumbbell Bicep Curl', 'Cuốn tạ đơn tập tay trước. Tập trung cô lập cơ bắp tay.', 'https://example.com/videos/curl.mp4', 'BEGINNER', 3.5, '["DUMBBELL"]', '["BICEPS"]')
ON CONFLICT (code) DO UPDATE SET 
    name = EXCLUDED.name, 
    description = EXCLUDED.description,
    difficulty = EXCLUDED.difficulty,
    equipment = EXCLUDED.equipment,
    target_muscles = EXCLUDED.target_muscles;

-- Seed: Workout Plans
-- Xóa giáo án cũ (nếu có) để tránh lỗi trùng lặp khi chạy lại script
DELETE FROM workout_plans WHERE id = '99999999-9999-9999-9999-999999999999';

INSERT INTO workout_plans (id, title, goal, difficulty, total_days, thumbnail_url, is_premium) VALUES
('99999999-9999-9999-9999-999999999999', 'Giáo án Push-Pull-Legs Cơ Bản', 'GAIN_MUSCLE', 'INTERMEDIATE', 3, 'https://example.com/images/ppl-thumbnail.jpg', false);

-- Seed: Workout Sessions
DELETE FROM workout_sessions WHERE id IN ('77777777-7777-7777-7777-777777777777', '88888888-8888-8888-8888-888888888888');

INSERT INTO workout_sessions (id, plan_id, day_number, name, exercise_items) VALUES
('77777777-7777-7777-7777-777777777777', '99999999-9999-9999-9999-999999999999', 1, 'Ngày 1: Push (Ngực, Vai, Tay sau)', 
'[
  {
    "exerciseId": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
    "order": 1,
    "sets": 4,
    "reps": 10,
    "weightKg": 40.0,
    "restSeconds": 90,
    "durationMinutes": null,
    "distanceKm": null
  },
  {
    "exerciseId": "cccccccc-cccc-cccc-cccc-cccccccccccc",
    "order": 2,
    "sets": 3,
    "reps": 30,
    "weightKg": 0,
    "restSeconds": 60,
    "durationMinutes": null,
    "distanceKm": null
  }
]'::jsonb),

('88888888-8888-8888-8888-888888888888', '99999999-9999-9999-9999-999999999999', 2, 'Ngày 2: Legs (Đùi, Mông, Bắp chân)', 
'[
  {
    "exerciseId": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
    "order": 1,
    "sets": 4,
    "reps": 8,
    "weightKg": 60.0,
    "restSeconds": 120,
    "durationMinutes": null,
    "distanceKm": null
  }
]'::jsonb);

-- LƯU Ý: Không thêm sẵn WorkoutLog vì đây là data phát sinh trong quá trình User tập luyện.
