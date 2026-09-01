# Nhật Ký Hỏi - Đáp Kỹ Thuật (Q&A Log) & Bộ Câu Hỏi Phản Biện DATN - BodyPilot

Tài liệu này ghi nhớ toàn bộ danh sách các câu hỏi, thắc mắc kỹ thuật và **Bộ Câu Hỏi Phản Biện Đồ Án Tốt Nghiệp (DATN Defense Q&A)** thường bị Thầy/Cô Hội đồng bảo vệ hỏi liên quan đến luồng Khảo sát (Assessment Flow), Kiến trúc & Mã nguồn dự án **BodyPilot**.

---

## 🎓 BỘ CÂU HỎI VÀ CÂU TRẢ LỜI PHẢN BIỆN ĐỒ ÁN TỐT NGHIỆP (DATN DEFENSE)

### 🔴 Nhóm 1: Câu Hỏi Về Kiến Trúc & Security (Architecture & Security)

#### ❓ Câu hỏi 1.1: Tại sao cả Mobile Client (Flutter) và Backend (Spring Boot) đều thực hiện tính toán BMI, BMR, TDEE? Nếu kết quả giữa Mobile và Backend khác nhau thì sao?
* **Cách trả lời chuẩn**:
  - **Phía Mobile Client**: Tính toán thời gian thực tại `AssessmentResultStep` ngay trên thiết bị để **tối ưu UX/UI**, hiển thị kết quả xem trước (Instant Preview) mà không cần đợi request mạng.
  - **Phía Backend**: Thực hiện tính toán lại trong hàm giao dịch `@Transactional submitAssessment()` tại `AssessmentServiceImpl.java` để **đảm bảo toàn vẹn dữ liệu (Data Integrity)**, chống việc client gửi payload giả mạo và lưu bản ghi chuẩn xác vào DB `user_metric_history`.
  - **Trường hợp kết quả khác nhau**: **Backend (Server) luôn là Nguồn Sự Thật Duy Nhất (Single Source of Truth)**. Sau khi nộp khảo sát, ứng dụng tự động gọi `userCubit.fetchUserProfile()` để tải lại toàn bộ kết quả từ Server về. Toàn bộ lượng Calo mục tiêu, BMR, TDEE hiển thị trên Trang Chủ (`MainScreen`) và Nhật Ký sau này đều tuân theo số liệu chuẩn do Server trả về.

#### ❓ Câu hỏi 1.2: Cơ chế xác thực JWT Token được thực hiện thế nào khi nộp khảo sát? Nếu Token bị giả mạo hoặc hết hạn thì xử lý ra sao?
* **Cách trả lời chuẩn**:
  - Khi gửi request `POST /api/v1/users/{userId}/assessment`, Dio Interceptor phía Mobile tự động đính kèm Header `Authorization: Bearer <token>`.
  - Phía Backend, bộ lọc `JwtAuthenticationFilter.java` chặn mọi request. Hàm `jwtService.extractUsername(jwt)` giải mã JWT secret key.
  - Nếu token bị giả mạo hoặc hết hạn (`isTokenExpired`), `JwtAuthenticationFilter` hoặc `SecurityConfig` sẽ lập tức bắn ra HTTP Status `401 Unauthorized`. Client nhận lỗi `401` sẽ tự động xóa token hỏng và đưa người dùng về màn hình Đăng nhập.

---

### 🟡 Nhóm 2: Câu Hỏi Về Quản Lý Trạng Thái & Dữ Liệu Tạm (State Management & Cache)

