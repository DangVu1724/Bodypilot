package com.bodypilot.backend.service.impl;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

public class PresetWorkoutPlanData {

        @Data
        @Builder
        @NoArgsConstructor
        @AllArgsConstructor
        public static class PresetExerciseItem {
                private String exerciseName;
                private String bodyPartCode; // CHEST, BACK, LEGS, SHOULDERS, ARMS, CORE, CARDIO, FULL_BODY
                private int sets;
                private int reps;
                private double weightKg;
                private int restSeconds;
                private int durationMinutes;
                private double distanceKm;
                private double caloriesBurned;
                private String notes;
        }

        @Data
        @Builder
        @NoArgsConstructor
        @AllArgsConstructor
        public static class PresetWorkoutDay {
                private int dayIndex; // 0 to 6
                private String note;
                private List<PresetExerciseItem> exerciseItems;
        }

        public static List<PresetWorkoutDay> getPresetForGoal(String goalType, String focusBodyPart) {
                String goal = (goalType != null) ? goalType.toUpperCase() : "DEFAULT";
                if (goal.contains("LOSE") || goal.contains("CUTTING")) {
                        return buildFatLossPreset();
                } else if (goal.contains("GAIN") || goal.contains("BULKING") || goal.contains("MUSCLE")) {
                        return buildGainMusclePreset();
                } else if (goal.contains("ENDURANCE")) {
                        return buildEndurancePreset();
                } else {
                        return buildMaintainPreset();
                }
        }

        private static List<PresetWorkoutDay> buildFatLossPreset() {
                List<PresetWorkoutDay> days = new ArrayList<>();

                // Day 1: Full Body HIIT & Core
                days.add(createDay(0, "Tập toàn thân & Giảm mỡ (HIIT & Core)",
                                item("Jumping Jacks", "CARDIO", 4, 30, 0, 30, 8, 0, 60,
                                                "Nhảy giạng tay chân nhịp nhàng"),
                                item("Chống đẩy", "CHEST", 3, 12, 0, 45, 10, 0, 50, "Giữ lưng thẳng, hạ ngực sát đất"),
                                item("Squat", "LEGS", 4, 15, 0, 45, 12, 0, 70,
                                                "Đẩy hông về sau, gối không vượt quá mũi chân"),
                                item("Plank", "CORE", 3, 1, 0, 60, 6, 0, 40,
                                                "Giữ người thẳng như tấm ván trong 45 giây")));

                // Day 2: Cardio & Lower Body
                days.add(createDay(1, "Chạy bộ tiêu hao năng lượng & Chân mông",
                                item("Chạy bộ", "CARDIO", 1, 1, 0, 60, 20, 2.5, 180,
                                                "Chạy bộ tốc độ trung bình tiêu hao calo"),
                                item("Lunge", "LEGS", 3, 12, 0, 45, 10, 0, 55,
                                                "Bước dài về phía trước, gối vuông góc 90 độ"),
                                item("Gập bụng", "CORE", 3, 15, 0, 45, 8, 0, 45,
                                                "Siết chặt cơ bụng khi nâng vai lên")));

                // Day 3: Rest / Active Recovery
                days.add(createDay(2, "Ngày nghỉ ngơi phục hồi & Giãn cơ",
                                item("Giãn cơ toàn thân", "CARDIO", 1, 1, 0, 0, 15, 0, 30,
                                                "Thực hiện các động tác giãn cơ nhẹ nhàng")));

                // Day 4: Upper Body & HIIT
                days.add(createDay(3, "Tập thân trên & Tiêu mỡ",
                                item("Chống đẩy", "CHEST", 4, 12, 0, 45, 10, 0, 60, "Tập trung lực ngực và tay sau"),
                                item("Kéo xà đơn", "BACK", 3, 8, 0, 60, 10, 0, 50,
                                                "Kéo người lên cho đến khi cằm vượt quá xà"),
                                item("Gập bụng", "CORE", 4, 15, 0, 45, 10, 0, 50, "Gập bụng kiểm soát nhịp thở")));

                // Day 5: Cardio & Tabata
                days.add(createDay(4, "Cardio tim mạch & Đốt calo",
                                item("Chạy bộ", "CARDIO", 1, 1, 0, 60, 25, 3.0, 220, "Duy trì nhịp tim ở vùng đốt mỡ"),
                                item("Burpee", "FULL_BODY", 3, 10, 0, 60, 10, 0, 70, "Bật nhảy và hít đất liên hoàn")));

                // Day 6: Leg & Abs
                days.add(createDay(5, "Tập chân đùi & Bụng đùi",
                                item("Squat", "LEGS", 4, 15, 0, 45, 12, 0, 75, "Tăng cường sức mạnh đôi chân"),
                                item("Lunge", "LEGS", 3, 12, 0, 45, 10, 0, 55, "Siết đùi trước và cơ mông"),
                                item("Plank", "CORE", 3, 1, 0, 60, 8, 0, 45, "Siết bụng phẳng")));

                // Day 7: Rest
                days.add(createDay(6, "Ngày nghỉ phục hồi cơ bắp",
                                item("Giãn cơ toàn thân", "CARDIO", 1, 1, 0, 0, 15, 0, 30,
                                                "Giãn thả lỏng các nhóm cơ")));

                return days;
        }

