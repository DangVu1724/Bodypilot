package com.bodypilot.backend.service;

import java.util.Collections;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import com.bodypilot.backend.model.entity.nutrition.DietTag;
import com.bodypilot.backend.model.entity.nutrition.Food;
import com.bodypilot.backend.model.entity.nutrition.FoodCategory;
import com.bodypilot.backend.model.entity.user.UserAllergy;
import com.bodypilot.backend.model.entity.user.UserDietPreference;
import com.bodypilot.backend.model.entity.user.UserFoodPreference;
import com.bodypilot.backend.service.impl.diet.DietFoodFilterService;

import lombok.extern.slf4j.Slf4j;

@SpringBootTest
@Slf4j
public class DietAllergyAndSafetyPostProcessorTest {

    @Autowired
    private DietFoodFilterService foodFilterService;

    @Test
    @DisplayName("Test 1.1: Bộ lọc dị ứng - Đậu phộng")
    void testAllergyFiltering_Peanut() {
        UserAllergy peanutAllergy = UserAllergy.builder().note("Đậu phộng").build();

        List<Food> filtered = foodFilterService.getFilteredFoods(
                List.of(peanutAllergy),
                Collections.emptyList(),
                Collections.emptyList()
        );

        assertNotNull(filtered);
        log.info("Số lượng món an toàn sau khi lọc dị ứng Đậu phộng: {} món", filtered.size());

        for (Food f : filtered) {
            String nameLower = f.getName().toLowerCase();
            String descLower = f.getDescription() != null ? f.getDescription().toLowerCase() : "";
            assertFalse(nameLower.contains("đậu phộng") || descLower.contains("đậu phộng"),
                    "Lỗi: Món " + f.getName() + " vẫn chứa đậu phộng!");
        }
    }

    @Test
    @DisplayName("Test 1.2: Bộ lọc dị ứng - Hải sản (Tôm, Cua)")
    void testAllergyFiltering_Seafood() {
        UserAllergy seafoodAllergy = UserAllergy.builder().note("Hải sản, tôm, cua").build();

        List<Food> filtered = foodFilterService.getFilteredFoods(
                List.of(seafoodAllergy),
                Collections.emptyList(),
                Collections.emptyList()
        );

        assertNotNull(filtered);
        log.info("Số lượng món an toàn sau khi lọc dị ứng Hải sản (Tôm, Cua): {} món", filtered.size());

        for (Food f : filtered) {
            String nameLower = f.getName().toLowerCase();
            String descLower = f.getDescription() != null ? f.getDescription().toLowerCase() : "";
            assertFalse((nameLower.contains("tôm") && !nameLower.contains("tôm chay")) || (descLower.contains("tôm") && !descLower.contains("tôm chay")),
                    "Lỗi: Món " + f.getName() + " vẫn chứa tôm!");
            assertFalse((nameLower.contains("cua") && !nameLower.contains("cua chay")) || (descLower.contains("cua") && !descLower.contains("cua chay")),
                    "Lỗi: Món " + f.getName() + " vẫn chứa cua!");
        }
    }

    @Test
    @DisplayName("Test 1.3: Bộ lọc dị ứng - Trứng")
    void testAllergyFiltering_Egg() {
        UserAllergy eggAllergy = UserAllergy.builder().note("Trứng").build();

        List<Food> filtered = foodFilterService.getFilteredFoods(
                List.of(eggAllergy),
                Collections.emptyList(),
                Collections.emptyList()
        );

        assertNotNull(filtered);
        log.info("Số lượng món an toàn sau khi lọc dị ứng Trứng: {} món", filtered.size());

        for (Food f : filtered) {
            String nameLower = f.getName().toLowerCase();
            String descLower = f.getDescription() != null ? f.getDescription().toLowerCase() : "";
            assertFalse(nameLower.contains("trứng") || descLower.contains("trứng"),
                    "Lỗi: Món " + f.getName() + " vẫn chứa trứng!");
        }
    }

