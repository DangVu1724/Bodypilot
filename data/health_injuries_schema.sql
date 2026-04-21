-- Health Conditions Master Table
CREATE TABLE health_conditions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    code VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    affects_diet BOOLEAN DEFAULT FALSE,
    affects_workout BOOLEAN DEFAULT FALSE,
    severity_level VARCHAR(50), -- LOW, MEDIUM, HIGH
    diet_notes TEXT,
    workout_notes TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Injuries Master Table
CREATE TABLE injuries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    code VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    body_part VARCHAR(50), -- KNEE, BACK, SHOULDER, ARM, LEG, FULL_BODY
    severity_level VARCHAR(50),
    restricted_exercises TEXT[], -- Array of exercise codes or names
    recommended_exercises TEXT[],
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User Health Conditions Mapping Table
CREATE TABLE user_health_conditions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    condition_id UUID NOT NULL,
    severity_override VARCHAR(50),
    note TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (condition_id) REFERENCES health_conditions(id) ON DELETE CASCADE
);

-- User Injuries Mapping Table
CREATE TABLE user_injuries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    injury_id UUID NOT NULL,
    severity_override VARCHAR(50),
    recovery_status VARCHAR(50), -- RECOVERING, STABLE, WORSENING
    note TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (injury_id) REFERENCES injuries(id) ON DELETE CASCADE
);

-- Sample Data: Health Conditions
INSERT INTO health_conditions (name, code, description, affects_diet, affects_workout, severity_level, diet_notes, workout_notes) VALUES
('Diabetes Type 1', 'DIABETES_T1', 'Insulin-dependent diabetes', TRUE, TRUE, 'HIGH', 'Focus on low glycemic index foods', 'Monitor blood sugar levels before and after exercise'),
('Diabetes Type 2', 'DIABETES_T2', 'Adult-onset diabetes', TRUE, TRUE, 'MEDIUM', 'Carbohydrate counting and portion control', 'Regular aerobic and strength training'),
('Hypertension', 'HYPERTENSION', 'High blood pressure', TRUE, TRUE, 'MEDIUM', 'Low sodium dietary approach', 'Avoid high-intensity isometric exercises'),
('Celiac Disease', 'CELIAC', 'Gluten intolerance', TRUE, FALSE, 'HIGH', 'Strict gluten-free diet required', 'None'),
('Asthma', 'ASTHMA', 'Respiratory condition', FALSE, TRUE, 'LOW', 'None', 'Keep inhaler nearby; cardio with caution'),
('Hypothyroidism', 'HYPOTHYROIDISM', 'Underactive thyroid', TRUE, TRUE, 'LOW', 'Iodine-rich foods; calorie control', 'Focus on metabolic-boosting workouts'),
('Heart Disease', 'HEART_DISEASE', 'Cardiovascular condition', TRUE, TRUE, 'HIGH', 'Low saturated fat and cholesterol', 'Cardiac rehab approved exercises only'),
('IBS', 'IBS', 'Irritable Bowel Syndrome', TRUE, FALSE, 'MEDIUM', 'FODMAP friendly diet', 'None');

-- Sample Data: Injuries
INSERT INTO injuries (name, code, body_part, severity_level, restricted_exercises, recommended_exercises) VALUES
('ACL Tear', 'ACL_TEAR', 'KNEE', 'HIGH', '{"Squats", "Lunges", "Jumping"}', '{"Swimming", "Isometric Quad Holds"}'),
('Runner''s Knee', 'RUNNERS_KNEE', 'KNEE', 'MEDIUM', '{"Downhill Running", "Deep Squats"}', '{"Strengthening Hips", "Foam Rolling"}'),
('Lower Back Pain', 'BACK_PAIN_LOW', 'BACK', 'MEDIUM', '{"Deadlifts", "High Impact Cardio"}', '{"Cat-Cow", "Bridges", "Planks"}'),
('Herniated Disc', 'HERNIATED_DISC', 'BACK', 'HIGH', '{"Heavy Lifting", "Twisting"}', '{"Walking", "Gentle Stretching"}'),
('Shoulder Impingement', 'SHOULDER_IMPINGEMENT', 'SHOULDER', 'MEDIUM', '{"Overhead Press", "Shadow Boxing"}', '{"External Rotations", "Face Pulls"}'),
('Rotator Cuff Tear', 'ROTATOR_CUFF_TEAR', 'SHOULDER', 'HIGH', '{"All Push/Pull Exercises"}', '{"Passive Range of Motion"}'),
('Tennis Elbow', 'TENNIS_ELBOW', 'ARM', 'LOW', '{"Heavy Curls", "Grip Intensive"}', '{"Eccentric Wrist Extensions"}'),
('Ankle Sprain', 'ANKLE_SPRAIN', 'LEG', 'LOW', '{"Running", "Agility Drills"}', '{"Ankle Circles", "Resistance Band Work"}');
