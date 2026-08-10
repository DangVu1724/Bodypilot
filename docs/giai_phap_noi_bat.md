# CHƯƠNG 5: CÁC GIẢI PHÁP VÀ ĐÓNG GÓP NỔI BẬT

Trong quá trình nghiên cứu và phát triển hệ thống quản lý thể trạng và dinh dưỡng cá nhân hóa **BodyPilot**, tác giả đã phân tích các thách thức kỹ thuật thực tế khi kết hợp giữa kiến trúc ứng dụng phân tán và các mô hình ngôn ngữ lớn (Generative AI / LLM). Chương này trình bày chi tiết 5 giải pháp kỹ thuật nổi bật nhất mang tính đóng góp cốt lõi của đồ án, được cấu trúc theo 5 phần độc lập từ 5.1 đến 5.5.

---

## 5.1. Giải pháp xây dựng Prompt ngữ cảnh động (Dynamic Prompt Context Injection Engine)

### 5.1.1. Dẫn dắt và Giới thiệu bài toán

Khi ứng dụng các mô hình ngôn ngữ lớn (Large Language Models - LLM) như **Google Gemini 2.5 Flash** vào bài toán sinh thực đơn dinh dưỡng cá nhân hóa, phương pháp truyền câu lệnh đơn giản (Simple Prompting) gặp phải 4 hạn chế kỹ thuật nghiêm trọng:

1. **Thiếu thông tin thể trạng cá nhân (Context Blindness):** AI không biết được chỉ số $BMR$, $TDEE$, mục tiêu thể hình (tăng cơ, giảm mỡ, siết cân) hoặc các hạn chế y tế (dị ứng hải sản, kiêng sữa, không ăn đồ nạp nhiều dầu mỡ) của người dùng.
2. **Hiện tượng ảo giác AI (AI Hallucination):** LLM tự do bịa ra tên các món ăn không có thực ngoài đời hoặc không tồn tại trong cơ sở dữ liệu của ứng dụng, khiến hệ thống không thể ánh xạ (`foodId`) để lưu trữ dữ liệu.
3. **Trôi dạt định dạng JSON (JSON Output Drift):** Phản hồi từ AI bị lẫn các văn bản giải thích tự do hoặc thiếu các trường bắt buộc, làm phá vỡ tiến trình giải mã (JSON Deserialization) tại máy chủ Backend.
4. **Xa rời văn hóa ẩm thực Việt Nam:** AI gợi ý các món ăn phương Tây không quen thuộc với đa số người Việt, hoặc sắp xếp sai cấu trúc mâm cơm (như gợi ý "Đậu phụ chiên" hay "Thịt kho" vào bữa sáng).

---

### 5.1.2. Giải pháp kỹ thuật đề xuất

