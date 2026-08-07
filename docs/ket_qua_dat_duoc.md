# KẾT QUẢ ĐẠT ĐƯỢC VÀ THỐNG KÊ ỨNG DỤNG

## 1. Mô tả kết quả đạt được và sản phẩm đóng gói

Sau quá trình nghiên cứu, thiết kế và phát triển, hệ thống hỗ trợ quản lý sức khỏe và dinh dưỡng cá nhân hóa **BodyPilot** đã hoàn thành đầy đủ các mục tiêu đề ra. Toàn bộ hệ thống được đóng gói thành các sản phẩm phần mềm độc lập, hoàn chỉnh và có khả năng triển khai thực tế trên hạ tầng sản xuất (Production Environment).

### 1.1. Các sản phẩm phần mềm được đóng gói

```
                       HỆ THỐNG DỰ ÁN BODYPILOT
                                  │
    ┌─────────────────────────────┼─────────────────────────────┐
    ▼                             ▼                             ▼
Ứng dụng Di động             Hệ thống Backend API        Trang Web Quản trị
(BodyPilot Mobile)           (BodyPilot Backend)          (Admin Web Dashboard)
- Tệp đóng gói:              - Tệp đóng gói:              - Tệp đóng gói:
  `app-release.apk`            `backend-0.0.1.jar`          Tệp tĩnh `build/web/`
  `app-release.aab`            Container `Dockerfile`       (HTML, JS, Canvas)
- Vai trò: Giao diện         - Vai trò: Xử lý nghiệp      - Vai trò: Quản lý
  người dùng cuối (Android)    vụ, tính toán & AI           hệ thống & nội dung
```

#### 1. Ứng dụng Di động (BodyPilot Mobile Application)

- **Sản phẩm đóng gói:**
  - File cài đặt Android: `app-release.apk` (Dùng để cài đặt trực tiếp lên thiết bị Android).
  - Gói phân phối Google Play: `app-release.aab` (Android App Bundle tối ưu hóa tải về).
- **Thành phần bao gồm:** Giao diện người dùng (UI Screens/Widgets), các BLoC State Notifiers, bộ lưu cache local (Shared Preferences / SQLite), trình phát video hướng dẫn bài tập, công cụ tính calo tự động và bộ tích hợp Firebase Cloud Messaging (FCM).
- **Ý nghĩa & Vai trò:** Là cổng giao tiếp trực tiếp với người dùng cuối (End-users) trên nền tảng Android, cho phép người dùng ghi nhật ký ăn uống, theo dõi chỉ số calo, thực hiện bài tập và nhận tư vấn dinh dưỡng thông minh từ AI mọi lúc mọi nơi.

#### 2. Hệ thống RESTful API Backend (BodyPilot Backend Service)

- **Sản phẩm đóng gói:**
  - File ứng dụng thực thi Java: `backend-0.0.1-SNAPSHOT.jar` (Executable Fat JAR).
  - Container Image: `Dockerfile` sẵn sàng triển khai trên nền tảng đám mây (Render / AWS / Docker Hub).
- **Thành phần bao gồm:** Tầng tiếp nhận API Controllers, tầng xử lý nghiệp vụ Services (tính toán BMR, TDEE, Calo nạp/đốt), tầng bảo mật JWT & Spring Security, bộ tích hợp Google Gemini AI SDK, Meilisearch Engine và kết nối Database PostgreSQL.
- **Ý nghĩa & Vai trò:** Là bộ não trung tâm của toàn bộ hệ thống. Đảm bảo tính toán chính xác các chỉ số sinh học, lưu trữ dữ liệu an toàn, xử lý các tác vụ AI phức tạp và cung cấp API chuẩn hóa cho cả Mobile App và Web Admin.

#### 3. Trang Web Quản trị (BodyPilot Admin Web Dashboard)

- **Sản phẩm đóng gói:** Thư mục mã nguồn tĩnh `build/web/` (gồm `index.html`, `main.dart.js` và các tài nguyên đính kèm).
- **Thành phần bao gồm:** Giao diện quản lý danh mục thực phẩm, danh mục bài tập, bảng thống kê người dùng, quản lý báo cáo vi phạm và bộ công cụ theo dõi hiệu năng hệ thống.
- **Ý nghĩa & Vai trò:** Cung cấp công cụ quản trị tập trung cho Quản trị viên (Admin), giúp kiểm soát chất lượng dữ liệu món ăn, cập nhật thư viện bài tập và theo dõi số lượng người dùng kích hoạt.

