# CHƯƠNG 4: THIẾT KẾ QUY TRÌNH NGHIỆP VỤ HỆ THỐNG BODYPILOT

---

## 4.1. Tổng quan về các Quy trình Nghiệp vụ Cốt lõi

Các quy trình nghiệp vụ (Business Workflows) đóng vai trò là xương sống vận hành của hệ thống **BodyPilot**. Không chỉ đơn thuần là luồng sự kiện của từng Use Case đơn lẻ, quy trình nghiệp vụ thể hiện sự phối hợp nhịp nhàng giữa nhiều Use Case, nhiều tầng kiến trúc (Mobile App Client, Backend Spring Boot Server, PostgreSQL Database, Meilisearch Engine, Firebase Services và Gemini AI Model) qua các khoảng thời gian khác nhau nhằm hoàn thành một mục tiêu toàn vẹn của người dùng.

Hệ thống **BodyPilot** bao gồm 5 Quy trình Nghiệp vụ Cốt lõi:

1. **Quy trình 1:** Đăng ký, Đánh giá Thể trạng Onboarding và Khởi tạo Lộ trình AI Cá nhân hóa.
2. **Quy trình 2:** Theo dõi Dinh dưỡng Hàng ngày, Ghi Nhật ký và Đổi món Thông minh (AI Smart Swap).
3. **Quy trình 3:** Theo dõi Luyện tập, Đếm bước chân Pedometer và Điểm danh Kiên trì (Daily Fitness & Streak Tracking Loop).
4. **Quy trình 4:** Trợ lý AI Coach Tư vấn & Điều chỉnh Thực đơn theo Phản hồi Người dùng (AI Coach Feedback Loop & Re-generation).
5. **Quy trình 5:** Quản trị Nội dung Danh mục Thực phẩm / Bài tập và Theo dõi Báo cáo (Admin Content Management & System Audit Workflow).

---

## 4.2. Chi tiết các Quy trình Nghiệp vụ và Biểu đồ Hoạt động (PlantUML Activity Diagrams)

### 4.2.1. Quy trình 1: Đăng ký, Đánh giá Thể trạng Onboarding và Khởi tạo Lộ trình AI Cá nhân hóa

#### 1. Mô tả chi tiết quy trình

Luồng nghiệp vụ phối hợp các Use Case: **UC01 (Xác thực tài khoản)**, **UC02 (Khảo sát thể trạng Onboarding)**, **UC02.3 (Tính toán chỉ số BMR/TDEE)**, **UC05 (Tạo thực đơn AI)** và **UC10 (Tạo lịch tập AI)**.

- **Khởi đầu:** Người dùng mở ứng dụng di động, thực hiện đăng ký tài khoản (qua Email/Password hoặc Google OAuth2).
- **Thu thập ngữ cảnh:** Người dùng tham gia khảo sát Onboarding 12 bước (Giới tính, Tuổi, Chiều cao, Cân nặng, Mức độ vận động, Mục tiêu thể hình, Ngân sách, Dị ứng thực phẩm, Nhóm món ăn ghét, Bệnh lý/Chấn thương).
- **Xử lý số liệu:** Máy chủ Backend tính toán $BMR$ (Mifflin-St Jeor), $TDEE$, hạn mức Calo mục tiêu và tỷ lệ phân bổ Macros (Carbs/Protein/Fat).
- **Tiền lọc Y tế & Rút trích Candidates:** Backend lọc bỏ tuyệt đối các món ăn chứa dị ứng/chấn thương và rút trích tập ứng viên cân bằng 90-150 món theo thuật toán Category Round-Robin.
- **Tương tác AI:** Backend đóng gói Dynamic Prompt gửi tới Google Gemini AI API để sinh chuỗi JSON thực đơn 7 ngày và lịch tập thể hình.
- **Hậu xử lý & Lưu trữ:** Backend chạy bộ vá JSON bằng Stack (`repairTruncatedJsonNode`), ánh xạ UUID thực phẩm 3 tầng (`Fuzzy Matching`), co giãn Gram theo `Macro Scaler` chuẩn $100\% TDEE$ và lưu vào cơ sở dữ liệu PostgreSQL.
- **Kết thúc:** Mobile App nhận DTO kết quả và hiển thị Bảng điều khiển cá nhân hóa cho người dùng.