        private static List<PresetWorkoutDay> buildGainMusclePreset() {
                List<PresetWorkoutDay> days = new ArrayList<>();

                // Day 1: Chest & Triceps (Ngực & Tay sau)
                days.add(createDay(0, "Tập Ngực & Tay sau (Push Day)",
                                item("Đẩy ngực bằng tạ đòn", "CHEST", 4, 10, 40, 90, 15, 0, 110,
                                                "Đẩy tạ đòn ngang ngực, hạ kiểm soát"),
                                item("Chống đẩy", "CHEST", 3, 12, 0, 60, 10, 0, 60, "Tập tối đa phạm vi chuyển động"),
                                item("Đẩy tay sau", "ARMS", 3, 12, 10, 60, 10, 0, 50,
                                                "Duỗi thẳng tay sau ép cơ triceps")));

                // Day 2: Back & Biceps (Lưng & Tay trước)
                days.add(createDay(1, "Tập Lưng xô & Tay trước (Pull Day)",
                                item("Kéo xà đơn", "BACK", 4, 8, 0, 90, 12, 0, 80, "Gồng lưng xô kéo thân người lên"),
                                item("Gập người kéo tạ đơn", "BACK", 3, 10, 14, 60, 12, 0, 70,
                                                "Kéo tạ đơn sát hông ép xô"),
                                item("Cuốn tạ đơn", "ARMS", 3, 12, 10, 60, 10, 0, 50,
                                                "Gập cẳng tay cuốn tạ đơn tập cơ tay trước")));

                // Day 3: Legs & Abs (Chân & Bụng)
                days.add(createDay(2, "Tập Chân Đùi & Cơ bụng (Leg Day)",
                                item("Squat", "LEGS", 4, 10, 30, 90, 15, 0, 120, "Gánh tạ gập gối vuông góc 90 độ"),
                                item("Đạp đùi", "LEGS", 3, 12, 50, 60, 12, 0, 90, "Đẩy bàn đạp chân kiểm soát tạ"),
                                item("Gập bụng", "CORE", 3, 15, 0, 45, 10, 0, 50, "Gập bụng siết cơ sáu múi")));

                // Day 4: Rest
                days.add(createDay(3, "Ngày nghỉ ngơi phát triển cơ bắp",
                                item("Giãn cơ toàn thân", "CARDIO", 1, 1, 0, 0, 15, 0, 30,
                                                "Thả lỏng phục hồi sau chuỗi ngày tập nặng")));

                // Day 5: Shoulders & Arms (Vai & Tay)
                days.add(createDay(4, "Tập Vai & Tay toàn diện (Shoulders & Arms)",
                                item("Đẩy vai tạ đơn", "SHOULDERS", 4, 10, 12, 75, 12, 0, 85,
                                                "Đẩy tạ đơn qua đầu tập vai trước và giữa"),
                                item("Cuốn tạ đơn", "ARMS", 3, 12, 10, 60, 10, 0, 50, "Cuốn tạ tập bicep"),
                                item("Plank", "CORE", 3, 1, 0, 60, 6, 0, 40, "Gồng gánh vai và core")));

                // Day 6: Full Body / Weak Point
                days.add(createDay(5, "Tập toàn thân & Tăng khối lượng cơ",
                                item("Chống đẩy", "CHEST", 3, 15, 0, 60, 10, 0, 60, "Tập bổ sung thể lực"),
                                item("Squat", "LEGS", 3, 12, 20, 60, 12, 0, 80, "Tập phát triển cơ đùi"),
                                item("Gập bụng", "CORE", 3, 15, 0, 45, 8, 0, 40, "Tập cơ bụng kiên cố")));

                // Day 7: Rest
                days.add(createDay(6, "Ngày nghỉ hoàn toàn",
                                item("Giãn cơ toàn thân", "CARDIO", 1, 1, 0, 0, 15, 0, 30,
                                                "Nghỉ ngơi chuẩn bị cho tuần mới")));

                return days;
        }

