# YÊU CẦU PHI CHỨC NĂNG VÀ CÔNG NGHỆ HỆ THỐNG BODYPILOT

Tài liệu này xác định các **Yêu cầu phi chức năng (Non-Functional Requirements - NFR)** và các **Yêu cầu kỹ thuật** cốt lõi nhằm đảm bảo chất lượng, hiệu năng, tính an toàn, tính dễ bảo trì và độ ổn định cho toàn bộ hệ sinh thái ứng dụng **BodyPilot**.

---

## 1. Yêu cầu về Hiệu năng (Performance Requirements)

- **Thời gian phản hồi API (Response Time):**
  - Đối với các truy vấn CRUD thông thường (đăng nhập, tìm kiếm thực phẩm, ghi nhật ký ăn uống/tập luyện, điểm danh): Thời gian phản hồi của Backend API đạt **< 1.5 - 2.0 giây** trong điều kiện mạng bình thường.
  - Đối với các chức năng AI phản hồi ngắn (Smart Swap đổi món, AI Chatbot trò chuyện tư vấn): Thời gian phản hồi đạt từ **3 đến 15 giây**.
  - Đối với chức năng **Sinh thực đơn 7 ngày AI chi tiết** (chứa hơn 28 bữa ăn thuần Việt, thông số dinh dưỡng, nguyên liệu và định lượng): Do độ phức tạp tính toán y khoa kết hợp suy luận mô hình ngôn ngữ lớn (LLM) và ép định dạng JSON Schema, thời gian xử lý và trả lời thực tế dao động từ **3 đến 5 phút (180 - 300 giây)**.
  - **Tối ưu trải nghiệm chờ tải (Loading State UX):** Trong suốt thời gian 3-5 phút chờ AI sinh thực đơn, ứng dụng di động hiển thị bộ đếm giờ kết hợp giao diện chuyển bước tự động (*Progressive 4-Step Loading Animation*) để giải thích trạng thái xử lý cho người dùng:
    1. *Bước 1:* Phân tích chỉ số & mục tiêu calo.
    2. *Bước 2:* Kiểm tra dị ứng & kiêng kỵ bệnh lý.
    3. *Bước 3:* Lọc danh sách thực phẩm Việt Nam.
    4. *Bước 4:* AI tính toán & hoàn thiện thực đơn chi tiết.
- **Tốc độ khởi động ứng dụng (Startup Time):**
  - Ứng dụng di động (Mobile Client) hoàn tất tải trang chính (Dashboard) trong vòng **< 2 giây** đối với các thiết bị di động Android và iOS thông dụng.
- **Tốc độ khung hình (Frame Rate):**
  - Giao diện di động Flutter duy trì tốc độ khung hình ổn định từ **60 FPS trở lên**, không xảy ra hiện tượng giật lag (*jank*) khi cuộn danh sách bài tập/thực phẩm hoặc chuyển đổi giữa các tab.
- **Tối ưu hóa điện năng và tài nguyên phần cứng (Resource Efficiency):**
  - Tính năng đếm bước chân tự động (*Hardware Step Counter*) chạy nền bằng cảm biến Pedometer tích hợp của thiết bị, mức tiêu thụ pin tăng thêm không quá **1% - 2% mỗi 24 giờ**.

---

## 2. Yêu cầu về Độ tin cậy và Độ sẵn sàng (Reliability & Availability)

- **Độ sẵn sàng hệ thống (Availability):**
  - Hệ thống Backend API và Database đảm bảo chỉ số sẵn sàng đạt **99.5%** (cho phép thời gian bảo trì tối đa không quá 3.6 giờ/tháng).
- **Cấu hình Thời gian chờ & Chịu lỗi (Network Timeout & Circuit Breaker):**
  - Cấu hình thời gian chờ phản hồi HTTP (`receiveTimeout`) của client được thiết lập ở mức **300 giây (5 phút)** dành riêng cho các tác vụ sinh thực đơn AI phức tạp.
  - Khi dịch vụ AI bên ngoài bị gián đoạn hoặc vượt quá thời gian 300 giây, hệ thống tự động ngắt kết nối an toàn (*Circuit Breaker*), bảo toàn thông tin thể trạng đã chọn và hiển thị thông báo lỗi thân thiện khuyên người dùng thử lại sau mà không làm treo hay sập ứng dụng.
  - Dữ liệu tiến trình khảo sát dở dang (`current_assessment`) và lịch sử trò chuyện AI Coach được tự động lưu trữ cục bộ (*Hive Local Cache*) trên điện thoại, đảm bảo không bị mất dữ liệu khi mất kết nối mạng.
- **Độ chuẩn xác của tính toán (Accuracy):**
  - Thuật toán tính toán các chỉ số BMR (Mifflin-St Jeor), TDEE, BMI và Calo tiêu thụ dựa trên chỉ số MET đảm bảo tính toán chuẩn xác 100% theo các công thức y khoa chuẩn hóa.

---

## 3. Yêu cầu về An toàn và Bảo mật (Security & Privacy)

- **Xác thực và Phân quyền (Authentication & Authorization):**
  - Sử dụng chuẩn xác thực **JSON Web Token (JWT)** mã hóa với thuật toán `HS256`/`RS256` và chuỗi mã bí mật (*Secret Key*) độ dài tối thiểu 256-bit.
  - Phân quyền chặt chẽ các cấp độ người dùng (`ROLE_USER` và `ROLE_ADMIN`). Mọi yêu cầu truy cập tài nguyên private phải kiểm tra tính hợp lệ của token trong Header `Authorization: Bearer <token>`.
