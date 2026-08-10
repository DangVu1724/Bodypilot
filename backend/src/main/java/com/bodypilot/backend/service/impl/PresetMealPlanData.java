package com.bodypilot.backend.service.impl;

import com.bodypilot.backend.model.enums.MealType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

public class PresetMealPlanData {

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PresetItem {
        private String foodName;
        private String categoryCode; // GRAIN, MEAT, SEAFOOD, VEG, FRUIT, BEVERAGE, DAIRY, NOODLE_SOUP, DRY_DISH
        private double defaultServingGrams;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PresetSlot {
        private MealType mealType;
        private String customName;
        private List<PresetItem> items;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PresetDay {
        private int dayIndex; // 0 to 6
        private List<PresetSlot> slots;
    }

    public static List<PresetDay> getPresetForGoal(String goalType) {
        String goal = (goalType != null) ? goalType.toUpperCase() : "DEFAULT";
        if (goal.contains("LOSE") || goal.contains("CUTTING")) {
            return buildLoseWeightPreset();
        } else if (goal.contains("GAIN") || goal.contains("BULKING")) {
            return buildGainMusclePreset();
        } else if (goal.contains("HEALTHY") || goal.contains("EAT_CLEAN")) {
            return buildEatCleanPreset();
        } else {
            return buildMaintainPreset();
        }
    }

    private static List<PresetDay> buildLoseWeightPreset() {
        List<PresetDay> days = new ArrayList<>();

        // Day 1
        days.add(createDay(0,
                createSlot(MealType.BREAKFAST, "Bữa sáng",
                        item("Yến mạch", "GRAIN", 60),
                        item("Trứng luộc", "MEAT", 100),
                        item("Táo", "FRUIT", 150)),
                createSlot(MealType.LUNCH, "Bữa trưa",
                        item("Cơm gạo lứt", "GRAIN", 150),
                        item("Ức gà áp chảo", "MEAT", 150),
                        item("Rau muống luộc", "VEG", 150),
                        item("Dưa hấu", "FRUIT", 150)),
                createSlot(MealType.DINNER, "Bữa tối",
                        item("Cơm gạo lứt", "GRAIN", 100),
                        item("Thịt bò xào súp lơ", "MEAT", 130),
                        item("Canh cải cúc", "VEG", 150),
                        item("Kiwi", "FRUIT", 100))
        ));

        // Day 2
        days.add(createDay(1,
                createSlot(MealType.BREAKFAST, "Bữa sáng",
                        item("Bánh mì cám yến mạch", "GRAIN", 80),
                        item("Trứng ốp la", "MEAT", 100),
                        item("Sữa chua Hy Lạp", "DAIRY", 100)),
                createSlot(MealType.LUNCH, "Bữa trưa",
                        item("Cơm gạo lứt", "GRAIN", 150),
                        item("Cá hồi nướng", "SEAFOOD", 130),
                        item("Salad dưa chuột cà chua", "VEG", 150),
                        item("Táo", "FRUIT", 150)),
                createSlot(MealType.DINNER, "Bữa tối",
                        item("Cơm gạo lứt", "GRAIN", 100),
                        item("Ức gà xé phay", "MEAT", 130),
                        item("Rau bắp cải luộc", "VEG", 150),
                        item("Cam", "FRUIT", 120))
        ));

        // Day 3
        days.add(createDay(2,
                createSlot(MealType.BREAKFAST, "Bữa sáng",
                        item("Khoai lang luộc", "GRAIN", 120),
                        item("Trứng luộc", "MEAT", 100),
                        item("Chuối", "FRUIT", 120)),
                createSlot(MealType.LUNCH, "Bữa trưa",
                        item("Cơm gạo lứt", "GRAIN", 150),
                        item("Thịt lợn nạc luộc", "MEAT", 130),
                        item("Canh bí đao", "VEG", 150),
                        item("Dưa hấu", "FRUIT", 150)),
                createSlot(MealType.DINNER, "Bữa tối",
                        item("Cơm gạo lứt", "GRAIN", 100),
                        item("Cá diêu hồng hấp", "SEAFOOD", 130),
                        item("Rau su su luộc", "VEG", 150),
                        item("Táo", "FRUIT", 120))
        ));

        // Day 4
        days.add(createDay(3,
                createSlot(MealType.BREAKFAST, "Bữa sáng",
                        item("Phở bò", "NOODLE_SOUP", 350),
                        item("Táo", "FRUIT", 120)),
                createSlot(MealType.LUNCH, "Bữa trưa",
                        item("Cơm gạo lứt", "GRAIN", 150),
                        item("Tôm hấp", "SEAFOOD", 130),
                        item("Canh mồng tơi luộc", "VEG", 150),
                        item("Cam", "FRUIT", 150)),
                createSlot(MealType.DINNER, "Bữa tối",
                        item("Cơm gạo lứt", "GRAIN", 100),
                        item("Đậu phụ sốt cà chua", "MEAT", 150),
                        item("Rau muống luộc", "VEG", 150),
                        item("Dưa hấu", "FRUIT", 120))
        ));

        // Day 5
        days.add(createDay(4,
                createSlot(MealType.BREAKFAST, "Bữa sáng",
                        item("Bánh mì nguyên cám", "GRAIN", 80),
                        item("Ức gà", "MEAT", 100),
                        item("Sữa tươi không đường", "DAIRY", 150)),
                createSlot(MealType.LUNCH, "Bữa trưa",
                        item("Cơm gạo lứt", "GRAIN", 150),
                        item("Thịt bò áp chảo", "MEAT", 130),
                        item("Bông cải xanh luộc", "VEG", 150),
                        item("Kiwi", "FRUIT", 120)),
                createSlot(MealType.DINNER, "Bữa tối",
                        item("Cơm gạo lứt", "GRAIN", 100),
                        item("Cá bống kho nạc", "SEAFOOD", 120),
                        item("Canh rau dền", "VEG", 150),
                        item("Táo", "FRUIT", 120))
        ));

        // Day 6
        days.add(createDay(5,
                createSlot(MealType.BREAKFAST, "Bữa sáng",
                        item("Yến mạch", "GRAIN", 60),
                        item("Sữa chua Hy Lạp", "DAIRY", 120),
                        item("Dâu tây", "FRUIT", 100)),
                createSlot(MealType.LUNCH, "Bữa trưa",
                        item("Cơm gạo lứt", "GRAIN", 150),
                        item("Ức gà nướng", "MEAT", 140),
                        item("Măng tây xào tỏi", "VEG", 130),
                        item("Dưa hấu", "FRUIT", 150)),
                createSlot(MealType.DINNER, "Bữa tối",
                        item("Cơm gạo lứt", "GRAIN", 100),
                        item("Thịt lợn thăn luộc", "MEAT", 130),
                        item("Canh bù ngót thịt băm", "VEG", 150),
                        item("Cam", "FRUIT", 120))
        ));

        // Day 7
        days.add(createDay(6,
                createSlot(MealType.BREAKFAST, "Bữa sáng",
                        item("Bún gà xé", "NOODLE_SOUP", 350),
                        item("Táo", "FRUIT", 120)),
                createSlot(MealType.LUNCH, "Bữa trưa",
                        item("Cơm gạo lứt", "GRAIN", 150),
                        item("Tôm nướng sa tế nhẹ", "SEAFOOD", 130),
                        item("Rau bí xào tỏi", "VEG", 140),
                        item("Chuối", "FRUIT", 120)),
                createSlot(MealType.DINNER, "Bữa tối",
                        item("Cơm gạo lứt", "GRAIN", 100),
                        item("Cá diêu hồng nướng", "SEAFOOD", 140),
                        item("Canh cải xanh", "VEG", 150),
                        item("Kiwi", "FRUIT", 100))
        ));

        return days;
    }

    private static List<PresetDay> buildGainMusclePreset() {
        List<PresetDay> days = new ArrayList<>();

        days.add(createDay(0,
                createSlot(MealType.BREAKFAST, "Bữa sáng",
                        item("Phở bò", "NOODLE_SOUP", 400),
                        item("Trứng luộc", "MEAT", 100),
                        item("Sữa tươi", "DAIRY", 200)),
                createSlot(MealType.LUNCH, "Bữa trưa",
                        item("Cơm trắng", "GRAIN", 250),
                        item("Thịt bò xào củ hành", "MEAT", 180),
                        item("Canh bí đỏ thịt băm", "VEG", 180),
                        item("Chuối", "FRUIT", 150)),
                createSlot(MealType.DINNER, "Bữa tối",
                        item("Cơm trắng", "GRAIN", 200),
                        item("Ức gà nướng", "MEAT", 180),
                        item("Rau muống xào tỏi", "VEG", 150),
                        item("Táo", "FRUIT", 150))
        ));

        for (int i = 1; i < 7; i++) {
            days.add(createDay(i,
                    createSlot(MealType.BREAKFAST, "Bữa sáng",
                            item(i % 2 == 0 ? "Bún bò Huế" : "Bánh mì kẹp thịt trứng", i % 2 == 0 ? "NOODLE_SOUP" : "DRY_DISH", 380),
                            item("Sữa chua Hy Lạp", "DAIRY", 120),
                            item("Táo", "FRUIT", 120)),
                    createSlot(MealType.LUNCH, "Bữa trưa",
                            item("Cơm trắng", "GRAIN", 250),
                            item(i % 2 == 0 ? "Cá hồi áp chảo" : "Thịt lợn nạc kho", i % 2 == 0 ? "SEAFOOD" : "MEAT", 180),
                            item("Rau cải luộc", "VEG", 160),
                            item("Dưa hấu", "FRUIT", 150)),
                    createSlot(MealType.DINNER, "Bữa tối",
                            item("Cơm gạo lứt", "GRAIN", 200),
                            item(i % 2 == 0 ? "Tôm rim" : "Thịt bò nướng", i % 2 == 0 ? "SEAFOOD" : "MEAT", 170),
                            item("Canh mồng tơi", "VEG", 160),
                            item("Chuối", "FRUIT", 120))
            ));
        }
        return days;
    }

    private static List<PresetDay> buildEatCleanPreset() {
        List<PresetDay> days = new ArrayList<>();
        for (int i = 0; i < 7; i++) {
            days.add(createDay(i,
                    createSlot(MealType.BREAKFAST, "Bữa sáng",
                            item("Yến mạch nguyên cám", "GRAIN", 70),
                            item("Trứng luộc", "MEAT", 100),
                            item("Táo", "FRUIT", 150)),
                    createSlot(MealType.LUNCH, "Bữa trưa",
                            item("Cơm gạo lứt", "GRAIN", 160),
                            item(i % 2 == 0 ? "Ức gà hấp" : "Cá lóc hấp", i % 2 == 0 ? "MEAT" : "SEAFOOD", 150),
                            item("Súp lơ luộc", "VEG", 160),
                            item("Cam", "FRUIT", 140)),
                    createSlot(MealType.DINNER, "Bữa tối",
                            item("Khoai lang hấp", "GRAIN", 140),
                            item(i % 2 == 0 ? "Thịt bò nạc hấp" : "Tôm hấp", i % 2 == 0 ? "MEAT" : "SEAFOOD", 140),
                            item("Salad trộn dầu oliu", "VEG", 150),
                            item("Kiwi", "FRUIT", 120))
            ));
        }
        return days;
    }

    private static List<PresetDay> buildMaintainPreset() {
        List<PresetDay> days = new ArrayList<>();
        for (int i = 0; i < 7; i++) {
            days.add(createDay(i,
                    createSlot(MealType.BREAKFAST, "Bữa sáng",
                            item(i % 3 == 0 ? "Phở bò" : (i % 3 == 1 ? "Bánh mì ốp la" : "Yến mạch"), i % 3 == 0 ? "NOODLE_SOUP" : "GRAIN", 300),
                            item("Sữa tươi", "DAIRY", 150),
                            item("Chuối", "FRUIT", 120)),
                    createSlot(MealType.LUNCH, "Bữa trưa",
                            item("Cơm trắng", "GRAIN", 180),
                            item(i % 2 == 0 ? "Thịt heo kho trứng" : "Cá diêu hồng chiên sốt cà", i % 2 == 0 ? "MEAT" : "SEAFOOD", 150),
                            item("Canh cải ngọt thịt băm", "VEG", 160),
                            item("Dưa hấu", "FRUIT", 150)),
                    createSlot(MealType.DINNER, "Bữa tối",
                            item("Cơm gạo lứt", "GRAIN", 140),
                            item(i % 2 == 0 ? "Thịt bò xào dưa chuột" : "Gà chiên nước mắm nạc", "MEAT", 150),
                            item("Rau muống luộc", "VEG", 160),
                            item("Táo", "FRUIT", 120))
            ));
        }
        return days;
    }

    private static PresetDay createDay(int dayIndex, PresetSlot... slots) {
        return PresetDay.builder()
                .dayIndex(dayIndex)
                .slots(List.of(slots))
                .build();
    }

    private static PresetSlot createSlot(MealType type, String customName, PresetItem... items) {
        return PresetSlot.builder()
                .mealType(type)
                .customName(customName)
                .items(List.of(items))
                .build();
    }

    private static PresetItem item(String name, String categoryCode, double grams) {
        return PresetItem.builder()
                .foodName(name)
                .categoryCode(categoryCode)
                .defaultServingGrams(grams)
                .build();
    }
}
