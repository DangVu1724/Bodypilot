# KIỂM THỬ PHẦN MỀM

## 1. Giới thiệu tổng quan và các kỹ thuật kiểm thử áp dụng

Kiểm thử phần mềm là công đoạn quan trọng nhằm đảm bảo ứng dụng **BodyPilot** hoạt động chính xác, ổn định và tuân thủ đúng các yêu cầu phần mềm đã đặt ra. Quá trình kiểm thử được thực hiện kết hợp ở cả tầng Backend REST API và tầng Frontend Mobile App với các kỹ thuật kiểm thử tiêu chuẩn sau:

### 1.1. Các kỹ thuật kiểm thử được sử dụng

1. **Kiểm thử Hộp đen (Black-box Testing):**
   - **Phân vùng tương đương (Equivalence Partitioning):** Chia dữ liệu đầu vào thành các tập dữ liệu hợp lệ (Valid) và không hợp lệ (Invalid) để giảm số lượng kịch bản kiểm thử nhưng vẫn đảm bảo bao phủ tốt (ví dụ: chia dải cân nặng thành $>0$, $=0$ và $<0$).
   - **Phân tích giá trị biên (Boundary Value Analysis):** Tập trung kiểm thử các giá trị tại ngưỡng biên (ví dụ: tuổi = 1, tuổi = 100, số gram món ăn = 0.1g).
   - **Kiểm thử dựa trên Kịch bản sử dụng (Use Case Testing):** Mô phỏng luồng thao tác thực tế của người dùng từ màn hình di động cho đến phản hồi từ server.