#### 2. Mã PlantUML Biểu đồ hoạt động (Activity Diagram)

```plantuml
@startuml
skinparam ActivityFontSize 12
skinparam ActivityDiamondFontSize 12
skinparam ArrowColor #1565C0
skinparam ActivityBorderColor #1565C0
skinparam ActivityBackgroundColor #E3F2FD

|👤 Người dùng (Mobile App)|
start
:Đăng ký tài khoản (Email / Google OAuth2);
:Thực hiện khảo sát Onboarding (12 bước);
note right
  - Chỉ số sinh học (Chiều cao, Cân nặng, Tuổi...)
  - Mục tiêu thể hình & Ngân sách ăn uống
  - Ràng buộc y tế (Dị ứng, Chấn thương, Món ghét)
end note
:Xác nhận gửi hồ sơ thể trạng;

|⚙️ Backend Server (Spring Boot)|
:Xác thực người dùng & Khởi tạo mã JWT Token;
:Tính toán chỉ số sinh học (BMR, TDEE, BMI & Target Calo);
:Tiền lọc y tế triệt để (Loại bỏ dị ứng, chấn thương);
:Rút trích tập ứng viên cân bằng (Category Round-Robin 90-150 món);
:Đóng gói Dynamic Prompt chứa ngữ cảnh người dùng;

|🤖 Google Gemini AI API|
:Phân tích suy luận ngữ cảnh & dinh dưỡng;
:Sinh chuỗi JSON Thực đơn 7 ngày & Lịch tập luyện;

|⚙️ Backend Server (Spring Boot)|
if (Chuỗi JSON bị ngắt dở chừng?) then (có)
  :Kích hoạt Stack-based JSON Auto-Repair Engine;
  :Tự đóng ngoặc kép & Pop ngược Stack đóng nhọn/vuông;
else (không)
endif
:Ánh xạ UUID mờ 3 tầng (Fuzzy Food/Exercise Matching);
:Co giãn Gram khẩu phần (Exact Macro Scaler chuẩn 100% TDEE);
:Lưu Lộ trình cá nhân hóa vào CSDL PostgreSQL;

|👤 Người dùng (Mobile App)|
:Hiển thị Dashboard & Lộ trình Thực đơn/Lịch tập;
stop
@enduml
```

---

### 4.2.2. Quy trình 2: Theo dõi Dinh dưỡng Hàng ngày, Ghi Nhật ký và Đổi món Thông minh (AI Smart Swap)

#### 1. Mô tả chi tiết quy trình

Luồng nghiệp vụ kết hợp các Use Case: **UC03 (Ghi nhật ký ăn uống)**, **UC04 (Tìm kiếm thực phẩm Meilisearch)**, **UC06 (Đổi món thông minh Smart Swap AI)** và **UC12 (Check-in dinh dưỡng)**.

- **Theo dõi nhật ký:** Người dùng mở màn hình dinh dưỡng, tìm kiếm món ăn bằng công cụ Meilisearch siêu tốc và nạp thực phẩm tiêu thụ thực tế vào nhật ký bữa Sáng, Bữa Trưa.
- **Tính toán Calo lũy kế:** Backend tính tổng Calo và Macros đã nạp trong ngày, phản hồi tiến độ về Mobile App.
- **Nhu cầu đổi món:** Đến bữa Tối, người dùng không muốn ăn món ăn gợi ý sẵn trong thực đơn nên bấm chọn **Smart Swap (Đổi món)**.
- **Gợi ý món tương đồng:** Backend tính lượng Calo/Macro còn thiếu trong ngày, truy vấn tập ứng viên tương đồng về dinh dưỡng và danh mục, gửi yêu cầu tới Gemini AI để tìm ra 5 món ăn thay thế chuẩn Việt Nam.
- **Cập nhật thực đơn:** Người dùng chọn món thay thế ưa thích; Backend tự động cập nhật lại thực đơn Bữa Tối và tính toán lại các chỉ số dinh dưỡng.
- **Điểm danh ngày:** Người dùng hoàn thành dinh dưỡng ngày và bấm Check-in.

#### 2. Mã PlantUML Biểu đồ hoạt động (Activity Diagram)