- **Mã hóa Dữ liệu (Data Encryption):**
  - Mọi luồng truyền tải dữ liệu giữa Client, Backend Server, Cơ sở dữ liệu Supabase PostgreSQL và Gemini AI API phải bắt buộc chạy qua mã hóa **HTTPS / TLS 1.3**.
  - Mật khẩu người dùng lưu trữ trong cơ sở dữ liệu phải được băm an toàn bằng thuật toán **BCrypt** kèm theo salt ngẫu nhiên.
- **Bảo mật Thông tin Bí mật (Secrets Management):**
  - Tuyệt đối không để lọt API Keys (Gemini Key, Groq Key, JWT Secret, Firebase Credentials) vào mã nguồn đẩy lên Git Repository (tuân thủ cơ chế *GitHub Push Protection*). Toàn bộ được quản lý qua biến môi trường (*Environment Variables*) trên đám mây.

---

## 4. Yêu cầu về Tính dễ sử dụng (Usability & User Experience)

- **Giao diện hiện đại và Thuần Việt (Localization & Aesthetics):**
  - Ngôn ngữ hiển thị mặc định là **Tiếng Việt 100%**, câu chữ gần gũi, các thuật ngữ chuyên môn (như Calo, Protein, Carbs, Fat, MET, TDEE) được giải thích rõ ràng.
  - Thiết kế UI/UX hiện đại theo xu hướng *Glassmorphism/Dark mode Accent*, màu sắc hài hòa, font chữ tiêu chuẩn (*Google Fonts Work Sans/Inter*), mang lại cảm giác cao cấp.
- **Tính khả dụng & Thao tác tối thiểu (Ease of Operation):**
  - Quy trình Onboarding khảo sát thể trạng 12 bước được chia nhỏ trực quan kèm thanh tiến độ (*Progress bar*), người dùng chỉ cần thao tác chạm chọn (*Choice Chips/Cards*) tối đa 2-3 phút là hoàn thành.
  - Chức năng tìm kiếm món ăn và bài tập hỗ trợ cơ chế lọc thông minh, hiển thị kết quả gợi ý tức thì sau khi gõ từ 2 ký tự.

---

## 5. Yêu cầu về Tính dễ bảo trì và Mở rộng (Maintainability & Scalability)

- **Kiến trúc Mã nguồn Chuẩn hóa (Clean Architecture):**
  - **Mobile Client:** Xây dựng theo mô hình **BLoC / Cubit State Management** phân tách rõ ràng giữa giao diện (Presentation), logic nghiệp vụ (Bloc), kho dữ liệu (Repository) và kết nối mạng (Data Services).
  - **Backend Server:** Áp dụng mô hình chuẩn 3 lớp (**Controller - Service - Repository**) của Spring Boot, giúp dễ dàng nâng cấp hoặc thay thế từng module riêng biệt.
- **Khả năng mở rộng quy mô (Scalability):**
  - Ứng dụng Backend được đóng gói dưới dạng container hóa **Docker Multi-Stage Build**, cho phép dễ dàng mở rộng quy mô theo chiều ngang (*Horizontal Scaling*) trên các dịch vụ đám mây (như Render, AWS, Kubernetes).
- **Khả năng bảo trì cơ sở dữ liệu (Database Maintainability):**
  - Sử dụng **Spring Data JPA / Hibernate** tự động quản lý thực thể dữ liệu, đảm bảo mã nguồn độc lập với hệ quản trị CSDL bên dưới.

---

## 6. Yêu cầu Kỹ thuật và Công nghệ Sử dụng (Technical Stack & Database)

| Thành phần hệ thống | Công nghệ / Thư viện lựa chọn | Ràng buộc & Thông số kỹ thuật |
| :--- | :--- | :--- |
| **Mobile Client App** | **Flutter SDK (Dart 3.x)** | Biên dịch Native cho Android (Android 5.0 / API 21+) và iOS (iOS 13.0+). |
| **Admin Web Dashboard** | **Flutter Web (Dart)** | Tương thích mượt mà trên các trình duyệt hiện đại (Chrome, Firefox, Edge, Safari). |
| **Backend API Framework** | **Java 17 / Spring Boot 3.x** | Xây dựng RESTful APIs theo chuẩn JSON, bảo mật Spring Security 6.x. |
| **Hệ quản trị CSDL** | **PostgreSQL v15+ (Supabase Cloud)** | Lưu trữ cấu trúc Relational DB, hỗ trợ các ràng buộc khóa ngoại (FK) và Index truy vấn nhanh. |
| **Mô hình Trí tuệ Nhân tạo** | **Google Gemini API (`gemini-2.5-flash`)** | Tương tác qua REST API, sử dụng cấu trúc JSON Schema linh hoạt cho phản hồi AI. |
| **Dịch vụ Thông báo Push** | **Firebase Admin SDK (FCM)** | Đẩy thông báo tức thì (*Realtime Push Notification*) đa nền tảng. |
| **Container & Cloud Deploy** | **Docker & Render Web Services** | Đóng gói môi trường thực thi nhẹ, tự động triển khai CI/CD qua GitHub Integration. |