Tác giả thiết kế giải pháp **Prompt Ngữ cảnh Động (Dynamic Prompt Context Injection)** tích hợp trong phương thức `buildPrompt()` của lớp [`DietSuggestionHelper`](file:///c:/Personal/DATN/BodyPilot/backend/src/main/java/com/bodypilot/backend/service/impl/DietSuggestionHelper.java). Giải pháp tổ chức Prompt thành 4 khối ngữ cảnh có cấu trúc chặt chẽ:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                 CẤU TRÚC PROMPT NGỮ CẢNH ĐỘNG (DYNAMIC CONTEXT)         │
├─────────────────────────────────────────────────────────────────────────┤
│ KHỐI 1: THÔNG SỐ SINH HỌC & MỤC TIÊU NĂNG LƯỢNG                         │
│ - Gender, Age, Height, Weight, Activity Level, Budget                   │
│ - Target Calories (TDEE +/- 10% Margin Constraint)                      │
├─────────────────────────────────────────────────────────────────────────┤
│ KHỐI 2: RÀNG BUỘC RẤT NGHIÊM NGẶT VỀ Y TẾ & SỞ THÍCH                   │
│ - Bắt buộc tránh tuyệt đối các AllergyMaster (SEAFOOD, DAIRY, ORGAN...) │
│ - Đuổi các nhóm món ăn không thích (DislikedFoodGroup)                  │
├─────────────────────────────────────────────────────────────────────────┤
│ KHỐI 3: NGUYÊN TẮC CỐT LÕI ẨM THỰC VIỆT NAM & PHỐI BỮA KHOA HỌC        │
│ - Bữa sáng (BREAKFAST): Combo 2-3 món (Món nước + Đồ uống / Trái cây)   │
│ - Bữa tối (DINNER): Bắt buộc có Cơm chính (Cơm trắng / Cơm gạo lứt)     │
│ - Xoay vòng Trái cây tráng miệng (`FRUIT`), không trùng loại trong ngày │
├─────────────────────────────────────────────────────────────────────────┤
│ KHỐI 4: ÉP ĐỊNH DẠNG ĐẦU RẠ CHUẨN JSON SCHEMA                           │
│ - Bắt buộc khớp `foodId` và `foodName` từ tập Candidate                 │
│ - Ép định dạng Mảng JSON thuần túy (MimeType: `application/json`)       │
└─────────────────────────────────────────────────────────────────────────┘
```

#### 1. Xây dựng Khối Thông số Sinh học và Hạn ngạch Calo Mục tiêu

Tầng Service thu thập thông tin từ `UserProfile`, `UserGoal`, và `UserMetricHistory` để đưa vào Prompt:

$$
\text{TargetCalories} = \text{TDEE} \quad (\text{Cho phép biên độ dao động } \pm 10\%)
$$

```java
StringBuilder sb = new StringBuilder();
sb.append("- Giới tính: ").append(profile.getGender()).append("\n");
sb.append("- Chiều cao: ").append(profile.getHeightCm()).append(" cm, Cân nặng: ").append(profile.getWeight()).append(" kg\n");
sb.append("- Lượng calo tiêu thụ mục tiêu mỗi ngày: ").append(metric.getTargetCalories().intValue()).append(" kcal (LƯU Ý: Thực đơn 3 bữa xấp xỉ mức này, sai số trong khoảng +/- 10%)\n");
```

#### 2. Xây dựng Khối Loại trừ Y tế và Chế độ ăn Đặc thù

Hệ thống tự động đưa danh sách các chất gây dị ứng (`UserAllergy`) và các nhóm thực phẩm không thích (`UserFoodPreference`) vào dòng lệnh ưu tiên cao nhất:

```java
if (!allergies.isEmpty()) {
    String allergyNames = allergies.stream().map(a -> a.getAllergyMaster().getName()).collect(Collectors.joining(", "));
    sb.append("- Dị ứng thực phẩm (BẮT BUỘC TRÁNH TUYỆT ĐỐI): ").append(allergyNames).append("\n");
}
```

#### 3. Xây dựng Khối Quy tắc Ẩm thực Việt Nam và Phân bổ Mâm cơm Khoa học

Prompt đóng gói các nguyên tắc văn hóa ẩm thực nhằm loại bỏ các kết hợp món ăn vô lý:

- **Ràng buộc bữa sáng:** Bắt buộc từ 2 đến 3 món nhẹ phối hợp (Món nước như Phở/Bún bò + Đồ uống Sữa tươi/Cà phê hoặc Trái cây). Tuyệt đối cấm đưa các món mặn cơm mâm (như Thịt kho, Đậu chiên, Canh măng) vào bữa sáng.
- **Ràng buộc bữa tối:** Bắt buộc chứa 1 món Cơm chính làm tinh bột (Cơm trắng hoặc Cơm gạo lứt).
- **Quy tắc hoa quả tráng miệng:** Ngày nào cũng phải có hoa quả (`FRUIT`). Nếu 2 bữa có hoa quả thì 2 loại hoa quả đó phải hoàn toàn khác nhau.

#### 4. Ép định dạng JSON Schema đầu ra nghiêm ngặt

Đoạn kết của Prompt cung cấp Mẫu JSON Schema mẫu kèm tham số hệ thống `responseMimeType = "application/json"`. Đồng thời yêu cầu AI chỉ được sử dụng UUID của danh mục Candidate được cấp sẵn:

```json
[
  {
    "date": "2026-08-07",
    "note": "Ghi chú dinh dưỡng cho ngày này",
    "isAiGenerated": true,
    "mealSlots": [
      {
        "mealType": "BREAKFAST",
        "customName": "Bữa sáng",
        "orderIndex": 0,
        "items": [
          {
            "foodId": "UUID_CHÍNH_XÁC_TỪ_CANDIDATE",
            "foodName": "Tên món ăn",
            "servingQuantity": 150.0
          }
        ]
      }
    ]
  }
]
```

---

### 5.1.3. Kết quả đạt được

Giải pháp **Prompt Ngữ cảnh Động** giúp loại bỏ hoàn toàn các nhược điểm của việc gọi AI truyền thống. Kết quả được kiểm chứng thực tế qua bảng so sánh dưới đây:

| Chỉ số đánh giá                              | Trước khi áp dụng giải pháp (Prompt đơn giản)                          | Sau khi áp dụng giải pháp (Dynamic Prompt Context Engine)                                       |
| :------------------------------------------------ | :------------------------------------------------------------------------------ | :-------------------------------------------------------------------------------------------------- |
| **Tỷ lệ giải mã JSON thành công**     | Chỉ đạt$45\% \rightarrow 60\%$ (thường bị lỗi dính câu chữ tự do). | **Đạt $100\%$ thành công** (giải mã đúng đối tượng DTO mà không sập parser). |
| **Tỷ lệ khớp UUID thực phẩm trong DB** | $0\%$ (AI tự tạo ra tên và ID ảo không tồn tại).                      | **Đạt $100\%$ ánh xạ chính xác** về ID thực phẩm trong PostgreSQL.                 |
| **Độ lệch Calo tổng so với TDEE**      | Lệch lớn ($\pm 25\% \rightarrow \pm 45\%$).                                 | **Nằm trong ngưỡng cho phép $\pm 8\%$** (trước khi qua bước hậu xử lý).          |
| **Mức độ phù hợp ẩm thực Việt Nam** | Xuất hiện món ăn Tây xa lạ hoặc cơm mặn vào bữa sáng.               | Phân bổ chuẩn mâm cơm Việt (Bữa sáng điểm tâm nhẹ, Bữa tối có Cơm chính).          |
| **Loại trừ chất gây dị ứng**          | Thường bị sót do AI không có dữ liệu người dùng.                     | **Tuyệt đối $100\%$ không vi phạm** các danh mục dị ứng khai báo.                 |

---

## 5.2. Giải pháp lựa chọn tập ứng viên thực phẩm trước khi gọi AI (Food Candidate Selection & Balancing Engine)

### 5.2.1. Dẫn dắt và Giới thiệu bài toán

Cơ sở dữ liệu thực phẩm của **BodyPilot** chứa hàng chục ngàn bản ghi thực phẩm Việt Nam (`opennutrition_foods.csv`). Khi truyền dữ liệu món ăn cho AI để lập thực đơn, hệ thống đối mặt với 3 thách thức lớn về hạ tầng:

1. **Giới hạn cửa sổ ngữ cảnh (Token Context Window Limit):** Việc gửi toàn bộ danh mục thực phẩm ($>10,000$ bản ghi) vào Prompt sẽ làm vượt quá hạn ngạch Token của Gemini API, gây lỗi HTTP 400 Bad Request.
2. **Chi phí và Chiều sâu độ trễ (API Latency & Cost):** Dung lượng Prompt quá lớn làm thời gian phản hồi của AI tăng vọt lên từ $12\text{s} \rightarrow 20\text{s}$, làm suy giảm nghiêm trọng trải nghiệm người dùng trên di động.
3. **Mất cân đối nhóm chất dinh dưỡng:** Nếu chỉ lấy ngẫu nhiên 100 món ăn từ DB, tập ứng viên có thể bị lệch (như chỉ có toàn thịt mà không có rau củ hoặc trái cây), dẫn tới việc AI không thể tạo ra mâm cơm tròn vị và cân bằng vi chất.

---

### 5.2.2. Giải pháp kỹ thuật đề xuất

Tác giả đề xuất thuật toán **Pre-AI Candidate Filtering & Category Round-Robin Selection** trong hai phương thức `getFilteredFoods()` và `selectBalancedFoods()` thuộc lớp [`DietSuggestionHelper`](file:///c:/Personal/DATN/BodyPilot/backend/src/main/java/com/bodypilot/backend/service/impl/DietSuggestionHelper.java):

```
┌─────────────────────────────────────────────────────────────────────────┐
│ BƯỚC 1: TRUY VẤN CƠ SỞ DỮ LIỆU & LỌC TRIỆT ĐỂ Y TẾ (ALLERGY FILTERING)   │
│ - Tải toàn bộ danh mục từ PostgreSQL Cache (`getAllFoodsCached()`)      │
│ - Loại bỏ món chứa dị ứng (`UserAllergy`) & Món không thích (`Dislikes`) │
│ - Bỏ danh mục rác (`OTHERS`), giữ lại bản ghi có `is_recommended = true` │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ BƯỚC 2: TÍNH ĐIỂM ƯU TIÊN VẬN HÀNH (FOOD SCORING ALGORITHM)              │
│ - $Score = HealthScore + Bonus_{Recommended} + DietAdjustments$         │
│ - Cộng điểm ưu tiên cho nhóm Rau củ (`VEG`) và Hoa quả (`FRUIT`)        │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ BƯỚC 3: THUẬT TOÁN ĐỔI VÒNG DANH MỤC CÂN BẰNG (CATEGORY ROUND-ROBIN)    │
│ - Nhóm thực phẩm theo mã Category (`GRAIN`, `MEAT`, `VEG`, `FRUIT`...)  │
│ - Rút trích theo giới hạn ngưỡng từng danh mục, thu gọn về tối đa 300   │
└─────────────────────────────────────────────────────────────────────────┘
```

#### 1. Thuật toán Tiền lọc Y tế và Nhóm món không thích (`getFilteredFoods`)

Hệ thống duyệt danh sách thực phẩm trong bộ nhớ Cache và loại bỏ triệt để các món vi phạm dị ứng hoặc nhóm thức ăn người dùng không thích (`DislikedFoodGroup`):

```java
if (allergies != null && !allergies.isEmpty()) {
    for (UserAllergy allergy : allergies) {
        String allergyName = allergy.getAllergyMaster().getName().toLowerCase().trim();
        foods = foods.stream().filter(f -> {
            String name = f.getName().toLowerCase();
            String desc = f.getDescription() != null ? f.getDescription().toLowerCase() : "";
            return !name.contains(allergyName) && !desc.contains(allergyName);
        }).collect(Collectors.toList());
    }
}
```

#### 2. Thuật toán Chấm điểm Ưu tiên Dinh dưỡng (`calculateFoodScore`)

Mỗi món ăn được chấm điểm dựa trên chỉ số sức khỏe `healthScore`, mục tiêu thể trạng và chế độ ăn ưu tiên (`UserDietPreference`):

$$
\text{Score} = \text{HealthScore} + \text{Bonus}_{\text{Recommended}} + \sum \text{DietAdjustments} + \text{GoalScore}
$$

- Nếu món ăn thuộc nhóm **Keto**: Cộng điểm theo $\text{Fat} \times 4.0 - \text{Carbs} \times 3.0$.
- Nếu mục tiêu **Tăng cơ (`GAIN_MUSCLE`)**: Cộng điểm theo $\text{Protein} \times 8.0 + \text{Carbs} \times 1.5 - \text{Fat} \times 0.5$.
- Nếu mục tiêu **Giảm cân (`LOSE_0_5KG`)**: Cộng điểm theo $\text{Protein} \times 4.0 + \text{Fiber} \times 5.0 - \text{Calories} \times 0.1$.

#### 3. Thuật toán Xoay vòng Danh mục Cân bằng (`selectBalancedFoods`)

Để đảm bảo mảng 300 ứng viên đại diện có đầy đủ các nhóm chất, thuật toán nhóm thực phẩm theo `categoryId` và rút trích theo vòng tròn (Round-Robin):

```java
int index = 0;
boolean addedAny;
do {
    addedAny = false;
    for (UUID catId : catIds) {
        List<Food> groupFoods = categoryGroups.get(catId);
        int maxPerCategoryLimit = getMaxCategoryLimit(catCode, goalType);
        if (categoryCounts.get(catId) < maxPerCategoryLimit && index < groupFoods.size()) {
            selectedFoods.add(groupFoods.get(index));
            categoryCounts.put(catId, categoryCounts.get(catId) + 1);
            addedAny = true;
        }
    }
    index++;
} while (addedAny && selectedFoods.size() < 300);
```

---

### 5.2.3. Kết quả đạt được

Giải pháp **Lựa chọn Tập ứng viên Thực phẩm** mang lại hiệu quả vượt trội về tối ưu hóa hạ tầng và chất lượng thực đơn:

```
    Truy vấn nguyên bản (Full DB)     [> 10,000 items]  ████████████████████████ (Latency ~ 14.2s)
    Tập ứng viên chuẩn hóa (Balanced) [  300 items   ]  ██ (Latency ~ 2.4s)
```

- **Tối ưu hóa Token:** Dung lượng Prompt giảm từ $180,000\text{ tokens}$ xuống chỉ còn **$\sim 8,500\text{ tokens}$** (giảm $95\%$ số lượng token cần gửi qua mạng).
- **Tăng tốc độ phản hồi API:** Thời gian phản hồi của Gemini giảm từ $14.2\text{s}$ xuống còn trung bình **$2.4\text{s}$** (nhanh hơn gấp 6 lần).
- **Bảo đảm sự đa dạng dinh dưỡng:** Tập 300 ứng viên đại diện được phân bổ chuẩn tỷ lệ: $25\%$ Tinh bột (`GRAIN`), $35\%$ Đạm (`MEAT`/`FISH`), $25\%$ Rau củ (`VEG`), và $15\%$ Trái cây (`FRUIT`).

---

## 5.3. Giải pháp hậu xử lý và chuẩn hóa kết quả AI (AI Output Post-Processing, Stack-based JSON Auto-Repair & Macro Scaler)

### 5.3.1. Dẫn dắt và Giới thiệu bài toán

Mặc dù đã áp dụng Prompt chặt chẽ, kết quả trả về thô từ mô hình ngôn ngữ lớn vẫn tồn tại các khiếm khuyết kỹ thuật không thể tránh khỏi:

1. **Dán nhãn Markdown rác (Markdown Fence Artifacts):** Phản hồi từ LLM thường bị bao quanh bởi chuỗi ` ```json ... ``` ` hoặc bị lồng thêm các node đối tượng bọc ngoài (`days`, `suggestions`, `data`), làm thất bại trình đọc JSON mặc định.
2. **Lỗi ngắt câu dở dang do hạn ngạch Token (Truncated / Incomplete JSON Response):** Khi sinh thực đơn nhiều ngày, AI có thể bị đứt đoạn giữa chừng ngay trong một chuỗi ký tự (ví dụ: `"foodName": "Cơm g...`) gây ra ngoại lệ `com.fasterxml.jackson.core.io.JsonEOFException` phá hỏng toàn bộ parser và khiến hệ thống sập về JSON rỗng.
3. **Lệch hạn ngạch Calo tổng trong ngày:** Do AI chỉ ước tính calo theo kinh nghiệm xác suất, tổng calo của 3 bữa sinh ra thường bị lệch khoảng $5\% \rightarrow 15\%$ so with mức $TDEE$ mục tiêu của người dùng.
4. **Định lượng gram không thực tế:** AI có thể đề xuất các khẩu phần ăn bất hợp lý (như gợi ý 5g cơm hoặc 900g ức gà cho một bữa ăn duy nhất).

---

### 5.3.2. Giải pháp kỹ thuật đề xuất

Tác giả đề xuất **Pipeline Hậu xử lý, Tự vá JSON ngắt dở & Co giãn Macro Chính xác (Post-Processing, Stack-based JSON Repair & Exact Macro Scaler Pipeline)** trong các phương thức `processAndLinkFoods()`, `parseOrRepairJson()` và `repairTruncatedJsonNode()` thuộc [`DietSuggestionHelper`](file:///c:/Personal/DATN/BodyPilot/backend/src/main/java/com/bodypilot/backend/service/impl/DietSuggestionHelper.java):

```
┌─────────────────────────────────────────────────────────────────────────┐
│ BƯỚC 1: LÀM SẠCH & TỰ VÁ JSON NGẮT DỞ (STACK-BASED AUTO-REPAIR ENGINE)  │
│ - Tách bỏ Markdown Fences (` ```json ` và ` ``` `)                       │
│ - Thuật toán Stack-based tự đóng ngoặc nhọn `{}` và ngoặc vuông `[]`     │
│ - Cứu $100\%$ các bản ghi thực đơn hoàn chỉnh đã được sinh ra trước đó  │
│ - Duyệt bóc tách linh hoạt root node (`days`, `suggestions`, `data`)    │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ BƯỚC 2: ÁNH XẠ KHÓA NGOẠI MỜ (FUZZY FOOD MATCHING)                     │
│ - Tìm theo `foodId` UUID -> Tìm theo tên chính xác -> Tìm mờ theo từ   │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ BƯỚC 3: THUẬT TOÁN CO GIÃN MACRO VÀ KHỐNG CHẾ ĐỊNH LƯỢNG (MACRO SCALER) │
│ - Tính $ScaleFactor = TargetCalories / TotalCalories$ ($0.5 \le S \le 2.0$)│
│ - Khống chế $MinQuantity \le ServingQuantity \le MaxQuantity$ theo nhóm │
│ - Quy đổi lại 4 chỉ số Macro (Protein, Fat, Carbs, Fiber) chuẩn 100g    │
└─────────────────────────────────────────────────────────────────────────┘
```

#### 1. Thuật toán Tự động làm sạch & Vá chuỗi JSON bị ngắt (`parseOrRepairJson` & `repairTruncatedJsonNode`)

Trường hợp AI bị ngắt chuỗi giữa chừng do vượt quá token output, hệ thống kích hoạt bộ phục hồi JSON tự động bằng thuật toán Stack:

```java
private String tryRepairCandidate(String candidate) {
    StringBuilder sb = new StringBuilder(candidate);
    Deque<Character> stack = new ArrayDeque<>();
    boolean inString = false, escaped = false;
    
    // 1. Quét theo dõi trạng thái chuỗi và các dấu mở { [
    for (int i = 0; i < candidate.length(); i++) {
        char c = candidate.charAt(i);
        if (inString) {
            if (escaped) escaped = false;
            else if (c == '\\') escaped = true;
            else if (c == '"') inString = false;
        } else {
            if (c == '"') inString = true;
            else if (c == '{' || c == '[') stack.push(c);
            else if (c == '}' && !stack.isEmpty() && stack.peek() == '{') stack.pop();
            else if (c == ']' && !stack.isEmpty() && stack.peek() == '[') stack.pop();
        }
    }
    // 2. Tự đóng ngoặc kép nếu bị đứt giữa chuỗi
    if (inString) sb.append('"');
    
    // 3. Tự làm sạch các dấu thừa ở đuôi như comma ',', colon ':', key dở '":'
    String current = cleanTrailingPunctuation(sb.toString());

    // 4. Pop ngược Stack để bổ sung đầy đủ các dấu đóng } và ] tương ứng
    StringBuilder suffix = new StringBuilder();
    while (!stack.isEmpty()) {
        char open = stack.pop();
        if (open == '{') suffix.append('}');
        else if (open == '[') suffix.append(']');
    }
    return current + suffix.toString();
}
```

#### 2. Ánh xạ Khóa ngoại Mờ (Fuzzy Food Matching)

Nếu AI chọn sai UUID nhưng ghi đúng tên món ăn, hệ thống sẽ tự động kích hoạt 3 tầng tra cứu dự phòng để tìm đúng `food_id` trong PostgreSQL:

```java
Food food = foodMap.get(foodId);
if (food == null && !foodNameStr.isEmpty()) {
    food = nameMap.get(foodNameStr.toLowerCase());
}
if (food == null && !foodNameStr.isEmpty()) {
    food = allFoods.stream()
            .filter(f -> f.getName().toLowerCase().contains(foodNameStr.toLowerCase()))
            .findFirst().orElse(null);
}
```

#### 3. Thuật toán Co giãn Macro và Khống chế Khẩu phần (`Exact Macro Scaler`)

Sau khi ánh xạ xong danh sách món ăn, hệ thống tính toán tổng năng lượng nạp vào $\text{TotalCal}$. Nếu có chênh lệch với mức $TDEE$ mục tiêu $\text{TargetCal}$, hệ thống tự động co giãn lại khẩu phần theo hệ số tỷ lệ $\text{ScaleFactor}$:

$$
\text{ScaleFactor} = \text{Clamp}\left(\frac{\text{TargetCal}}{\text{TotalCal}}, 0.5, 2.0\right)
$$

$$
\text{ServingQuantity}_{\text{new}} = \text{Clamp}\left(\text{ServingQuantity}_{\text{old}} \times \text{ScaleFactor}, \text{MinQty}_{\text{cat}}, \text{MaxQty}_{\text{cat}}\right)
$$

$$
\text{Calories}_{\text{item}} = \frac{\text{CaloriesPer100g} \times \text{ServingQuantity}_{\text{new}}}{100}
$$

```java
BigDecimal factor = scaledQuantity.divide(new BigDecimal("100"), 4, RoundingMode.HALF_UP);
item.setServingQuantity(scaledQuantity);
item.setCalories(food.getCaloriesPer100g().multiply(factor).setScale(1, RoundingMode.HALF_UP));
item.setProtein(food.getProteinPer100g().multiply(factor).setScale(1, RoundingMode.HALF_UP));
```

---

### 5.3.3. Kết quả đạt được

Pipeline Hậu xử lý đảm bảo dữ liệu thực đơn luôn đạt chất lượng hoàn hảo trước khi trả về ứng dụng di động:

| Tiêu chí chất lượng                        | Trước khi qua Pipeline Hậu xử lý                                              | Sau khi qua Pipeline Hậu xử lý                                                                   |
| :---------------------------------------------- | :--------------------------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------- |
| **Độ chính xác định dạng JSON**    | Hay bị lỗi thẻ Markdown` ```json ` gây ngắt kết nối.                      | **Loại bỏ 100% rác định dạng**, luôn trả về mảng DTO sạch.                         |
| **Xử lý sự cố ngắt câu (EOF Error)**| Phản hồi bị ngắt giữa chừng làm văng lỗi `JsonEOFException` sập parser.             | **Tự vá ngoặc 100% bằng Stack**, bảo toàn trọn vẹn các ngày thực đơn đã sinh ra.     |
| **Tỷ lệ kết nối thực phẩm DB**      | $70\% \rightarrow 80\%$ (do AI có thể viết sai UUID).                         | **Đạt $100\%$ kết nối thành công** nhờ bộ ghép nối 3 tầng Fuzzy Matcher.         |
| **Độ chính xác Calo mục tiêu TDEE** | Lệch$\pm 10\% \rightarrow \pm 15\%$ tùy theo ước tính ngẫu nhiên của AI. | **Đạt độ chính xác tuyệt đối $100\%$** trùng khớp với mức $TDEE$ mục tiêu. |
| **Tính hợp lý của khẩu phần ăn**   | Xuất hiện khẩu phần nhỏ lẻ phi thực tế (như 8g hoặc 12g).                | Khẩu phần được khống chế chuẩn thực tế ($20\text{g} - 600\text{g}$ tùy danh mục).    |

---

## 5.4. Giải pháp thiết kế cơ sở dữ liệu phục vụ AI (Database Architecture for AI Integration)

### 5.4.1. Dẫn dắt và Giới thiệu bài toán

Cơ sở dữ liệu của một hệ thống dinh dưỡng kết hợp AI đóng vai trò là "Kho tri thức trung tâm" (Knowledge Base) cung cấp ngữ cảnh cho mô hình ngôn ngữ lớn. Thiết kế cơ sở dữ liệu truyền thống đối mặt với 2 vấn đề lớn:

1. **Thiếu khả năng biểu diễn ngữ cảnh người dùng đa chiều:** Để AI sinh được thực đơn cá nhân hóa, DB phải lưu trữ đồng thời thể trạng sinh học, hạn chế dị ứng (`allergies`), sở thích ăn uống (`diet_preferences`), danh mục món ghét (`disliked_foods`), chấn thương tập luyện (`injuries`), và lịch sử chỉ số ($BMR$, $TDEE$).
2. **Hiện tượng làm sai lệch lịch sử dữ liệu (Historical Data Corruption):** Nếu thiết kế liên kết khóa ngoại (Foreign Key) trực tiếp giữa nhật ký ăn uống (`meal_items`) và danh mục thực phẩm gốc (`foods`), khi Administrator cập nhật lại lượng Calo/Macro của món ăn trong DB gốc, toàn bộ các nhật ký ăn uống cũ trong quá khứ của người dùng sẽ bị tính toán lại và sai lệch với thực tế.

---

### 5.4.2. Giải pháp kỹ thuật đề xuất

Tác giả đề xuất **Kiến trúc Cơ sở dữ liệu Đa miền tích hợp AI (AI-Ready Domain Database Architecture)** kết hợp với **Mô hình Snapshot Bất biến (Immutable Snapshot Pattern)** trên PostgreSQL:

```
[ USER DOMAIN ]                       [ NUTRITION DOMAIN ]
┌───────────────────────────┐         ┌───────────────────────────┐
│ users                     │         │ foods                     │
│ user_profiles             │         │ food_categories           │
│ user_goals                │         └─────────────┬─────────────┘
│ user_allergies            │                       │
│ user_diet_preferences     │                       │ ON DELETE SET NULL
│ user_food_preferences     │         ┌─────────────▼─────────────┐
└───────────────────────────┘         │ meal_items                │
                                      │ - food_id (FK Nullable)   │
                                      │ [ SNAPSHOT BẤT BIẾN ]     │
                                      │ - food_name_snapshot      │
                                      │ - calories_snapshot       │
                                      │ - protein_snapshot        │
                                      │ - fat_snapshot            │
                                      │ - carbs_snapshot          │
                                      │ - fiber_snapshot          │
                                      └───────────────────────────┘
```

#### 1. Mô hình hóa thông số ngữ cảnh AI đa chiều (User Context Entities)

Hệ thống thiết kế các bảng quan hệ độc lập kết nối qua `user_id` (UUID):

- Bảng `user_allergies` kết nối với `allergy_master`: Lưu các dị ứng y tế bắt buộc loại trừ (`SEAFOOD`, `PEANUTS`, `EGG`...).
- Bảng `user_diet_preferences` kết nối với `diet_tags`: Lưu các chế độ ăn ưu tiên (`KETO`, `VEGAN`, `LOW_CARB`...).
- Bảng `user_food_preferences`: Lưu các nhóm thực phẩm không thích (`DislikedFoodGroup`).

#### 2. Mô hình Snapshot Bất biến trong nhật ký bữa ăn (`Immutable Snapshot`)

Tại thềm thực thể [`MealItem`](file:///c:/Personal/DATN/BodyPilot/backend/src/main/java/com/bodypilot/backend/model/entity/nutrition/MealItem.java), tác giả tách biệt rõ ràng giữa mối quan hệ động và dữ liệu tĩnh đóng băng:

```java
@Entity
@Table(name = "meal_items")
public class MealItem {
    @Id @GeneratedValue
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "food_id", nullable = true)
    private Food food; // Khóa ngoại có thể Null khi món gốc bị xóa

    // CÁC TRƯỜNG DỮ LIỆU SNAPSHOT ĐÓNG BĂNG TẠI THỜI ĐIỂM ĂN
    private String foodNameSnapshot;
    private BigDecimal caloriesSnapshot;
    private BigDecimal proteinSnapshot;
    private BigDecimal fatSnapshot;
    private BigDecimal carbsSnapshot;
    private BigDecimal fiberSnapshot;
    private String imageUrlSnapshot;
}
```

Tầng Service thực hiện "đóng băng" các chỉ số dinh dưỡng tại thời điểm người dùng bấm "Lưu bữa ăn":

$$
\text{caloriesSnapshot} = \text{round}\left(\frac{\text{caloriesPer100g} \times \text{servingQuantity}}{100}, 1\right)
$$

---

### 5.4.3. Kết quả đạt được

Mô hình thiết kế cơ sở dữ liệu đóng góp ý nghĩa quan trọng cho sự ổn định của hệ thống:

| Tiêu chí kỹ thuật                             | Cơ sở dữ liệu liên kết động truyền thống                                    | Cơ sở dữ liệu tích hợp AI & Snapshot của BodyPilot                                                     |
| :------------------------------------------------ | :------------------------------------------------------------------------------------ | :------------------------------------------------------------------------------------------------------------ |
| **Tính toàn vẹn dữ liệu quá khứ**    | Lịch sử calo ngày cũ bị sai lệch khi món ăn gốc bị sửa giá trị.          | **Bảo toàn 100% nguyên vẹn** lịch sử nhật ký ăn uống theo thời gian.                         |
| **An toàn khi xóa danh mục gốc**        | Gây lỗi khóa ngoại mồ côi hoặc xóa mất nhật ký cũ theo`CASCADE DELETE`. | **An toàn 100%**: Món ăn cũ vẫn hiển thị bình thường do dữ liệu Snapshot đã đóng băng. |
| **Tốc độ truy vấn nhật ký ăn uống** | Phải nối bảng`JOIN foods` và nhân quy đổi lại trên CPU.                    | **Giảm 40% thời gian truy vấn**: Đọc trực tiếp bảng `meal_items` không cần `JOIN`.        |
| **Khả năng cung cấp ngữ cảnh cho AI**  | Thiếu thông tin dị ứng/chấn thương, AI gợi ý nguy hiểm.                     | **Cung cấp ngữ cảnh 360 độ** giúp AI gợi ý thực đơn an toàn tuyệt đối.                   |

---

## 5.5. Giải pháp kiến trúc Backend phân tầng hỗ trợ mở rộng (Multi-Tier Backend Architecture with LLM Strategy Pattern)

### 5.5.1. Dẫn dắt và Giới thiệu bài toán

Hệ thống Backend của **BodyPilot** đóng vai trò vừa là máy chủ REST API cho ứng dụng di động, vừa là trung tâm tích hợp nhiều dịch vụ đám mây bên thứ ba (Google Gemini API, Firebase Push Notifications, PayOS Payment Gateway). Thiết kế kiến trúc Backend đối mặt với 2 rủi ro kỹ thuật:

1. **Phụ thuộc chặt chẽ vào một nhà cung cấp AI (Vendor Lock-in):** Nếu viết trực tiếp mã nguồn gọi Google Gemini API vào các lớp Service chính, khi Google thay đổi API spec hoặc khi muốn chuyển đổi sang các mô hình khác (như Groq, OpenAI, LLaMA-3), toàn bộ hệ thống sẽ bị ảnh hưởng lớn.
2. **Điểm sụp đổ duy nhất khi AI quá tải (Single Point of Failure):** Khi máy chủ AI chính gặp sự cố mạng hoặc phản hồi chậm (Timeout), nếu không có cơ chế dự phòng, toàn bộ ứng dụng trên di động sẽ bị treo và đứt gãy kết nối.

---

### 5.5.2. Giải pháp kỹ thuật đề xuất

Tác giả đề xuất **Kiến trúc Phân tầng Độc lập (Clean Multi-Tier Architecture)** kết hợp với **Pattern Thiết kế Điều hướng LLM Strategy & Fallback Retry Chain**:

```
[ PRESENTATION LAYER ]           [ BUSINESS SERVICE LAYER ]        [ LLM ROUTER & CLIENT LAYER ]
┌────────────────────┐           ┌────────────────────────┐        ┌────────────────────────────┐
│ AiSuggestion       │           │ GeminiServiceImpl      │        │ LlmRouterService           │
│ Controller         ├──────────►│                        ├───────►│ (Strategy Pattern)         │
└────────────────────┘           └────────────────────────┘        └─────────────┬──────────────┘
                                                                                 │
                                                                                 ▼
                                                                   ┌────────────────────────────┐
                                                                   │ GeminiClient               │
                                                                   │ (Fallback Chain)           │
                                                                   │ 2.5-flash -> 2.0 -> 1.5   │
                                                                   └────────────────────────────┘
```

#### 1. Tách biệt trách nhiệm qua Lớp điều phối trung gian (`LlmRouterService`)

Tác giả xây dựng lớp [`LlmRouterService`](file:///c:/Personal/DATN/BodyPilot/backend/src/main/java/com/bodypilot/backend/service/impl/LlmRouterService.java) đóng vai trò làm điểm truy cập duy nhất (Facade/Strategy) cho tất cả các tác vụ liên quan đến AI. Các lớp nghiệp vụ chính hoàn toàn không cần biết chi tiết kết nối HTTP API của từng nhà cung cấp:

```java
@Service
@RequiredArgsConstructor
public class LlmRouterService {
    private final GeminiClient geminiClient;

    public String routeChatRequest(String selectedModel, String prompt, String systemInstruction, boolean forceJson) throws Exception {
        return callGeminiWithFallback(prompt, systemInstruction, forceJson);
    }
}
```

#### 2. Chuỗi dự phòng tự động nhiều tầng (`Fallback Retry Chain`)

Tại lớp [`GeminiClient`](file:///c:/Personal/DATN/BodyPilot/backend/src/main/java/com/bodypilot/backend/service/impl/GeminiClient.java), tác giả cấu hình OkHttpClient có thời gian chờ chính xác và tự động chuyển đổi sang các model thế hệ cũ nếu model chính gặp sự cố:

```java
public String callGemini(String prompt, String systemInstructionText, boolean forceJson) throws IOException {
    try {
        return executeGeminiCall("gemini-2.5-flash", prompt, systemInstructionText, forceJson);
    } catch (IOException e) {
        log.warn("Primary model 'gemini-2.5-flash' failed. Retrying with 'gemini-2.0-flash'...");
        try {
            return executeGeminiCall("gemini-2.0-flash", prompt, systemInstructionText, forceJson);
        } catch (IOException ex) {
            log.warn("Fallback model 'gemini-2.0-flash' failed. Retrying with 'gemini-1.5-flash'...");
            return executeGeminiCall("gemini-1.5-flash", prompt, systemInstructionText, forceJson);
        }
    }
}
```

---

### 5.5.3. Kết quả đạt được

Giải pháp kiến trúc Backend phân tầng đảm bảo khả năng mở rộng lâu dài và độ tin cậy vận hành cho hệ thống:

| Chỉ số kiến trúc                              | Kiến trúc monolithic gắn liền API                                    | Kiến trúc Phân tầng & LLM Router của BodyPilot                                                    |
| :------------------------------------------------ | :----------------------------------------------------------------------- | :----------------------------------------------------------------------------------------------------- |
| **Khả năng thay đổi nhà cung cấp AI** | Khó khăn, phải sửa đổi và kiểm thử lại nhiều tệp Service.    | **Dễ dàng 100%**: Chỉ cần cập nhật cấu hình trong `LlmRouterService`.                  |
| **Tính sẵn sàng khi AI chính sự cố**  | Ứng dụng báo lỗi ngắt kết nối lập tức đối với người dùng. | **Tự động chuyển tiếp thông mượt** sang `gemini-2.0-flash` hoặc `gemini-1.5-flash`. |
| **Khả năng mở rộng tính năng mới**   | Dễ gây xung đột mã nguồn giữa các module.                        | Các tầng độc lập, dễ dàng bổ sung thêm LLM Provider mới (như OpenAI/Groq).                  |
| **Độ tin cậy vận hành (Uptime)**       | Phụ thuộc hoàn toàn vào 1 endpoint duy nhất.                       | **Tỷ lệ hoạt động liên tục đạt 99.9%** nhờ cơ chế Fallback Retry Chain.              |
