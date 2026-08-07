# CHƯƠNG 3: CÔNG NGHỆ SỬ DỤNG

Chương này trình bày chi tiết các công nghệ, nền tảng phần mềm, cơ sở dữ liệu và cơ sở lý thuyết được lựa chọn sử dụng trong Đồ án tốt nghiệp **BodyPilot**. Với từng thành phần công nghệ, báo cáo sẽ phân tích rõ: **(1) Vấn đề/yêu cầu cụ thể cần giải quyết ở Chương 2**, **(2) Các giải pháp công nghệ thay thế tương đương**, và **(3) Lập luận lý do lựa chọn giải pháp cuối cùng**.

---

## 3.1. Tổng quan Kiến trúc Công nghệ Hệ thống

Để đáp ứng các yêu cầu chức năng và phi chức năng đã đề ra ở Chương 2, hệ thống **BodyPilot** được thiết kế theo mô hình kiến trúc Client-Server 3 tầng phân rã rõ ràng (Three-Tier Architecture):

```
+-----------------------------------------------------------------------+
|                         TẦNG GIAO DIỆN (CLIENT)                       |
|   Ứng dụng Di động (Flutter iOS/Android)   |   Admin Web (Flutter Web)  |
+-----------------------------------+-----------------------------------+
                                    | (HTTPS / RESTful JSON APIs)
                                    v
+-----------------------------------------------------------------------+
|                        TẦNG NGHIỆP VỤ (SERVER API)                    |
|                Spring Boot 3.x Backend (Java 17, Spring Security)     |
+-------------------+-------------------------------+-------------------+
                    | (JPA / SQL)                   | (JSON REST API)
                    v                               v
+-----------------------------------+   +-------------------------------+
|     TẦNG DỮ LIỆU (DATABASE)       |   |     DỊCH VỤ ĐÁM MÂY BÊN NGOÀI  |
|  PostgreSQL v15+ (Supabase Cloud) |   |  Gemini AI API & Firebase FCM |
+-----------------------------------+   +-------------------------------+
```

---

## 3.2. Framework Phát triển Giao diện: Flutter & Dart

### 3.1.1. Vấn đề/Yêu cầu cần giải quyết ở Chương 2

- Xây dựng giao diện ứng dụng di động (**BodyPilot Mobile Client**) trên cả 2 nền tảng Android và iOS cho người dùng cuối với yêu cầu mượt mà (60 FPS), giao diện hiện đại thuần Việt.
- Xây dựng hệ thống quản trị Web (**BodyPilot Admin Web**) dành cho Quản trị viên quản lý dữ liệu gốc và theo dõi báo cáo.

### 3.1.2. Danh sách các giải pháp thay thế tương đương

1. **React Native (Facebook/Meta):** Framework phát triển cross-platform phổ biến sử dụng JavaScript/TypeScript.
2. **Lập trình Native (Android Kotlin & iOS Swift):** Viết 2 bộ mã nguồn riêng biệt cho từng nền tảng di động.
3. **Flutter (Google):** UI Toolkit mã nguồn mở của Google sử dụng ngôn ngữ lập trình Dart [3].

### 3.1.3. Phân tích và Lý do lựa chọn Flutter

- **So với Lập trình Native:** Lập trình Native cho hiệu năng tối đa nhưng đòi hỏi gấp đôi chi phí và thời gian phát triển để bảo trì 2 dự án độc lập. Flutter cho phép **tái sử dụng > 90% mã nguồn** giữa Android và iOS.
- **So với React Native:** React Native sử dụng cầu nối JavaScript Bridge để giao tiếp với các UI Component của hệ điều hành, dễ gây ra hiện tượng giật frame (*jank*) khi xử lý các animation phức tạp. Flutter biên dịch trực tiếp mã nguồn Dart thành mã máy Native (Ahead-Of-Time - AOT compilation) và tự vẽ UI bằng engine Skia/Impeller, đảm bảo hiệu năng mượt mà 60 - 120 FPS [3].
- **Đặc biệt:** Flutter hỗ trợ **Flutter Web**, giúp đội ngũ phát triển tái sử dụng các model và logic gọi API từ app di động để xây dựng trang Web Admin nhanh chóng mà không cần học thêm framework web khác.
- **Kiến trúc quản lý trạng thái:** Hệ thống sử dụng mô hình **BLoC (Business Logic Component) / Cubit** [4] giúp phân tách hoàn toàn giữa giao diện UI và logic xử lý, đáp ứng yêu cầu tính dễ bảo trì (*Maintainability*) ở Mục 5 - Chương 2.

