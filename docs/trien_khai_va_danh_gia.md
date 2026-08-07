# MÔ HÌNH VÀ CẤU HÌNH TRIỂN KHAI HỆ THỐNG

## 1. Mô hình kiến trúc triển khai (Deployment Architecture)

Để đảm bảo khả năng vận hành độc lập, tính mở rộng và khả năng bảo trì hệ thống, ứng dụng **BodyPilot** được tổ chức triển khai theo mô hình đa tầng **Client - Cloud Server - Managed Database** kết hợp với các dịch vụ đám mây bên thứ ba (Third-party Cloud Services).

```
[ TẦNG CLIENT / THIẾT BỊ NGƯỜI DÙNG ]            [ TẦNG SERVER ĐÁM MÂY (RENDER CLOUD) ]
  ┌─────────────────────────────────┐               ┌─────────────────────────────────┐
  │  Thiết bị Di động Android       │               │  Render Cloud Platform          │
  │  (Tệp cài đặt app-release.apk)  │               │  (Khu vực Singapore)            │
  └────────────────┬────────────────┘               │  ┌───────────────────────────┐  │
                   │                                │  │ BodyPilot REST API Service│  │
                   │    Giao thức HTTPS / REST API  │  │ (Docker Container - Java) │  │
                   ├───────────────────────────────►│  └─────────────┬─────────────┘  │
                   │                                │                │                │
  ┌────────────────┴────────────────┐               │                │ Kết nối JDBC   │
  │  Trình duyệt Web Quản trị       │               │  ┌─────────────▼─────────────┐  │
  │  (Admin Web Host - Desktop/PC)  │               │  │ PostgreSQL Cloud Database │  │
  └─────────────────────────────────┘               │  └───────────────────────────┘  │
                                                    └─────────────────────────────────┘
                                                                     │
                                                    [ DỊCH VỤ TÍCH HỢP BÊN NGOÀI ]
                                                    ┌─────────────────────────────────┐
                                                    │ ✦ Google Gemini 2.5 Flash API   │
                                                    │ ✦ Firebase Cloud Messaging (FCM)│
                                                    │ ✦ Cổng thanh toán PayOS API     │
                                                    └─────────────────────────────────┘
```

---

## 2. Đặc tả cấu hình máy chủ và thiết bị triển khai

### 2.1. Cấu hình Máy chủ Backend REST API (`bodypilot-backend`)
- **Nền tảng triển khai (Cloud Host):** Render Cloud Platform (`render.yaml`).
- **Vùng địa lý máy chủ (Region):** Singapore (`ap-southeast-1`) - Giúp tối ưu độ trễ truyền dữ liệu cho người dùng tại Việt Nam.
- **Môi trường đóng gói:** Docker Container (sử dụng Base Image `eclipse-temurin:17-jdk-alpine` tối ưu dung lượng).
- **Cấu hình phần cứng виртуальный (Virtual Hardware Spec):**
  - **CPU:** 1 vCPU Shared.
  - **Bộ nhớ RAM:** 512 MB - 1 GB (Tự động co giãn theo lưu lượng request).
  - **Hệ điều hành:** Alpine Linux 64-bit.
  - **Môi trường thực thi:** Java Runtime Environment (JRE 17).
  - **Cấu hình cổng dịch vụ:** Port `8080` lắng nghe giao tiếp HTTP/HTTPS.
  - **Quản lý biến môi trường (Environment Variables):** Cấu hình bảo mật qua các khóa `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME`, `SPRING_DATASOURCE_PASSWORD`, `JWT_SECRET_KEY`, `GEMINI_API_KEY`, và `GOOGLE_CLIENT_ID`.

---

### 2.2. Cấu hình Máy chủ Cơ sở dữ liệu (PostgreSQL Database)
- **Hệ quản trị cơ sở dữ liệu:** PostgreSQL Server (Phiên bản 16.x).
- **Mô hình triển khai:** Managed Cloud Database Instance.
- **Phương thức kết nối:** Kết nối từ xa qua JDBC với chế độ mã hóa đường truyền SSL (`sslmode=require`).
- **Dung lượng lưu trữ:** 1 GB SSD Storage.
- **Cấu hình Bảng mã & Múi giờ:** Mã hóa văn bản `UTF-8` (hỗ trợ lưu trữ dữ liệu món ăn tiếng Việt có dấu) và múi giờ hệ thống `Asia/Ho_Chi_Minh` (+7).

---

### 2.3. Cấu hình Thiết bị thử nghiệm Ứng dụng Di động (Mobile App Client)
- **Phương thức cài đặt thử nghiệm:** Đóng gói thành tệp cài đặt `app-release.apk` và cài đặt trực tiếp lên thiết bị di động Android vật lý.
- **Yêu cầu cấu hình phần cứng thiết bị tối thiểu (Minimum Specs):**
  - **Hệ điều hành:** Android 5.0 (Lollipop - API Level 21) trở lên.
  - **Bộ nhớ RAM:** Tối thiểu 2 GB RAM (Khuyến nghị 4 GB RAM trở lên).
  - **Dung lượng bộ nhớ trống:** Tối thiểu 100 MB.
  - **Kết nối mạng:** Wi-Fi hoặc dữ liệu di động 3G/4G/5G để đồng bộ dữ liệu với Backend.
- **Thiết bị cài đặt thử nghiệm đại diện:** Điện thoại thông minh Android thế hệ mới (màn hình Full HD+, tỉ lệ 19.5:9, hỗ trợ cảm biến gia tốc kế để đo bước chân).

---

### 2.4. Cấu hình Môi trường Web Quản trị (Admin Web Host)
- **Nền tảng triển khai:** Web Static Hosting Server (triển khai mã nguồn thư mục `build/web/`).
- **Công nghệ Frontend:** Flutter Web Engine (Sử dụng WebAssembly / HTML Canvas Renderer).
- **Trình duyệt Web hỗ trợ:** Google Chrome (v100+), Microsoft Edge, Mozilla Firefox, Safari.
- **Độ phân giải hiển thị tối ưu:** Màn hình máy tính mỏng Desktop / Laptop từ 13.3 inch trở lên (Độ phân giải Full HD $1920 \times 1080$ pixels).