```plantuml
@startuml
skinparam ArrowColor #2E7D32
skinparam ActivityBorderColor #2E7D32
skinparam ActivityBackgroundColor #E8F5E9

|👤 Người dùng (Mobile App)|
start
:Mở Nhật ký Dinh dưỡng trong ngày;
:Tìm kiếm món ăn (Meilisearch) & Ghi nạp bữa Sáng / Trưa;

|⚙️ Backend Server|
:Cập nhật Calo nạp lũy kế & Phản hồi thanh tiến độ TDEE;

|👤 Người dùng (Mobile App)|
if (Muốn thay đổi món ăn bữa Tối?) then (có (Smart Swap))
  :Nhấn chọn nút "Smart Swap" trên món ăn gốc;
  
  |⚙️ Backend Server|
  :Lấy thông tin món gốc (Calo, Protein, Fat, Carbs, Category);
  :Tính toán khoảng bù trừ Calo/Macro còn thiếu;
  :Gửi Prompt tìm kiếm món thay thế tới Gemini AI API;
  
  |🤖 Google Gemini AI API|
  :Tìm kiếm 5 món ăn Việt Nam có dinh dưỡng tương đồng;
  
  |⚙️ Backend Server|
  :Ánh xạ UUID & Phản hồi danh sách món gợi ý;
  
  |👤 Người dùng (Mobile App)|
  :Xem danh sách & Chọn món ăn thay thế ưa thích;
  :Xác nhận thay đổi món;
  
  |⚙️ Backend Server|
  :Cập nhật món mới vào Thực đơn & Nhật ký ăn uống;
else (không (Ăn theo thực đơn))
  :Giữ nguyên thực đơn sẵn có;
endif

|👤 Người dùng (Mobile App)|
:Tự động tính tổng Calo nạp cuối ngày;
:Bấm Check-in dinh dưỡng ngày hoàn thành;

|⚙️ Backend Server|
:Lưu dữ liệu Check-in Dinh dưỡng vào PostgreSQL;
stop
@enduml
```

---

### 4.2.3. Quy trình 3: Theo dõi Luyện tập, Đếm bước chân Pedometer và Điểm danh Kiên trì (Daily Fitness & Streak Tracking Loop)

#### 1. Mô tả chi tiết quy trình

Luồng nghiệp vụ phối hợp giữa cảm biến di động, tính toán thể lực và hệ thống duy trì động lực, kết hợp các Use Case: **UC13 (Thông báo Firebase FCM)**, **UC09 (Đếm bước chân Pedometer)**, **UC07 (Ghi nhật ký luyện tập)** và **UC12 (Thống kê Chuỗi Streak)**.

- **Nhắc nhở tự động:** Firebase FCM gửi thông báo đẩy nhắc nhở tập luyện vào khung giờ cố định đã cài đặt.
- **Tự động thu thập vận động:** Cảm biến Pedometer trên điện thoại đếm số bước chân vận động liên tục trong ngày và đồng bộ ngầm lên ứng dụng.
- **Thực hiện bài tập:** Người dùng mở màn hình Luyện tập, tập theo danh sách bài tập AI gợi ý (xem video hướng dẫn, đếm số Sets/Reps/Mức tạ).
- **Tính calo tiêu hao:** Backend tính toán lượng Calo đốt cháy dựa trên thời gian tập, trọng lượng cơ thể và chỉ số chuyển hóa **MET** ($Calories = Duration \times MET \times Weight / 200$), sau đó cộng dồn với Calo tiêu hao từ số bước chân.
- **Cập nhật Streak:** Người dùng bấm hoàn thành buổi tập. Backend kiểm tra điều kiện hoàn thành cả Dinh dưỡng & Luyện tập trong ngày để tự động tăng chuỗi kiên trì (**Streak Count +1**).

#### 2. Mã PlantUML Biểu đồ hoạt động (Activity Diagram)