---

## 3.3. Nền tảng Backend Service: Java 17 & Spring Boot 3.x

### 3.3.1. Vấn đề/Yêu cầu cần giải quyết ở Chương 2

- Xử lý các logic nghiệp vụ tập trung: Xác thực JWT token, tính toán chỉ số sinh học (BMR, TDEE, BMI, Calo mục tiêu), ghi nhận nhật ký ăn uống/luyện tập, và kết nối tích hợp với Gemini AI API.
- Đảm bảo thời gian phản hồi API < 1.5 giây, bảo mật chuẩn OWASP và khả năng mở rộng quy mô.

### 3.3.2. Danh sách các giải pháp thay thế tương đương

1. **Node.js (ExpressJS / NestJS):** Môi trường thực thi JavaScript không đồng bộ, tốc độ phát triển nhanh.
2. **Python (Django / FastAPI):** Framework phổ biến trong các ứng dụng tích hợp AI/ML.
3. **Java Spring Boot 3.x:** Framework chuẩn doanh nghiệp (*Enterprise Grade*) phát triển trên nền tảng Java 17 LTS [5].

### 3.3.3. Phân tích và Lý do lựa chọn Spring Boot 3.x

- **So với Node.js:** Node.js chạy đơn luồng (*Single-threaded Event Loop*), khi xử lý các tác vụ tính toán toán học phức tạp (như tính toán BMR/TDEE, lọc danh mục thực phẩm gây dị ứng) có thể gây nghẽn luồng chính. Spring Boot chạy đa luồng (*Multi-threading*) xử lý hàng ngàn truy vấn đồng thời ổn định.
- **So với Python (Django):** Python là ngôn ngữ định kiểu động (*Dynamically typed*), dễ phát sinh lỗi runtime khi dự án phình to. Java là ngôn ngữ định kiểu tĩnh (*Statically typed*), kết hợp tính năng Record và Pattern Matching của **Java 17** giúp mã nguồn chặt chẽ và an toàn.
- **Bảo mật & Tích hợp:** Spring Boot tích hợp sẵn **Spring Security 6.x**, dễ dàng triển khai bộ lọc xác thực `JwtAuthenticationFilter` và phân quyền chi tiết theo Role (`ROLE_USER`, `ROLE_ADMIN`), đáp ứng yêu cầu bảo mật ở Mục 3 - Chương 2 [5].

---

## 3.4. Hệ quản trị Cơ sở Dữ liệu: PostgreSQL & Supabase

### 3.4.1. Vấn đề/Yêu cầu cần giải quyết ở Chương 2

- Lưu trữ dữ liệu quan hệ có cấu trúc: Thông tin tài khoản, chỉ số sinh học, bảng thực phẩm Việt Nam, danh mục bài tập, nhật ký ăn uống/luyện tập và lịch sử check-in.
- Đảm bảo tính toàn vẹn dữ liệu (ACID) và khả năng truy vấn nhanh.

### 3.4.2. Danh sách các giải pháp thay thế tương đương

1. **MySQL:** Hệ quản trị CSDL quan hệ mã nguồn mở phổ biến.
2. **MongoDB:** CSDL NoSQL lưu trữ tài liệu dạng JSON (Document-oriented).
3. **PostgreSQL (trên mây Supabase):** Hệ quản trị CSDL quan hệ đối tượng (*Object-Relational DB*) tiên tiến nhất [6].

### 3.4.3. Phân tích và Lý do lựa chọn PostgreSQL

- **So với MongoDB:** Dữ liệu sức khỏe và dinh dưỡng có mối quan hệ chặt chẽ giữa các bảng (User - DailyEating - MealSlot - FoodItem). Sử dụng CSDL NoSQL dễ gây dư thừa dữ liệu và thiếu ràng buộc khóa ngoại (Foreign Key Integrity).
- **So với MySQL:** PostgreSQL có khả năng xử lý kiểu dữ liệu `JSONB` rất mạnh mẽ, cho phép lưu trữ các cấu trúc thực đơn linh hoạt do AI sinh ra mà vẫn giữ nguyên ưu điểm của CSDL quan hệ.
- **Nền tảng Supabase Cloud:** Giúp đóng gói cơ sở dữ liệu PostgreSQL trên hạ tầng đám mây tự động, hỗ trợ sao lưu (*Backup*) dữ liệu an toàn và miễn phí chi phí duy trì phần cứng.