        private static List<PresetWorkoutDay> buildEndurancePreset() {
                List<PresetWorkoutDay> days = new ArrayList<>();
                for (int i = 0; i < 7; i++) {
                        if (i % 2 == 0) {
                                days.add(createDay(i, "Tăng sức bền tim mạch & dẻo dai",
                                                item("Chạy bộ", "CARDIO", 1, 1, 0, 60, 30, 4.0, 260,
                                                                "Duy trì nhịp chạy đều đặn"),
                                                item("Jumping Jacks", "CARDIO", 3, 30, 0, 30, 6, 0, 50,
                                                                "Khởi động tim mạch tốt"),
                                                item("Plank", "CORE", 3, 1, 0, 60, 6, 0, 40,
                                                                "Tăng sức bền vùng bụng")));
                        } else if (i == 3) {
                                days.add(createDay(i, "Ngày nghỉ dẻo dai nhẹ nhàng",
                                                item("Giãn cơ toàn thân", "CARDIO", 1, 1, 0, 0, 20, 0, 40,
                                                                "Tập thả lỏng cơ khớp")));
                        } else {
                                days.add(createDay(i, "Tập thể lực & Sức bền cơ bắp",
                                                item("Squat", "LEGS", 4, 15, 0, 45, 12, 0, 75,
                                                                "Nhảy squat hoặc squat không tạ nhanh"),
                                                item("Chống đẩy", "CHEST", 3, 15, 0, 45, 10, 0, 60,
                                                                "Tăng sức bền thân trên"),
                                                item("Gập bụng", "CORE", 4, 20, 0, 30, 10, 0, 55,
                                                                "Tập sức bền bụng linh hoạt")));
                        }
                }
                return days;
        }

        private static List<PresetWorkoutDay> buildMaintainPreset() {
                List<PresetWorkoutDay> days = new ArrayList<>();
                for (int i = 0; i < 7; i++) {
                        if (i == 0 || i == 2 || i == 4) {
                                days.add(createDay(i, "Tập thể thao sức khỏe & duy trì vóc dáng",
                                                item("Chống đẩy", "CHEST", 3, 12, 0, 60, 10, 0, 50, "Duy trì lực ngực"),
                                                item("Squat", "LEGS", 3, 12, 0, 60, 10, 0, 60, "Duy trì lực chân mông"),
                                                item("Gập bụng", "CORE", 3, 12, 0, 45, 8, 0, 40,
                                                                "Duy trì vòng vèo bụng khỏe")));
                        } else if (i == 6) {
                                days.add(createDay(i, "Chạy bộ nhẹ nhàng cuối tuần",
                                                item("Chạy bộ", "CARDIO", 1, 1, 0, 60, 20, 2.0, 150,
                                                                "Chạy thư giãn cuối tuần")));
                        } else {
                                days.add(createDay(i, "Ngày nghỉ phục hồi thể trạng",
                                                item("Giãn cơ toàn thân", "CARDIO", 1, 1, 0, 0, 15, 0, 30,
                                                                "Giãn lỏng cơ thể nhẹ nhàng")));
                        }
                }
                return days;
        }

        private static PresetWorkoutDay createDay(int dayIndex, String note, PresetExerciseItem... items) {
                return PresetWorkoutDay.builder()
                                .dayIndex(dayIndex)
                                .note(note)
                                .exerciseItems(List.of(items))
                                .build();
        }

        private static PresetExerciseItem item(String name, String bodyPartCode, int sets, int reps, double weightKg,
                        int restSeconds, int durationMinutes, double distanceKm,
                        double caloriesBurned, String notes) {
                return PresetExerciseItem.builder()
                                .exerciseName(name)
                                .bodyPartCode(bodyPartCode)
                                .sets(sets)
                                .reps(reps)
                                .weightKg(weightKg)
                                .restSeconds(restSeconds)
                                .durationMinutes(durationMinutes)
                                .distanceKm(distanceKm)
                                .caloriesBurned(caloriesBurned)
                                .notes(notes)
                                .build();
        }
}