    @Test
    @DisplayName("Test 1.4: Bộ lọc dị ứng - Thịt bò")
    void testAllergyFiltering_Beef() {
        UserAllergy beefAllergy = UserAllergy.builder().note("Bò, thịt bò").build();

        List<Food> filtered = foodFilterService.getFilteredFoods(
                List.of(beefAllergy),
                Collections.emptyList(),
                Collections.emptyList()
        );

        assertNotNull(filtered);
        log.info("Số lượng món an toàn sau khi lọc dị ứng Thịt bò: {} món", filtered.size());

        for (Food f : filtered) {
            String nameLower = f.getName().toLowerCase();
            String descLower = f.getDescription() != null ? f.getDescription().toLowerCase() : "";
            assertFalse((nameLower.contains("bò") && !nameLower.contains("bò chay")) || (descLower.contains("bò") && !descLower.contains("bò chay")),
                    "Lỗi: Món " + f.getName() + " vẫn chứa bò!");
        }
    }

    @Test
    @DisplayName("Test 1.5: Bộ lọc dị ứng - Quả dâu (Dâu tây)")
    void testAllergyFiltering_Strawberry() {
        UserAllergy strawberryAllergy = UserAllergy.builder().note("Quả dâu, dâu tây, dâu").build();

        List<Food> filtered = foodFilterService.getFilteredFoods(
                List.of(strawberryAllergy),
                Collections.emptyList(),
                Collections.emptyList()
        );

        assertNotNull(filtered);
        log.info("Số lượng món an toàn sau khi lọc dị ứng Quả dâu: {} món", filtered.size());

        for (Food f : filtered) {
            String nameLower = f.getName().toLowerCase();
            String descLower = f.getDescription() != null ? f.getDescription().toLowerCase() : "";
            assertFalse(nameLower.contains("dâu") || descLower.contains("dâu"),
                    "Lỗi: Món " + f.getName() + " vẫn chứa dâu!");
        }
    }

    @Test
    @DisplayName("Test 1.6: Bộ lọc dị ứng - Quả bơ")
    void testAllergyFiltering_Avocado() {
        UserAllergy avocadoAllergy = UserAllergy.builder().note("Quả bơ, bơ").build();

        List<Food> filtered = foodFilterService.getFilteredFoods(
                List.of(avocadoAllergy),
                Collections.emptyList(),
                Collections.emptyList()
        );

        assertNotNull(filtered);
        log.info("Số lượng món an toàn sau khi lọc dị ứng Quả bơ: {} món", filtered.size());

        for (Food f : filtered) {
            String nameLower = f.getName().toLowerCase();
            String descLower = f.getDescription() != null ? f.getDescription().toLowerCase() : "";
            assertFalse(nameLower.contains("bơ") || descLower.contains("bơ"),
                    "Lỗi: Món " + f.getName() + " vẫn chứa bơ!");
        }
    }

    @Test
    @DisplayName("Test 1.7: Bộ lọc dị ứng - Cá ngừ")
    void testAllergyFiltering_Tuna() {
        UserAllergy tunaAllergy = UserAllergy.builder().note("Cá ngừ").build();

        List<Food> filtered = foodFilterService.getFilteredFoods(
                List.of(tunaAllergy),
                Collections.emptyList(),
                Collections.emptyList()
        );

        assertNotNull(filtered);
        log.info("Số lượng món an toàn sau khi lọc dị ứng Cá ngừ: {} món", filtered.size());

        for (Food f : filtered) {
            String nameLower = f.getName().toLowerCase();
            String descLower = f.getDescription() != null ? f.getDescription().toLowerCase() : "";
            assertFalse(nameLower.contains("cá ngừ") || descLower.contains("cá ngừ"),
                    "Lỗi: Món " + f.getName() + " vẫn chứa cá ngừ!");
        }
    }

    @Test
    @DisplayName("Test 1.8: Bộ lọc dị ứng - Thịt gà")
    void testAllergyFiltering_Chicken() {
        UserAllergy chickenAllergy = UserAllergy.builder().note("Gà, thịt gà").build();

        List<Food> filtered = foodFilterService.getFilteredFoods(
                List.of(chickenAllergy),
                Collections.emptyList(),
                Collections.emptyList()
        );

        assertNotNull(filtered);
        log.info("Số lượng món an toàn sau khi lọc dị ứng Thịt gà: {} món", filtered.size());

        for (Food f : filtered) {
            String nameLower = f.getName().toLowerCase();
            String descLower = f.getDescription() != null ? f.getDescription().toLowerCase() : "";
            
            boolean isChickenMeat = (nameLower.contains("gà") && !nameLower.contains("gà chay") 
                    && !nameLower.contains("trứng") && !nameLower.contains("lòng đỏ") && !nameLower.contains("lòng trắng"))
                    || nameLower.contains("chicken")
                    || descLower.contains("thịt gà") || descLower.contains("ức gà") 
                    || descLower.contains("đùi gà") || descLower.contains("cánh gà");

            assertFalse(isChickenMeat, "Lỗi: Món " + f.getName() + " vẫn chứa thịt gà!");
        }
    }