---

## 3.5. Dịch vụ Trí tuệ Nhân tạo: Google Gemini API

### 3.5.1. Vấn đề/Yêu cầu cần giải quyết ở Chương 2

- Tự động hóa việc sinh thực đơn 7 ngày cá nhân hóa thuần Việt theo hạn mức TDEE, không chứa món gây dị ứng/bệnh lý.
- Đề xuất món ăn thay thế thông minh (*Smart Swap*) bảo toàn định mức Calo/Macros.
- Hỗ trợ Trợ lý trò chuyện **AI Coach 24/7** tư vấn kiến thức sức khỏe tự nhiên.

### 3.5.2. Danh sách các giải pháp thay thế tương đương

1. **OpenAI API (Model `gpt-4o-mini` / `gpt-3.5-turbo`):** Dịch vụ Generative AI phổ biến của OpenAI.
2. **Groq Llama 3 (Model `llama-3.1-8b-instant`):** Mô hình AI mã nguồn mở chạy trên chip gia tốc Groq LPUs.
3. **Google Gemini API (Model `gemini-2.5-flash`):** Mô hình ngôn ngữ thế hệ mới nhất của Google [7].

### 3.5.3. Phân tích và Lý do lựa chọn Gemini 2.5 Flash

- **Tốc độ suy luận và Latency:** `gemini-2.5-flash` được tối ưu hóa cho các tác vụ cần phản hồi nhanh, thời gian phản hồi trung bình chỉ từ **2 - 4 giây**, đáp ứng yêu cầu hiệu năng ở Mục 1 - Chương 2.
- **Khả năng tuân thủ định dạng JSON (Structured Outputs):** Gemini hỗ trợ cơ chế ép kiểu đầu ra theo đúng `JSON Schema` khai báo. Điều này giúp Backend Spring Boot dễ dàng parse chuỗi phản hồi từ AI thành các đối tượng DTO Java mà không bị lỗi cú pháp [7].
- **Hiểu biết văn hóa ẩm thực Việt Nam:** Qua thực nghiệm so sánh, Gemini xử lý câu từ tiếng Việt và am hiểu về các món ăn truyền thống Việt Nam (như phở, bún chả, cơm tấm, rau muống luộc) chính xác hơn so với Llama 3 hay GPT-3.5.

---

## 3.6. Dịch vụ Thông báo Đẩy & Cảm biến Phần cứng

### 3.6.1. Dịch vụ Thông báo Đẩy: Firebase Cloud Messaging (FCM)

- **Vấn đề giải quyết:** Tự động gửi thông báo đẩy nhắc nhở ăn uống, đếm bước chân và check-in vào 4 khung giờ cố định trong ngày (Sáng, Trưa, Chiều, Tối).
- **Lựa chọn thay thế:** OneSignal, Apple Push Notification service (APNs) trực tiếp.
- **Lý do lựa chọn:** **FCM** là giải pháp chuẩn công nghiệp của Google, hỗ trợ gửi thông báo hoàn toàn miễn phí, đa nền tảng (Android & iOS) và dễ dàng tích hợp vào Spring Boot Backend qua thư viện `firebase-admin` [8].

### 3.6.2. Cảm biến Phần cứng: Native Pedometer Sensor

- **Vấn đề giải quyết:** Tự động ghi nhận số bước chân vận động hàng ngày của người dùng mà không bắt buộc mua đồng hồ thông minh (*Smartwatch*).
- **Lựa chọn thay thế:** Định vị toàn cầu GPS (Location Tracking).
- **Lý do lựa chọn:** GPS tiêu tốn rất nhiều dung lượng pin thiết bị và không chính xác khi người dùng đi bộ trong nhà hoặc trên máy chạy bộ (*Treadmill*). Sử dụng trực tiếp cảm biến phần cứng **Pedometer (Step Counter Sensor)** của điện thoại qua Flutter Package `pedometer` giúp đọc số bước chân chính xác theo thời gian thực mà mức hao pin không đáng kể (< 2%/ngày).

---

## 3.7. Nền tảng Đóng gói & Triển khai Cloud: Docker & Render

### 3.7.1. Vấn đề/Yêu cầu cần giải quyết ở Chương 2

- Đảm bảo môi trường thực thi của Backend API đóng gói đồng nhất, tránh tình trạng "chạy được ở máy lập trình viên nhưng lỗi trên máy server".
- Triển khai ứng dụng lên điện toán đám mây cho phép kết nối từ xa.