#### ❓ Câu hỏi 2.1: Tại sao em không viết code lưu Hive ở từng trang khảo sát (GoalStep, GenderStep, BodyStep...) mà dữ liệu vẫn tự động được lưu?
* **Cách trả lời chuẩn**:
  - Nhờ thiết kế **Override hàm `emit()` tập trung trong `AssessmentCubit`** ([assessment_cubit.dart:L48-L55](file:///c:/Personal/DATN/BodyPilot/mobile/lib/presentation/bloc/assessment/assessment_cubit.dart#L48-L55)):
    ```dart
    @override
    void emit(AssessmentState state) {
      super.emit(state);
      if (state.status != AssessmentStatus.success && state.status != AssessmentStatus.loading) {
        _box.put('current_assessment', state.toJson());
      }
    }
    ```
  - Trong BLoC Pattern, bất kỳ trang nào khi người dùng tương tác (như `selectGoal`, `selectGender`, `selectHeight`, `toggleCondition`...) đều gọi một hàm setter trong `AssessmentCubit`, và tất cả các hàm này cuối cùng đều gọi `emit(state.copyWith(...))`.
  - Việc ghi đè hàm `emit()` giúp **kích hoạt việc lưu tự động dữ liệu vào Hive local box (`'current_assessment'`) tại một nơi duy nhất**, giúp tránh lặp lại code 10 lần ở 10 file giao diện khác nhau (Tuân thủ nguyên tắc DRY - Don't Repeat Yourself).

#### ❓ Câu hỏi 2.2: Khi đang làm khảo sát 9 bước mà người dùng vô tình thoát App hoặc sập nguồn, dữ liệu đã nhập có bị mất không?
* **Cách trả lời chuẩn**:
  - Dữ liệu **KHÔNG bị mất**. Khi mở lại App, constructor của `AssessmentCubit` tự động gọi `_loadFromHive()` đọc dữ liệu từ Hive box `'current_assessment'` để khôi phục lại chính xác các lựa chọn dở dang. Chỉ khi nộp bài thành công lên Backend, cache Hive này mới được xóa (`_box.delete('current_assessment')`).

#### ❓ Câu hỏi 2.3: Tại sao khi phiên đăng nhập hết hạn 7 ngày (`isSessionValid() == false`), hàm `removeToken()` lại xóa sạch cả các cờ `is_assessment_completed` trên máy?
* **Cách trả lời chuẩn**:
  - Để đảm bảo **An toàn đa người dùng (Multi-user Safety)** trên cùng một chiếc điện thoại. Nếu không xóa cờ `is_assessment_completed` của User A, khi User B mượn máy đăng nhập, App sẽ đọc nhầm cờ của User A và bỏ qua bước khảo sát của User B.
  - Người dùng **không bao giờ phải làm lại khảo sát** vì dữ liệu khảo sát chính thức đã nằm an toàn trong cơ sở dữ liệu PostgreSQL ở Backend (`UserProfile.isAssessmentCompleted = true`). Đăng nhập lại ➔ Server trả cờ về ➔ App đưa thẳng vào Trang Chủ.

---

### 🟢 Nhóm 3: Câu Hỏi Về Thuật Toán & Cơ Sở Khoa Học (Scientific & Calculation Formulas)

#### ❓ Câu hỏi 3.1: Em căn cứ vào tiêu chuẩn y khoa nào để tính BMR và TDEE? Tại sao lại chọn công thức Mifflin-St Jeor mà không dùng Harris-Benedict?
* **Cách trả lời chuẩn**:
  - Dự án áp dụng công thức **Mifflin-St Jeor (1990)** vì các nghiên cứu y học thể thao hiện đại khẳng định Mifflin-St Jeor có độ chính xác cao hơn từ 5% - 10% so với công thức cổ điển Harris-Benedict (xây dựng từ năm 1919).
  - Phân loại chỉ số BMI được áp dụng theo chuẩn **WHO WPRO (Tổ chức Y tế Thế giới dành cho khu vực Tây Thái Bình Dương - Người Châu Á)** với ngưỡng thừa cân bắt đầu từ 23.0 kg/m² (thay vì 25.0 kg/m² của người Châu Âu).

#### ❓ Câu hỏi 3.2: Với mục tiêu giảm 1.0kg/tuần (thâm hụt 1000 kcal/ngày), làm sao để đảm bảo người dùng không bị giảm calo quá đà gây nguy hại sức khỏe?
* **Cách trả lời chuẩn**:
  - Hệ thống áp dụng nguyên tắc kiểm soát ngưỡng an toàn: Mức Calo mục tiêu nạp vào (`targetCalories`) không bao giờ được phép thấp hơn chỉ số **BMR** (Mức năng lượng tối thiểu cần thiết để duy trì các cơ quan sinh tồn hoạt động ở trạng thái nghỉ).

---

### 🔵 Nhóm 4: Câu Hỏi Về Thiết Kế Database & Tích Hợp AI (Database Design & AI Scalability)

#### ❓ Câu hỏi 4.1: Tại sao thông tin Bệnh Lý (HealthConditions) và Chấn Thương (Injuries) lại lưu thành các bảng Master riêng thay vì lưu trực tiếp dưới dạng chuỗi Text/JSON trong bảng Profile?
* **Cách trả lời chuẩn**:
  - Thiết kế chuẩn hóa **Normalization (Chuẩn 3NF)** giúp:
    1. Quản lý danh mục master tập trung (Dễ dàng thêm/sửa bệnh lý từ Admin Web mà không sửa code App).
    2. Tối ưu hóa truy vấn SQL (Dùng JOIN và UUID Index thay vì quét chuỗi Full-text Search).
    3. Phục vụ cho **AI Prompt Builder**: Khi phát sinh nhu cầu tạo thực đơn AI, Backend chỉ cần query bảng `user_health_conditions` lấy code (VD: `DIABETES`) để tự động gắn Rule cho AI Prompt: *"Không gợi ý món ăn có chỉ số đường huyết (GI) cao"*.

---

## 📄 NHẬT KÝ CÂU HỎI TRƯỚC ĐÓ (LỊCH SỬ THẢO LUẬN)

### ❓ Câu Hỏi 1: Kế Hoạch & Lộ Trình Để Hiểu Toàn Bộ Flow và Code Dự Án
- Lộ trình 5 bước: Kiến trúc & Nghiệp vụ ➔ Phân tích Database & Backend ➔ Mã nguồn Mobile Flutter ➔ Admin Web & Shared ➔ Debug & Trace 3 scenario.

### ❓ Câu Hỏi 2: Luồng Chạy Chi Tiết Từ Khi Mở App Đến Hoàn Thành Khảo Sát
- 5 Giai đoạn: App Launch & Splash ➔ Auth Flow ➔ Survey 9 Steps PageView ➔ Backend Processing & Calculation ➔ Result Step & Redirect Home.

### ❓ Câu Hỏi 5: Giải Thích Dòng Code `if (_isStarting) return;` Trong `splash_cubit.dart`
- Guard Clause / Re-entrancy Lock ngăn việc trigger hàm async 2 lần liên tiếp khi UI Flutter re-build.

### ❓ Câu Hỏi 9: Cách Nhận Biết Từ `SplashStatus.unauthenticated` Sẽ Chuyển Về Màn Hình Nào
- Liên kết 3 tầng: `splash_cubit.dart` (emit status) ➔ `splash_screen.dart` (`BlocListener` hứng status & gọi route) ➔ `app_pages.dart` (`GoRouter` map route sang `WelcomeScreen()`).

### ❓ Câu Hỏi 10: Luồng Lấy Dữ Liệu Danh Mục Master & Đồng Bộ UserCubit
- `fetchOptions()` lấy 4 API master data nạp vào state ➔ Sau khi submit thành công ➔ gọi `userCubit.fetchUserProfile()` đồng bộ dữ liệu mới nhất từ Server.

### ❓ Câu Hỏi 11: Luồng Khi Tải & Render Trang Kết Quả (`AssessmentResultStep`)
- Submit OK ➔ `AssessmentStatus.success` ➔ PageView Index 9 ➔ Tính BMI, BMR, TDEE, Target Calo real-time ➔ Render 4 khối UI ➔ Bấm nút Hoàn thành ➔ `context.go('/home')`.