    @Test
    @DisplayName("Test 2: Bộ lọc chế độ ăn kiêng - Ăn chay (Vegetarian) loại bỏ hoàn toàn Thịt và Hải sản")
    void testDietComplianceVegetarian() {
        DietTag vegTag = DietTag.builder().name("VEGETARIAN").build();
        UserDietPreference vegDiet = UserDietPreference.builder().dietTag(vegTag).build();

        List<Food> filtered = foodFilterService.getFilteredFoods(
                Collections.emptyList(),
                List.of(vegDiet),
                Collections.emptyList()
        );

        assertNotNull(filtered);
        log.info("Số lượng món ăn chay sau khi lọc: {} món", filtered.size());

        for (Food f : filtered) {
            FoodCategory cat = f.getCategory();
            if (cat != null && cat.getCode() != null) {
                String code = cat.getCode().toUpperCase();
                assertFalse(code.equals("MEAT"), "Lỗi: Món ăn chay không được chứa thịt (MEAT): " + f.getName());
                assertFalse(code.equals("SEAFOOD"), "Lỗi: Món ăn chay không được chứa hải sản (SEAFOOD): " + f.getName());
            }
        }
    }

    @Test
    @DisplayName("Test 3: Bộ lọc món không thích (Disliked Food)")
    void testDislikedFoodFiltering() {
        UserFoodPreference dislike = UserFoodPreference.builder()
                .note("khổ qua, mướp đắng, sầu riêng")
                .build();

        List<Food> filtered = foodFilterService.getFilteredFoods(
                Collections.emptyList(),
                Collections.emptyList(),
                List.of(dislike)
        );

        assertNotNull(filtered);
        log.info("Số lượng món sau khi loại bỏ món không thích: {} món", filtered.size());

        for (Food f : filtered) {
            String nameLower = f.getName().toLowerCase();
            String descLower = f.getDescription() != null ? f.getDescription().toLowerCase() : "";

            assertFalse(nameLower.contains("khổ qua") || descLower.contains("khổ qua"),
                    "Lỗi: Món " + f.getName() + " vẫn chứa khổ qua!");
            assertFalse(nameLower.contains("mướp đắng") || descLower.contains("mướp đắng"),
                    "Lỗi: Món " + f.getName() + " vẫn chứa mướp đắng!");
            assertFalse(nameLower.contains("sầu riêng") || descLower.contains("sầu riêng"),
                    "Lỗi: Món " + f.getName() + " vẫn chứa sầu riêng!");
        }
    }

    @Test
    @DisplayName("Test 4: Bộ lọc kết hợp - Dị ứng + Ăn chay + Món không thích")
    void testCombinedFiltering() {
        UserAllergy peanut = UserAllergy.builder().note("Đậu phộng").build();
        DietTag vegTag = DietTag.builder().name("VEGETARIAN").build();
        UserDietPreference vegDiet = UserDietPreference.builder().dietTag(vegTag).build();
        UserFoodPreference dislike = UserFoodPreference.builder().note("hành tây").build();

        List<Food> filtered = foodFilterService.getFilteredFoods(
                List.of(peanut),
                List.of(vegDiet),
                List.of(dislike)
        );

        assertNotNull(filtered);
        log.info("Số lượng món sau khi lọc kết hợp: {} món", filtered.size());

        for (Food f : filtered) {
            String nameLower = f.getName().toLowerCase();
            String descLower = f.getDescription() != null ? f.getDescription().toLowerCase() : "";

            // Không chứa đậu phộng
            assertFalse(nameLower.contains("đậu phộng") || descLower.contains("đậu phộng"));
            // Không chứa hành tây
            assertFalse(nameLower.contains("hành tây") || descLower.contains("hành tây"));
            // Là món chay
            FoodCategory cat = f.getCategory();
            if (cat != null && cat.getCode() != null) {
                String code = cat.getCode().toUpperCase();
                assertFalse(code.equals("MEAT"));
                assertFalse(code.equals("SEAFOOD"));
            }
        }
    }
}