```plantuml
@startuml
skinparam ArrowColor #C62828
skinparam ActivityBorderColor #C62828
skinparam ActivityBackgroundColor #FFEBEE

|📱 Cảm biến & Firebase Service|
start
:Firebase FCM gửi thông báo nhắc nhở tập luyện;
:Cảm biến Pedometer tự động đếm bước chân liên tục;

|👤 Người dùng (Mobile App)|
:Mở phân hệ Luyện tập từ Thông báo / Dashboard;
:Xem danh sách bài tập & Video hướng dẫn kỹ thuật;
:Thực hiện bài tập & Nhập số Sets, Reps, Mức tạ thực tế;
:Bấm "Hoàn thành Buổi tập";

|⚙️ Backend Server|
:Đồng bộ dữ liệu số bước chân Pedometer;
:Tính Calo đốt cháy bài tập = (Duration * MET * Weight) / 200;
:Cộng dồn Calo tiêu hao từ Bước chân + Bài tập thể hình;
:Lưu thông tin Nhật ký Luyện tập (Daily Workout Log);

if (Đã đạt mục tiêu Dinh dưỡng AND Luyện tập trong ngày?) then (đạt cả hai)
  :Tăng số ngày kiên trì liên tục (Streak Count = Streak + 1);
  :Kiểm tra cấp Huy hiệu vinh danh (Milestone Badges);
  
  |👤 Người dùng (Mobile App)|
  :Hiển thị Popup chúc mừng Streak +1 & Hiệu ứng Huy hiệu;
else (chưa đạt đủ)
  |⚙️ Backend Server|
  :Lưu tiến trình Check-in một phần;
  
  |👤 Người dùng (Mobile App)|
  :Hiển thị tiến độ luyện tập trong ngày;
endif
stop
@enduml
```

---

### 4.2.4. Quy trình 4: Trợ lý AI Coach Tư vấn & Điều chỉnh Thực đơn theo Phản hồi Người dùng (AI Coach Feedback Loop)

#### 1. Mô tả chi tiết quy trình

Luồng nghiệp vụ thể hiện khả năng trò chuyện và thích ứng thông minh của AI khi người dùng đưa ra phản hồi hoặc câu hỏi thắc mắc. Phối hợp các Use Case: **UC11 (Trò chuyện AI Coach)** và **UC05.2 (Tái tạo thực đơn theo phản hồi)**.

- **Tương tác câu hỏi/phản hồi:** Người dùng nhập câu hỏi tư vấn sức khỏe hoặc gửi phản hồi điều chỉnh thực đơn (ví dụ: *"Hôm nay tôi mệt, muốn đổi bữa trưa thành cháo gà"*).
- **Xây dựng ngữ cảnh nâng cao:** Backend thu thập lịch sử hội thoại gần nhất, chỉ số BMR/TDEE, danh sách dị ứng/chấn thương và thực đơn hiện tại của người dùng để đóng gói thành System Context Prompt.
- **Suy luận đa mục đích:** Gemini AI phân tích yêu cầu. Nếu là câu hỏi tư vấn, AI trả về lời khuyên dạng Text. Nếu là yêu cầu đổi thực đơn, AI trả về mảng JSON thực đơn mới đã qua điều chỉnh.
- **Xác nhận áp dụng:** Với trường hợp điều chỉnh thực đơn, Mobile App hiển thị thực đơn dự thảo. Người dùng xem lại và bấm **"Đồng ý áp dụng"**. Backend tiến hành ghi đè thực đơn mới vào CSDL.

#### 2. Mã PlantUML Biểu đồ hoạt động (Activity Diagram)