#### 4. Kịch bản SQL và Tập dữ liệu khởi tạo (Database Migration & Datasets)

- **Sản phẩm đóng gói:**
  - Các kịch bản SQL khởi tạo & cập nhật cấu trúc: `workout_init.sql`, `allergy_migration.sql`, `health_injuries_schema.sql`, `preferences_migration.sql`.
  - Bộ dữ liệu mồi chuẩn hóa: `exercises.csv` (Danh mục bài tập) và `opennutrition_foods.csv` (Thư viện dinh dưỡng món ăn thực tế).
- **Thành phần bao gồm:** Cấu trúc các bảng dữ liệu chuẩn hóa 3NF và hàng ngàn bản ghi thực phẩm/bài tập mẫu được tiền xử lý sẵn.
- **Ý nghĩa & Vai trò:** Nạp sẵn cơ sở dữ liệu mẫu phong phú về thực phẩm Việt Nam và bài tập thể hình, đảm bảo hệ thống có thể đi vào hoạt động ngay sau khi triển khai.

---

## 2. Thống kê thông tin quy mô ứng dụng

Dưới đây là các bảng thống kê chi tiết về số lượng dòng code (Lines of Code - LOC), số lượng lớp (Classes), số lượng gói (Packages), dung lượng mã nguồn và dung lượng các sản phẩm phần mềm đóng gói của hệ thống **BodyPilot**.

### Bảng 1. Thống kê tổng quan quy mô mã nguồn hệ thống BodyPilot (Đo đếm bằng VSCodeCounter)

|       STT       | Thành phần Module / Ngôn ngữ                      | Số lượng Tệp / Lớp | Dòng Code thuần (Code Lines) | Chú thích (Comment Lines) | Dòng trống (Blank Lines) | Tổng số dòng (Total Lines) |
| :-------------: | :---------------------------------------------------- | :---------------------: | :----------------------------: | :-------------------------: | :------------------------: | :---------------------------: |
|        1        | **Backend REST API (Java)**                     |        204 lớp        |             9,072             |             104             |           1,816           |       **10,992**       |
|        2        | **Frontend Client (Dart - Mobile & Admin Web)** |        195 tệp        |             32,830             |             367             |           2,568           |       **35,765**       |
| **TỔNG** | **Toàn bộ hệ thống BodyPilot**              | **399 tệp/lớp** |     **41,902 dòng**     |     **471 dòng**     |   **4,384 dòng**   |    **46,757 dòng**    |

*Ghi chú thống kê:*

- Số liệu được đo đếm tự động bằng công cụ **VSCodeCounter** trên các tệp nguồn `.java` và `.dart` của toàn bộ workspace dự án BodyPilot.

---

### Bảng 2. Thống kê dung lượng các sản phẩm phần mềm được đóng gói (Build Artifacts)

| STT | Tên sản phẩm đóng gói                     |           Định dạng Tệp           | Môi trường triển khai             | Dung lượng tệp đóng gói |
| :-: | :---------------------------------------------- | :-----------------------------------: | :------------------------------------ | :---------------------------: |
|  1  | **Android Application Package (APK)**     |               `.apk`               | Thiết bị Android (v5.0 trở lên)   |       **28.5 MB**       |
|  2  | **Android App Bundle (AAB)**              |               `.aab`               | Google Play Store Distribution        |       **22.0 MB**       |
|  3  | **Backend Executable Fat JAR**            |               `.jar`               | OpenJDK 17 Runtime Environment        |       **35.0 MB**       |
|  4  | **Admin Web Production Bundle**           |          Folder`build/web`          | Web Server (Nginx / Cloudflare Pages) |       **14.8 MB**       |
|  5  | **SQL Migration & Schema Scripts**        | `.sql` (`workout_init.sql`, v.v.) | PostgreSQL Database Server            |       **15.6 KB**       |
|  6  | **Seeding Nutrition & Exercise Datasets** |  `.csv` (`exercises.csv`, v.v.)  | Database Ingestion Tools              |       **7.4 MB**       |