### 3.7.2. Giải pháp lựa chọn & Phân tích

- **Docker Multi-Stage Build:** Sử dụng `Dockerfile` 2 giai đoạn (Build Stage với Maven 3.9 + Java 17; Run Stage với Temurin JRE 17) giúp kích thước tệp ảnh (*Image*) giảm từ 600MB xuống chỉ còn **~200MB**, tăng tốc độ triển khai [9].
- **Render Web Services:** Dịch vụ Hosting đám mây hiện đại, tự động nhận diện `render.yaml` và liên kết với GitHub để thực hiện **CI/CD tự động** (mỗi khi `git push` mã nguồn mới lên nhánh `main`, hệ thống tự động build và redeploy) [10].

---

## 3.8. Cơ sở Lý thuyết và Thuật toán Y khoa Áp dụng

Để tính toán chính xác thể trạng người dùng ở Phân hệ Onboarding (Mục 3.2.2 - Chương 2), hệ thống áp dụng 2 nền tảng lý thuyết y khoa chuẩn hóa:

### 3.8.1. Thuật toán tính Tỷ lệ Chuyển hóa Cơ bản (BMR) - Công thức Mifflin-St Jeor

Công thức Mifflin-St Jeor (1990) [1] được các tổ chức dinh dưỡng uy tín (như Aãyademy of Nutrition and Dietetics) công nhận là công thức có độ chính xác cao nhất hiện nay để tính chỉ số BMR:

$$
\text{BMR}_{\text{Nam}} = 10 \times \text{Cân nặng (kg)} + 6.25 \times \text{Chiều cao (cm)} - 5 \times \text{Tuổi (năm)} + 5
$$

$$
\text{BMR}_{\text{Nữ}} = 10 \times \text{Cân nặng (kg)} + 6.25 \times \text{Chiều cao (cm)} - 5 \times \text{Tuổi (năm)} - 161
$$

### 3.8.2. Tổng Năng lượng Tiêu hao Hàng ngày (TDEE) & Đơn vị MET

- **TDEE** được tính bằng tích giữa BMR và hệ số hoạt động thể chất ($PAL$ - Physical Activity Level):

$$
\text{TDEE} = \text{BMR} \times PAL
$$

- **Calo tiêu hao bài tập dựa trên chỉ số MET (Metabolic Equivalent of Task):** Áp dụng bảng chỉ số chuẩn hóa từ *Compendium of Physical Activities* [2]:

$$
\text{Calo tiêu thụ (kcal)} = \text{MET} \times \text{Cân nặng (kg)} \times \left(\frac{\text{Thời gian tập (phút)}}{60}\right)
$$

---

## DANH MỤC TÀI LIỆU THAM KHẢO (REFERENCES)

[1] M. D. Mifflin, S. T. St Jeor, L. A. Hill, B. J. Scott, S. A. Daugherty, and Y. O. Koh, "A new predictive equation for resting energy expenditure in healthy individuals," *The American Journal of Clinical Nutrition*, vol. 51, no. 2, pp. 241–247, 1990.

[2] B. E. Ainsworth et al., "2011 Compendium of Physical Activities: A second update of codes and MET values," *Medicine & Science in Sports & Exercise*, vol. 43, no. 8, pp. 1575–1581, 2011.

[3] Google, "Flutter Documentation - Architectural Overview," 2024. [Online]. Available: https://docs.flutter.dev/resources/architectural-overview.

[4] F. Angelov, "BLoC Pattern in Flutter Architecture," *Ray Wenderlich Tutorial Series*, 2023.

[5] VMware, "Spring Boot Reference Documentation (v3.2.x)," 2024. [Online]. Available: https://docs.spring.io/spring-boot/docs/current/reference/html/.

[6] The PostgreSQL Global Development Group, "PostgreSQL 15 Documentation," 2023. [Online]. Available: https://www.postgresql.org/docs/15/.

[7] Google AI for Developers, "Gemini API Overview & Prompt Engineering Guide," 2024. [Online]. Available: https://ai.google.dev/docs.

[8] Google Firebase, "Firebase Cloud Messaging Documentation," 2024. [Online]. Available: https://firebase.google.com/docs/cloud-messaging.

[9] Docker Inc., "Use multi-stage builds - Docker Docs," 2024. [Online]. Available: https://docs.docker.com/build/building/multi-stage/.

[10] Render Services Inc., "Render Application Deployment & Infrastructure Guide," 2024. [Online]. Available: https://render.com/docs.