```plantuml
@startuml
skinparam ArrowColor #6A1B9A
skinparam ActivityBorderColor #6A1B9A
skinparam ActivityBackgroundColor #F3E5F5

|👤 Người dùng (Mobile App)|
start
:Mở giao diện Trợ lý AI Coach / Thực đơn gợi ý;
:Nhập tin nhắn tư vấn hoặc Yêu cầu điều chỉnh thực đơn;
note right
  Ví dụ: "Hôm nay tôi mệt, 
  hãy đổi bữa trưa thành cháo nhẹ dễ tiêu"
end note
:Gửi tin nhắn phản hồi;

|⚙️ Backend Server|
:Truy vấn Hồ sơ cá nhân (Chỉ số TDEE, Dị ứng, Bệnh lý);
:Đóng gói Lịch sử trò chuyện + Thực đơn hiện tại + Prompt nâng cao;
:Gửi API Request tới Gemini AI Model;

|🤖 Google Gemini AI API|
:Suy luận xử lý ngôn ngữ tự nhiên (NLP);
if (Loại yêu cầu là gì?) then (Tư vấn sức khỏe / Hỏi đáp)
  :Sinh phản hồi trả lời dạng Văn bản tự nhiên (Text);
else (Yêu cầu Điều chỉnh Thực đơn)
  :Tạo cấu trúc mảng JSON Thực đơn mới đã qua điều chỉnh;
endif

|⚙️ Backend Server|
:Hậu xử lý phản hồi & Phản hồi về Mobile App;

|👤 Người dùng (Mobile App)|
:Hiển thị tin nhắn tư vấn / Thực đơn điều chỉnh dự thảo;

if (Có yêu cầu đổi thực đơn AND Người dùng bấm Đồng ý?) then (đồng ý)
  |⚙️ Backend Server|
  :Ghi đè Thực đơn điều chỉnh mới vào CSDL PostgreSQL;
  
  |👤 Người dùng (Mobile App)|
  :Cập nhật Bảng điều khiển Thực đơn mới;
else (chỉ hỏi đáp / từ chối)
  |👤 Người dùng (Mobile App)|
  :Tiếp tục cuộc trò chuyện hoặc đóng màn hình;
endif
stop
@enduml
```

---

### 4.2.5. Quy trình 5: Quản trị Nội dung Danh mục Thực phẩm / Bài tập và Kiểm duyệt Hệ thống (Admin Moderation Workflow)

#### 1. Mô tả chi tiết quy trình

Luồng nghiệp vụ dành cho Quản trị viên (Admin) vận hành hệ thống trên trang **Admin Web Dashboard**. Kết hợp các Use Case: **UC14 (Quản lý danh mục thực phẩm)**, **UC15 (Quản lý danh mục bài tập)** và **UC16 (Báo cáo & Thống kê hệ thống)**.

- **Đăng nhập Quản trị:** Quản trị viên đăng nhập vào Admin Web Dashboard bằng tài khoản có quyền `ROLE_ADMIN`.
- **Cập nhật dữ liệu:** Admin thực hiện thêm/sửa/xóa thông tin món ăn (Calo, Protein, Fat, Carbs, Category, Image) hoặc bài tập thể hình (MET, Muscle Group, Equipment, Video URL).
- **Đồng bộ Meilisearch:** Mỗi khi dữ liệu món ăn/bài tập được chỉnh sửa thành công trong PostgreSQL, Backend tự động phát sự kiện đồng bộ bản ghi mới sang **Meilisearch Engine** để cập nhật chỉ mục tìm kiếm siêu tốc.
- **Làm mới bộ nhớ Cache:** Backend xóa bộ nhớ tạm (`cachedFoods` / `cachedExercises`) để các lượt gọi AI gợi ý thực đơn từ phía người dùng luôn nhận được dữ liệu mới nhất.
- **Theo dõi thống kê:** Admin xem các báo cáo tổng quan về số lượng người dùng mới, tỷ lệ gọi AI thành công và lưu lượng API.

#### 2. Mã PlantUML Biểu đồ hoạt động (Activity Diagram)

```plantuml
@startuml
skinparam ArrowColor #E65100
skinparam ActivityBorderColor #E65100
skinparam ActivityBackgroundColor #FFF3E0

|👨‍💼 Quản trị viên (Admin Web)|
start
:Đăng nhập hệ thống bằng tài khoản ROLE_ADMIN;
:Mở Màn hình Quản lý Danh mục Thực phẩm / Bài tập;
:Thực hiện Thêm mới / Chỉnh sửa / Xóa Thực phẩm (Bài tập);
:Bấm "Lưu thay đổi";

|⚙️ Backend Server (Spring Boot)|
:Kiểm tra phân quyền JWT Token (ROLE_ADMIN);
:Cập nhật thông tin bản ghi vào CSDL PostgreSQL;

fork
  :Phát sự kiện đồng bộ dữ liệu sang Meilisearch Engine;
  :Cập nhật lại Chỉ mục tìm kiếm (Search Index);
fork again
  :Xóa bộ nhớ Cache tạm (cachedFoods / cachedExercises);
  :Ghi Nhật ký Quản trị (System Audit Log);
end fork

|👨‍💼 Quản trị viên (Admin Web)|
:Hiển thị thông báo Cập nhật thành công;
:Xem Báo cáo Thống kê lưu lượng API & Người dùng mới;
stop
@enduml
```