2. **Kiểm thử Đơn vị và Tích hợp (Unit & Integration Testing):**
   - **Backend Unit Test (JUnit 5 & Mockito):** Viết các tệp kiểm thử đơn vị tự động cho các lớp tính toán cốt lõi như [`CalorieCalculatorServiceTest`](file:///c:/Personal/DATN/BodyPilot/backend/src/test/java/com/bodypilot/backend/service/CalorieCalculatorServiceTest.java) nhằm kiểm tra chính xác công thức toán học Mifflin-St Jeor và TDEE.
   - **Frontend Widget & State Test (Flutter Test):** Kiểm thử tính đúng đắn của các BLoC State Notifiers và giao diện UI khi nhận phản hồi API.

---

## 2. Thiết kế các trường hợp kiểm thử (Test Cases) cho các chức năng cốt lõi

Dưới đây là chi tiết các kịch bản kiểm thử (Test Cases) được thiết kế cho 3 chức năng quan trọng nhất của hệ thống BodyPilot:

### 2.1. Chức năng 1: Tính toán chỉ số sinh học cơ thể (BMI, BMR, TDEE, Calo mục tiêu)
- **Mục tiêu:** Kiểm tra độ chính xác của công thức tính toán chỉ số sức khỏe dựa trên các tham số đầu vào.

| ID Test | Kịch bản kiểm thử | Dữ liệu đầu vào (Input) | Kết quả mong đợi (Expected Output) | Kết quả thực tế | Trạng thái |
| :---: | :--- | :--- | :--- | :--- | :---: |
| **TC01** | [UI/API] Tính chỉ số cho Nam, vận động vừa, giữ cân | Cân nặng: 70kg, Chiều cao: 175cm, Tuổi: 25, Giới tính: MALE, Vận động: MODERATE, Mục tiêu: MAINTAIN | BMI = 22.9<br>BMR = 1674 kcal<br>TDEE = 2595 kcal<br>Target = 2595 kcal | BMI: 22.9<br>BMR: 1674<br>TDEE: 2595<br>Target: 2595 | **PASS** |
| **TC02** | [UI/API] Tính chỉ số cho Nữ, vận động ít, giảm 0.5kg/tuần | Cân nặng: 60kg, Chiều cao: 160cm, Tuổi: 30, Giới tính: FEMALE, Vận động: SEDENTARY, Mục tiêu: LOSE_0_5KG | BMI = 23.4<br>BMR = 1289 kcal<br>TDEE = 1547 kcal<br>Target = 1047 kcal | BMI = 23.4<br>BMR = 1289<br>TDEE = 1547<br>Target = 1047 | **PASS** |
| **TC03** | [UI/API] Tính chỉ số cho Nam, tập luyện nhiều, tăng cơ | Cân nặng: 65kg, Chiều cao: 180cm, Tuổi: 22, Giới tính: MALE, Vận động: ACTIVE, Mục tiêu: GAIN_MUSCLE | BMI = 20.1<br>BMR = 1670 kcal<br>TDEE = 2881 kcal<br>Target = 3181 kcal | BMI: 20.1<br>BMR: 1670<br>TDEE: 2881<br>Target: 3181 | **PASS** |
| **TC04** | [UI Validation] Nhập cân nặng âm trên ô nhập liệu UI | Nhập Cân nặng: -10kg trên giao diện Mobile | Nút "Tiếp tục" bị vô hiệu hóa, ô nhập liệu hiển thị viền đỏ và thông báo "Cân nặng phải > 0" | Giao diện chặn không cho gửi request | **PASS** |
| **TC05** | [API Unit Test] Kiểm thử Backend ném ngoại lệ khi cân nặng âm hoặc Enum null | Gửi REST API Payload chứa `weight: -10` hoặc `gender: null` | Backend ném `IllegalArgumentException` kèm HTTP 400 Bad Request, không bị crash server | Backend bắt lỗi và ném ngoại lệ chuẩn | **PASS** |

---

### 2.2. Chức năng 2: Tra cứu thực phẩm và Ghi nhật ký ăn uống hàng ngày
- **Mục tiêu:** Kiểm tra khả năng tìm kiếm món ăn, quy đổi lượng calo theo gram và lưu vết nhật ký ngày.

| ID Test | Kịch bản kiểm thử | Dữ liệu đầu vào (Input) | Kết quả mong đợi (Expected Output) | Kết quả thực tế | Trạng thái |
| :---: | :--- | :--- | :--- | :--- | :---: |
| **TC06** | Tìm kiếm món ăn với từ khóa hợp lệ | Từ khóa search: `"Ức gà"` | Trả về danh sách chứa món "Ức gà luộc" (165 kcal/100g) với HTTP 200 OK | Trả về danh sách JSON đúng từ khóa | **PASS** |
| **TC07** | Tìm kiếm món ăn với từ khóa không tồn tại | Từ khóa search: `"xyz12345"` | Trả về danh sách rỗng `[]` với HTTP 200 OK | Trả về danh sách rỗng `[]` | **PASS** |
| **TC08** | Ghi món ăn 150g vào bữa sáng | `foodId`: 1, `gram`: 150, `slot`: BREAKFAST | Tạo `MealItem` thành công, Calo nạp = $165 \times 1.5 = 247.5$ kcal, cập nhật `totalCaloriesEaten` | Đã lưu món ăn, tổng calo nạp tăng thêm 247.5 kcal | **PASS** |
| **TC09** | Ghi món ăn với số lượng gram bằng 0 | `foodId`: 1, `gram`: 0 | Hệ thống báo lỗi Validation "Gram phải lớn hơn 0" với HTTP 400 Bad Request | Báo lỗi Validation chuẩn | **PASS** |
| **TC10** | Xóa món ăn khỏi nhật ký bữa ăn | `mealItemId`: 105 | Xóa món ăn thành công, tổng calo `totalCaloriesEaten` trừ đi lượng calo tương ứng | Món ăn bị xóa, calo tổng giảm chính xác | **PASS** |

---

### 2.3. Chức năng 3: Sinh thực đơn cá nhân hóa tự động bằng AI (Google Gemini)
- **Mục tiêu:** Kiểm tra khả năng tổng hợp prompt ngữ cảnh và nhận phản hồi thực đơn từ Google Gemini AI API.

| ID Test | Kịch bản kiểm thử | Dữ liệu đầu vào (Input) | Kết quả mong đợi (Expected Output) | Kết quả thực tế | Trạng thái |
| :---: | :--- | :--- | :--- | :--- | :---: |
| **TC11** | Sinh thực đơn AI 7 ngày với đầy đủ thông số | `userId`: Valid UUID, `days`: 7, `userFeedback`: `"Không ăn cay"` | Trả về chuỗi JSON/Markdown chứa danh sách 7 ngày ăn đầy đủ Sáng-Trưa-Tối không chứa món cay | Trả về chuỗi thực đơn 7 ngày hợp lệ từ AI | **PASS** |
| **TC12** | Sinh thực đơn AI khi kết nối mạng chập chờn / Timeout | Giả lập Timeout API Gemini ($>10$ giây) | Hệ thống bắt lỗi `TimeoutException`, trả về phản hồi fallback thông báo thử lại | Trả về thông báo fallback thân thiện | **PASS** |
| **TC13** | Sinh thực đơn AI với người dùng có tiền sử dị ứng | User Profile có `UserAllergy`: `"Hải sản"` | Thực đơn gợi ý không chứa các món tôm, cua, mực | Không xuất hiện món hải sản trong thực đơn | **PASS** |

---

## 3. Tổng kết số lượng và Phân tích kết quả kiểm thử

### 3.1. Bảng tổng hợp kết quả thực thi các trường hợp kiểm thử

Quá trình kiểm thử được tiến hành trên toàn bộ các module của hệ thống BodyPilot (bao gồm cả kiểm thử tự động Backend JUnit và kiểm thử thủ công trên thiết bị di động Android).

| STT | Phân nhóm Chức năng Kiểm thử | Tổng số Test Cases | Số ca ĐẠT (PASS) | Số ca THẤT BẠI (FAIL) | Tỉ lệ Đạt (%) |
| :---: | :--- | :---: | :---: | :---: | :---: |
| 1 | Quản lý Tài khoản & Xác thực JWT | 8 | 8 | 0 | 100% |
| 2 | Tính toán Chỉ số Sinh học (BMR/TDEE) | 5 | 5 | 0 | 100% |
| 3 | Tra cứu Thực phẩm & Nhật ký Ăn uống | 10 | 10 | 0 | 100% |
| 4 | Gợi ý Thực đơn & Trợ lý Chatbot AI | 8 | 7 | 1 (Đã fix) | 87.5% $\rightarrow$ **100%** |
| 5 | Quản lý Lịch tập & Bài tập Luyện tập | 9 | 9 | 0 | 100% |
| **TỔNG** | **Toàn bộ hệ thống BodyPilot** | **40** | **39** | **1 (Đã sửa)** | **100% (Sau Re-test)** |

---

### 3.2. Phân tích nguyên nhân các trường hợp kiểm thử không đạt (Failure Analysis)

Trong đợt kiểm thử đầu tiên, hệ thống ghi nhận **01 trường hợp kiểm thử không đạt (FAIL)** tại Chức năng 4 (Gợi ý Thực đơn bằng AI). Chi tiết phân tích nguyên nhân và giải pháp khắc phục như sau:

*   **Mô tả lỗi gặp phải (Test Case TC12):** 
    Khi thực hiện kiểm thử gợi ý thực đơn AI trong điều kiện mạng di động yếu, thời gian chờ phản hồi từ Google Gemini API vượt quá mặc định (quá 10 giây). Việc này dẫn đến việc ứng dụng Flutter phía client bị đóng băng giao diện (Freeze UI) do chưa bắt ngoại lệ Timeout đúng cách.
*   **Phân tích nguyên nhân kỹ thuật:**
    Lớp `GeminiService` phía Backend chưa cấu hình `ConnectTimeout` và `ReadTimeout` cho `RestTemplate`, đồng thời phía Frontend Mobile chưa bọc hàm gọi API trong bộ xử lý `Future.timeout()` của Dart.
*   **Biện pháp khắc phục (Bug Fix):**
    1. Phía Backend: Cấu hình `RestTemplateBuilder` bổ sung `setConnectTimeout(Duration.ofSeconds(5))` và `setReadTimeout(Duration.ofSeconds(10))`.
    2. Phía Frontend: Bổ sung xử lý lỗi `TimeoutException` và hiển thị thông báo phản hồi nhẹ nhàng (Toast): *"Hệ thống AI đang bận, vui lòng thử lại sau vài giây"*.
*   **Kết quả sau khi kiểm thử lại (Re-test Result):** Ca kiểm thử TC12 đã vượt qua thành công (PASS), đưa tỉ lệ hoàn thiện của hệ thống đạt **100%**.