---

### 4.2.6. Quy trình 6: Theo dõi Tiến độ Thể trạng, Đánh giá và Điều chỉnh Lộ trình AI (Progress Tracking & AI Plan Re-evaluation Workflow)

#### 1. Mô tả chi tiết quy trình
Luồng nghiệp vụ này mô tả chu kỳ theo dõi sự thay đổi thể trạng của người dùng qua thời gian, hệ thống tính toán thống kê và **đưa ra gợi ý để người dùng đưa ra quyết định** duy trì lộ trình hiện tại hay chuyển sang mục tiêu mới. Phối hợp các Use Case: **UC02.2 (Cập nhật chỉ số thể trạng/cân nặng)**, **UC03 (Nhật ký dinh dưỡng)**, **UC07 (Nhật ký luyện tập)**, **UC09 (Đếm bước chân)**, **UC02.1 (Điều chỉnh mục tiêu UserGoal)** và **UC05.2 (Tái tạo lộ trình AI)**.

- **Ghi nhận tiến độ:** Người dùng cập nhật cân nặng mới (`UserMetricHistory`), đồng bộ số bước chân Pedometer và hoàn thành nhật ký Calo nạp/đốt hàng ngày trên Mobile App.
- **Tính toán chỉ số & Thống kê:** Máy chủ Backend lưu vết lịch sử chỉ số, tính toán mức biến động cân nặng ($\Delta Weight$), số dư Calo nạp/đốt lũy kế và vẽ biểu đồ tiến độ.
- **Đánh giá & Trình biểu quyết cho Người dùng:** Hệ thống hiển thị mức độ hoàn thành mục tiêu và đưa ra lựa chọn hành động cho người dùng:
  - *Lựa chọn 1 (Muốn tiếp tục duy trì):* Người dùng xác nhận duy trì kế hoạch hiện tại. Backend tiếp tục giữ lộ trình thực đơn/lịch tập sẵn có, đồng thời ghi nhận điểm thưởng kiên trì (Streak Count +1) và mở khóa Huy hiệu vinh danh.
  - *Lựa chọn 2 (Đã hoàn thành mục tiêu / Muốn đổi mục tiêu mới):* Người dùng bấm chọn "Thiết lập Mục tiêu mới" (như chuyển từ *Giảm cân* sang *Tăng cơ* hoặc *Duy trì thể trạng*). Backend cập nhật `UserGoal`, tính toán lại chỉ số $BMR$ (Mifflin-St Jeor) và $TDEE$ mới, lọc triệt để y tế, đóng gói Dynamic Prompt gửi tới Google Gemini AI API để tái tạo Thực đơn 7 ngày và Lịch tập mới.
- **Hậu xử lý & Cập nhật Lộ trình mới:** Backend chạy bộ vá lỗi JSON bằng Stack (`repairTruncatedJsonNode`), ánh xạ UUID thực phẩm/bài tập (`Fuzzy Matching`), co giãn Gram (`Macro Scaler`) chuẩn $100\% TDEE$ mới và ghi đè lộ trình mới lên CSDL PostgreSQL.

#### 2. Mã PlantUML Biểu đồ hoạt động (Activity Diagram)

```plantuml
@startuml
skinparam ActivityFontSize 12
skinparam ActivityDiamondFontSize 12
skinparam ArrowColor #1565C0
skinparam ActivityBorderColor #1565C0
skinparam ActivityBackgroundColor #E3F2FD

|👤 Người dùng (Mobile App)|
start
:Ghi nhận dữ liệu tiến độ thực tế;
note right
  - Cập nhật Cân nặng mới (UserMetricHistory)
  - Đồng bộ số bước chân Pedometer tự động
  - Nhật ký Calo nạp/đốt (Daily Log) & Kết quả buổi tập
end note

|⚙️ Backend Server (Spring Boot)|
:Kiểm tra tính hợp lệ của chỉ số & Lưu dữ liệu theo dõi;
:Tính toán biến động chỉ số theo thời gian (Weight Delta, Calo Net);
:Cập nhật Bảng thống kê & Biểu đồ tiến độ (Weight/Calorie Charts);
:Đánh giá mức độ đạt mục tiêu (Target Weight & Milestone Check);

|👤 Người dùng (Mobile App)|
if (Quyết định của Người dùng về Mục tiêu?) then (Đã hoàn thành / Muốn lập Mục tiêu mới)
  :Bấm chọn: "Thiết lập Mục tiêu mới" hoặc "Điều chỉnh thông số";
  note right
    Ví dụ: Chuyển từ "Giảm cân" 
    sang "Tăng cơ" hoặc "Duy trì"
  end note
  
  |⚙️ Backend Server (Spring Boot)|
  :Cập nhật Hồ sơ mục tiêu mới (UserGoal & Target Weight);
  :Tính toán lại chỉ số BMR (Mifflin-St Jeor) & Target TDEE mới;
  :Tiền lọc Y tế (Dị ứng, Chấn thương, Nhóm món ghét);
  :Đóng gói Dynamic Prompt chứa ngữ cảnh mục tiêu mới;
  
  |🤖 Google Gemini AI API|
  :Phân tích mục tiêu mới & Sinh Thực đơn/Lịch tập cá nhân hóa;
  
  |⚙️ Backend Server (Spring Boot)|
  if (Chuỗi JSON bị ngắt dở?) then (có)
    :Kích hoạt Stack-based JSON Auto-Repair Engine;
  else (không)
  endif
  :Ánh xạ UUID mờ (Fuzzy Matching) & Co giãn Gram (Macro Scaler);
  :Ghi đè Lộ trình Thực đơn & Lịch tập mới vào CSDL PostgreSQL;
  
  |👤 Người dùng (Mobile App)|
  :Hiển thị Thông báo Chúc mừng & Lộ trình Thực đơn/Lịch tập mới;
  :Thực hiện Lộ trình Mục tiêu mới;

else (Muốn tiếp tục duy trì Lộ trình hiện tại)
  |⚙️ Backend Server (Spring Boot)|
  :Duy trì Lộ trình Thực đơn & Lịch tập hiện tại;
  :Cập nhật Chuỗi ngày kiên trì (Streak Count +1) & Huy hiệu;
  
  |👤 Người dùng (Mobile App)|
  :Xem Biểu đồ tiến độ & Tiếp tục thực hiện lộ trình hiện tại;
endif
stop
@enduml
```

---

## 4.3. Bảng tổng hợp mối liên kết giữa Use Case và Quy trình Nghiệp vụ

| STT | Quy trình Nghiệp vụ Cốt lõi | Các Use Case kết hợp cấu thành quy trình | Thành phần tham gia xử lý chính |
| :-: | :--- | :--- | :--- |
| 1 | **Quy trình 1: Onboarding & Khởi tạo AI** | UC01 (Authen), UC02 (Onboarding), UC02.3 (BMR/TDEE), UC05 (Meal AI), UC10 (Workout AI) | Mobile App, Spring Boot Backend, PostgreSQL, Gemini AI API |
| 2 | **Quy trình 2: Ghi Nhật ký & Smart Swap** | UC03 (Daily Meal Log), UC04 (Meilisearch), UC06 (Smart Swap AI), UC12 (Check-in) | Mobile App, Spring Boot, Meilisearch Engine, Gemini AI, PostgreSQL |
| 3 | **Quy trình 3: Luyện tập & Streak Loop** | UC07 (Workout Log), UC09 (Pedometer), UC12 (Streak Check-in), UC13 (Firebase FCM) | Pedometer Sensor, Firebase FCM, Mobile App, Spring Boot Backend |
| 4 | **Quy trình 4: Trợ lý AI Coach Feedback** | UC11 (AI Coach Chat), UC05.2 (Re-generate Meal), UC02 (Health Context) | Mobile App, Spring Boot, Gemini AI Model, PostgreSQL |
| 5 | **Quy trình 5: Admin Content & Moderation** | UC14 (Manage Foods), UC15 (Manage Exercises), UC16 (System Reports) | Admin Web Dashboard, Spring Boot, PostgreSQL, Meilisearch Engine |
| 6 | **Quy trình 6: Progress Tracking & AI Re-evaluation** | UC02.2 (Metric Update), UC03 (Meal Log), UC07 (Workout Log), UC05.2 (Re-generate AI) | Mobile App, Spring Boot Backend, Gemini AI API, PostgreSQL |

