# Software Requirements Specification (SRS)

## For BodyPilot

Version 1.0  
Prepared by: Vũ Đặng  
Date: 2026-07-17  

---

## Table of Contents

<!-- TOC -->
* [1. Introduction](#1-introduction)
  * [1.1 Document Purpose](#11-document-purpose)
  * [1.2 Product Scope](#12-product-scope)
  * [1.3 Definitions, Acronyms, and Abbreviations](#13-definitions-acronyms-and-abbreviations)
  * [1.4 References](#14-references)
  * [1.5 Document Overview](#15-document-overview)
* [2. Product Overview](#2-product-overview)
  * [2.1 Product Perspective](#21-product-perspective)
  * [2.2 Product Functions](#22-product-functions)
  * [2.3 Product Constraints](#23-product-constraints)
  * [2.4 User Characteristics](#24-user-characteristics)
  * [2.5 Assumptions and Dependencies](#25-assumptions-and-dependencies)
  * [2.6 Apportioning of Requirements](#26-apportioning-of-requirements)
* [3. Requirements](#3-requirements)
  * [3.1 External Interfaces](#31-external-interfaces)
  * [3.2 Functional Requirements](#32-functional-requirements)
  * [3.3 Quality of Service](#33-quality-of-service)
  * [3.4 Compliance](#34-compliance)
  * [3.5 Design and Implementation Constraints](#35-design-and-implementation-constraints)
  * [3.6 AI/ML Integration](#36-aiml-integration)
* [4. Verification](#4-verification)
* [5. Appendixes](#5-appendixes)
<!-- TOC -->

---

## Revision History

| Name | Date | Reason For Changes | Version |
| :--- | :--- | :--- | :--- |
| Vũ Đặng | 2026-04-14 | Initial draft | 0.1 |
| Vũ Đặng | 2026-07-17 | Rebrand to BodyPilot, align assessment flow & AI integration, define Admin Web and complete entities. | 1.0 |

---

## 1. Introduction

### 1.1 Document Purpose
Tài liệu Đặc tả Yêu cầu Phần mềm (SRS) này mô tả toàn bộ các yêu cầu chức năng, phi chức năng và kiến trúc hệ thống của **BodyPilot** (tiền thân là NutriFit AI). Tài liệu này làm cơ sở kỹ thuật cho đội ngũ thiết kế giao diện, lập trình viên phát triển frontend/backend, kiểm thử viên (QA/QC) và đối tác liên quan trong suốt quá trình hoàn thiện dự án.

### 1.2 Product Scope
**BodyPilot** là một hệ sinh thái hỗ trợ quản lý sức khỏe, dinh dưỡng và luyện tập cá nhân hóa thông qua Trí tuệ Nhân tạo (AI). Hệ thống bao gồm:
1. **Ứng dụng di động (BodyPilot Mobile Client)**: Giúp người dùng thực hiện khảo sát thể trạng đầu vào (Assessment Onboarding), theo dõi nhật ký ăn uống hàng ngày, thực hiện các bài tập có bộ đếm thời gian hướng dẫn, và nhận các gợi ý thực đơn/lịch tập tự động được cá nhân hóa cao thông qua mô hình Generative AI (Gemini).
2. **Hệ thống Quản trị Web (BodyPilot Admin Dashboard)**: Dành cho quản trị viên hệ thống để theo dõi số lượng người dùng, quản lý danh mục bài tập, nguyên liệu và các công thức món ăn (Dishes).
3. **Backend API Server**: Xử lý logic nghiệp vụ, tính toán năng lượng (BMR, TDEE, macros), tích hợp mô hình Gemini AI và lưu trữ dữ liệu tập trung qua PostgreSQL.

### 1.3 Definitions, Acronyms, and Abbreviations

| Thuật ngữ | Định nghĩa |
| :--- | :--- |
| **BMR** | Basal Metabolic Rate - Lượng calo tiêu thụ tối thiểu để cơ thể duy trì sự sống khi nghỉ ngơi hoàn toàn. |
| **TDEE** | Total Daily Energy Expenditure - Tổng số năng lượng một người tiêu thụ trong một ngày, tính cả các hoạt động thể chất. |
| **BMI** | Body Mass Index - Chỉ số khối cơ thể, đo mức độ gầy hay béo dựa trên chiều cao và cân nặng. |
| **MET** | Metabolic Equivalent of Task - Đơn vị tương đương chuyển hóa, dùng để đo lượng calo tiêu hao khi thực hiện các bài tập thể chất. |
| **JWT** | JSON Web Token - Phương thức xác thực an toàn dạng token mã hóa giữa client và server. |
| **Gemini AI** | Mô hình ngôn ngữ lớn (LLM) của Google, được BodyPilot sử dụng thông qua API để tạo các đề xuất thông minh. |

### 1.4 References
- *Mifflin, M. D., St Jeor, S. T., et al. (1990). A new predictive equation for resting energy expenditure in healthy individuals.*
- *Flutter Documentation & Clean Architecture Guidelines.*
- *Spring Boot Core Specifications & Spring Security Architecture.*
- *Google Gemini API Documentation (Model `gemini-2.5-flash`).*

### 1.5 Document Overview
Tài liệu bao gồm:
- **Phần 2**: Mô tả tổng quan về sản phẩm, các phân hệ chức năng chính, ràng buộc hệ thống và các đối tượng người dùng.
- **Phần 3**: Chi tiết các yêu cầu về giao diện, luồng xử lý chức năng (bao gồm quy trình khảo sát 12 bước), các yêu cầu phi chức năng và tích hợp AI.
- **Phần 4**: Kế hoạch kiểm chứng (Verification Matrix) cho các yêu cầu chức năng cốt lõi.

---

## 2. Product Overview

### 2.1 Product Perspective
BodyPilot được xây dựng dưới cấu trúc Client-Server hiện đại:
- **Client**: Viết bằng Flutter (Dart) biên dịch Native sang ứng dụng di động Android/iOS, kết hợp Flutter Web dành cho Admin.
- **Server**: Viết bằng Spring Boot (Java), giao tiếp RESTful API qua định dạng JSON.
- **Database**: PostgreSQL lưu trữ trên nền tảng đám mây Supabase.
- **AI Engine**: Google Gemini API phục vụ suy luận tự động.

```
+---------------------------+        +--------------------------+
|  BodyPilot Mobile Client  |        |  BodyPilot Admin Web     |
|     (Flutter - Mobile)    |        |     (Flutter - Web)      |
+-------------+-------------+        +------------+-------------+
              |                                   |
              +-----------------+-----------------+
                                | (HTTPS / REST)
                                v
                +---------------+---------------+
                |     Spring Boot Backend       |
                |         (Java REST)           |
                +-------+---------------+-------+
                        |               |
             (SQL)      |               | (JSON API)
                        v               v
            +-----------+---+       +---+-----------+
            |  PostgreSQL   |       |  Google API   |
            |  (Supabase)   |       | (Gemini 2.5)  |
            +---------------+       +---------------+
```

### 2.2 Product Functions
Hệ thống cung cấp các nhóm chức năng chính như sau:
1. **Xác thực & Quản lý Tài khoản (Auth & Profiles)**: Đăng ký, đăng nhập, bảo mật tài khoản bằng JWT và quản lý hồ sơ người dùng.
2. **Khảo sát Thể trạng Ban đầu (Onboarding Assessment)**: Tiến trình 12 bước thu thập thông tin chỉ số sinh trắc học và lịch sử sức khỏe.
3. **Theo dõi Dinh dưỡng & Nhật ký Ăn uống (Meal & Nutrition Logs)**: Lưu nhật ký 4 bữa ăn trong ngày, tính toán lượng calo và macros thực tế so với mục tiêu.
4. **Đề xuất Dinh dưỡng bằng AI (AI Diet Suggestions)**: Tạo thực đơn hàng tuần tự động bằng Gemini AI, loại bỏ thực phẩm gây dị ứng hoặc không ưa thích của người dùng.
5. **Theo dõi & Thiết kế Lộ trình Luyện tập (Workout Programs & Logs)**: Xem danh mục bài tập, thực hiện bài tập bằng màn hình hướng dẫn tích hợp bộ đếm giờ, lưu nhật ký số sets/reps và tính calo tiêu hao dựa trên chỉ số MET.
6. **Đề xuất Lịch tập bằng AI (AI Workout Suggestions)**: Sử dụng Gemini AI thiết lập giáo án luyện tập dựa trên mục tiêu thể hình và tình trạng chấn thương thực tế.
7. **Quản trị Hệ thống Web (Admin Dashboard)**: Giúp Admin quản lý danh sách món ăn, nguyên liệu, bài tập và theo dõi số liệu người dùng.

### 2.3 Product Constraints
- Giao diện di động phải tối ưu hóa cho màn hình cảm ứng, chạy mượt mà trên hệ điều hành Android (từ SDK 21 trở lên) và iOS (từ iOS 13 trở lên).
- Giao diện Admin Web phải đáp ứng hiển thị tương thích tốt trên Chrome, Firefox và Safari.
- Thời gian phản hồi của backend đối với các truy vấn thông thường phải dưới 1.5 giây. Đối với các yêu cầu tạo đề xuất từ AI (Gemini), thời gian xử lý và trả về dữ liệu phải được tối ưu trong vòng 5-8 giây kèm hiệu ứng chờ tải (loading state) trên ứng dụng.

### 2.4 User Characteristics
- **Người dùng cá nhân (End Users)**: Mong muốn theo dõi cân nặng, tìm kiếm thực đơn ăn uống khoa học, rèn luyện thể chất cá nhân hóa theo mục tiêu và thể trạng riêng, có thể có bệnh lý nền hoặc chấn thương cần tránh.
- **Quản trị viên (Admin)**: Người kiểm duyệt và nhập liệu cơ sở dữ liệu thực phẩm, món ăn, bài tập mẫu và giám sát hoạt động của ứng dụng.

### 2.5 Assumptions and Dependencies
- Người dùng cung cấp chính xác các chỉ số sinh trắc học cá nhân.
- Hệ thống phụ thuộc vào tính sẵn sàng của kết nối Internet và dịch vụ Gemini API của Google.

### 2.6 Apportioning of Requirements
- Giai đoạn 1: Triển khai toàn bộ khung ứng dụng, phân hệ khảo sát thể trạng, quản lý bài tập/món ăn tĩnh và bộ khung API Spring Boot kết nối Supabase.
- Giai đoạn 2: Tích hợp logic AI đề xuất thực đơn và bài tập tự động từ Gemini, bộ đếm giờ luyện tập và phát triển hoàn thiện giao diện Admin Dashboard Web.

---

## 3. Requirements

### 3.1 External Interfaces

#### 3.1.1 User Interfaces
- **Mobile Client (Flutter)**: Sử dụng các thành phần UI cao cấp, màu sắc hiện đại, hỗ trợ hiệu ứng chuyển cảnh mượt mà. Hệ thống điều hướng bằng Bottom Navigation Bar gồm: Trang chủ (Dashboard), Dinh dưỡng (Meal/Food), Luyện tập (Workout), Hồ sơ (Profile).
- **Admin Dashboard (Flutter Web)**: Giao diện kiểu bảng điều khiển (Sidebar Navigation Layout), hỗ trợ xem biểu đồ và quản lý bảng dữ liệu trực quan.

#### 3.1.2 Software Interfaces
- **Cơ sở dữ liệu (DBMS)**: PostgreSQL v15+.
- **Generative AI API**: Google Gemini v1beta REST API (Model `gemini-2.5-flash`).
- **Giao thức mạng**: HTTPS cho toàn bộ API endpoints, đảm bảo truyền tải dữ liệu người dùng an toàn.

### 3.2 Functional Requirements

#### 3.2.1 Module 1: Đăng ký & Đăng nhập (Authentication)
- **REQ-F-001 (Đăng ký)**: Người dùng đăng ký tài khoản mới bằng Email và Mật khẩu (yêu cầu độ dài tối thiểu 6 ký tự).
- **REQ-F-002 (Đăng nhập)**: Xác thực người dùng bằng Email và Mật khẩu, hệ thống trả về mã Access Token (JWT) để duy trì phiên làm việc.
- **REQ-F-003 (Đăng xuất)**: Hủy bỏ token trên thiết bị và chấm dứt phiên làm việc.

#### 3.2.2 Module 2: Khảo sát Thể trạng Ban đầu (Onboarding Assessment)
Hệ thống bắt buộc người dùng thực hiện khảo sát 12 bước sau khi tạo tài khoản để có căn cứ tính toán thể trạng:
- **Bước 1 (Mục tiêu - Goal)**: Chọn 1 trong các mục tiêu: Duy trì cân nặng (`MAINTAIN`), Giảm cân chậm (`LOSE_0_5KG`), Giảm cân nhanh (`LOSE_1KG`), Tăng cân chậm (`GAIN_0_5KG`), Tăng cân nhanh (`GAIN_1KG`), Tăng cơ (`GAIN_MUSCLE`), Lối sống lành mạnh (`HEALTHY_LIFESTYLE`), Tăng sức bền (`ENDURANCE`).
- **Bước 2 (Giới tính - Gender)**: Chọn Nam (`MALE`) hoặc Nữ (`FEMALE`).
- **Bước 3 (Tuổi - Age)**: Nhập số tuổi hiện tại.
- **Bước 4 (Chiều cao - Height)**: Nhập chiều cao bằng đơn vị Centimet (cm).
- **Bước 5 (Cân nặng hiện tại - Current Weight)**: Nhập cân nặng hiện tại bằng đơn vị Kilogam (kg).
- **Bước 6 (Cân nặng mục tiêu - Target Weight)**: Nhập cân nặng mong muốn hướng tới (kg).
- **Bước 7 (Bệnh lý nền - Health Conditions)**: Chọn từ danh sách có sẵn (Tiểu đường Type 1/Type 2, Cao huyết áp, Celiac/Dị ứng gluten, Hen suyễn, Suy giáp, Bệnh tim, Hội chứng ruột kích thích IBS) hoặc để trống.
- **Bước 8 (Chấn thương - Injuries)**: Chọn chấn thương xương khớp hiện có (Đứt dây chằng chéo trước ACL, Hội chứng bánh chè đùi, Đau lưng dưới, Thoát vị đĩa đệm, Chèn ép khớp vai, Rách chóp xoay, Viêm lồi cầu Tennis elbow, Bong gân cổ chân) để AI giới hạn bài tập.
- **Bước 9 (Dị ứng thực phẩm - Allergies)**: Chọn các nhóm chất gây dị ứng (Sữa, Trứng, Cá, Động vật có vỏ, Đậu phộng, Quả hạch, Đậu nành, Gluten, Vừng/Mè) để loại bỏ khỏi thực đơn.
- **Bước 10 (Kinh nghiệm tập luyện - Workout Experience)**: Chọn trạng thái đã có kinh nghiệm luyện tập thể hình trước đây hay chưa (`hasExperience = true/false`).
- **Bước 11 (Mức độ hoạt động - Activity Level)**: Chọn mức độ vận động hàng ngày gồm:
  - Thụ động (`SEDENTARY`, hệ số 1.2): Làm việc văn phòng, ít vận động.
  - Vận động nhẹ (`LIGHT`, hệ số 1.375): Vận động nhẹ, tập thể dục 1-3 ngày/tuần.
  - Vận động vừa (`MODERATE`, hệ số 1.55): Tập thể dục trung bình 3-5 ngày/tuần.
  - Năng động (`ACTIVE`, hệ số 1.725): Tập luyện cường độ cao 6-7 ngày/tuần.
  - Rất năng động (`VERY_ACTIVE`, hệ số 1.9): Vận động viên hoặc công việc thể chất nặng.
- **Bước 12 (Tùy chọn ăn uống & Ngân sách - Diet & Budget)**:
  - Chọn chế độ ăn cụ thể (Keto, Vegan, Vegetarian, Low-Carb, Clean Eating, Mediterranean) hoặc Không ăn kiêng.
  - Chọn ngân sách chi tiêu cho thực phẩm (Thấp, Trung bình, Cao).
  - Chọn các nhóm thực phẩm không thích hoặc muốn tránh.

Sau khi hoàn tất, hệ thống tự động tính toán các chỉ số cơ bản cho người dùng thông qua công thức Mifflin-St Jeor:
- **BMI**: Cân nặng (kg) / [Chiều cao (m)]^2.
- **BMR**:
  - Nam: `10 * Cân nặng (kg) + 6.25 * Chiều cao (cm) - 5 * Tuổi (năm) + 5`
  - Nữ: `10 * Cân nặng (kg) + 6.25 * Chiều cao (cm) - 5 * Tuổi (năm) - 161`
- **TDEE**: `BMR * Hệ số vận động`.
- **Target Calories**: Lượng calo cần nạp hàng ngày được tăng/giảm tương ứng dựa theo mục tiêu đã chọn ở bước 1.

#### 3.2.3 Module 3: Nhật ký Dinh dưỡng (Nutrition & Meal Logs)
- **REQ-F-004 (Nhật ký ăn uống)**: Người dùng thêm món ăn đã tiêu thụ vào 4 bữa chính trong ngày: Bữa sáng (Breakfast), Bữa trưa (Lunch), Bữa tối (Dinner), Bữa phụ (Snack).
- **REQ-F-005 (Tìm kiếm thực phẩm)**: Tìm kiếm món ăn hoặc nguyên liệu trong cơ sở dữ liệu hệ thống kèm thông số calo và macros trên 100g.
- **REQ-F-006 (Gợi ý thực đơn bằng AI)**: Người dùng yêu cầu AI tạo thực đơn gợi ý nguyên tuần. Backend sẽ thu thập hồ sơ người dùng (Calo mục tiêu, dị ứng thực phẩm, bệnh lý nền, chế độ ăn kiêng ưu tiên và ngân sách) gửi tới Gemini API để tạo danh sách món ăn đầy đủ lượng macros phù hợp.
- **REQ-F-007 (Theo dõi Calo nạp vào)**: Hiển thị tổng Calo, Protein, Carbs, Fat đã ăn so với giới hạn mục tiêu của ngày.

#### 3.2.4 Module 4: Nhật ký Luyện tập (Workout & Exercise Logs)
- **REQ-F-008 (Xem thư viện bài tập)**: Xem danh sách các bài tập được phân loại theo nhóm cơ chính (Ngực, Đùi, Vai, Tay trước, Tay sau, Lưng, Bụng...). Xem chi tiết hướng dẫn, mô tả và thiết bị hỗ trợ của bài tập.
- **REQ-F-009 (Đề xuất lộ trình luyện tập bằng AI)**: AI (Gemini) tự động thiết kế chương trình tập luyện theo ngày/tuần. Logic lọc tự động loại trừ các bài tập tác động xấu tới chấn thương đã chọn ở bước đánh giá ban đầu (ví dụ: đau lưng dưới sẽ tránh các bài Deadlift nặng; chấn thương đầu gối ACL sẽ tránh Squats sâu hoặc bật nhảy).
- **REQ-F-010 (Thực hiện tập luyện & Hẹn giờ)**: Giao diện buổi tập cho phép người dùng chạy bộ đếm thời gian tập luyện (Workout Timer) cho mỗi set tập và thời gian nghỉ giữa các set.
- **REQ-F-011 (Nhật ký tập luyện - Workout Diary)**: Ghi lại lịch sử các bài tập đã hoàn thành, bao gồm số set, số reps thực tế và mức tạ sử dụng. Hệ thống tự tính toán lượng Calo tiêu hao dựa trên chỉ số MET của bài tập, thời gian tập và cân nặng hiện tại của người dùng theo công thức:
  `Calories tiêu hao = MET * Cân nặng (kg) * (Thời gian tập trong phút / 60)`.

#### 3.2.5 Module 5: Hồ sơ & Tiến trình (Profile & Progress)
- **REQ-F-012 (Cập nhật cân nặng)**: Ghi nhận cân nặng hiện tại mỗi ngày để theo dõi sự thay đổi.
- **REQ-F-013 (Biểu đồ tiến trình)**: Hiển thị biểu đồ trực quan về xu hướng biến động cân nặng theo tuần/tháng/năm để đánh giá mức độ hiệu quả của tiến trình so với mục tiêu đặt ra.
- **REQ-F-014 (Thông tin cá nhân)**: Cập nhật thông số chiều cao, đổi mật khẩu hoặc điều chỉnh các mục tiêu sức khỏe.

#### 3.2.6 Module 6: Hệ thống Web Quản trị (Admin Dashboard)
- **REQ-F-015 (Thống kê tổng quan)**: Hiển thị tổng số người dùng, số lượng tài khoản đăng ký mới, số liệu thống kê bài tập và món ăn hiện có.
- **REQ-F-016 (Quản lý món ăn & nguyên liệu - Dishes & Ingredients)**: Thêm, sửa, xóa (CRUD) các món ăn và nguyên liệu. Cho phép thiết lập hàm lượng calo, protein, carbs, fat, sodium, fiber, sugar trên 100g của mỗi thực phẩm và liên kết các thẻ ăn kiêng (Diet Tags).
- **REQ-F-017 (Quản lý bài tập - Exercises)**: CRUD danh mục bài tập, liên kết nhóm cơ tác động, thiết bị yêu cầu, độ khó, chỉ số MET và đính kèm video/hình ảnh hướng dẫn.
- **REQ-F-018 (Quản lý người dùng - User Management)**: Xem danh sách người dùng hệ thống, hỗ trợ khóa/mở khóa tài khoản khi có vi phạm điều khoản.

### 3.3 Quality of Service

#### 3.3.1 Security (An toàn thông tin)
- Mật khẩu người dùng bắt buộc phải được mã hóa trước khi lưu vào database sử dụng thuật toán băm bảo mật cao (như BCrypt).
- Xác thực API thông qua cơ chế JWT (JSON Web Token), mã khóa bí mật được lưu an toàn trong tệp cấu hình server. Các API liên quan đến thông tin cá nhân của người dùng bắt buộc phải có JWT hợp lệ trong tiêu đề request (Authorization Header).
- Phân quyền người dùng rõ ràng giữa vai trò Khách hàng (`ROLE_USER`) và Quản trị viên (`ROLE_ADMIN`).

#### 3.3.2 Performance (Hiệu năng hoạt động)
- Các truy vấn tìm kiếm món ăn hoặc bài tập trong cơ sở dữ liệu nội bộ phải phản hồi trong thời gian dưới 1.5s dưới điều kiện kết nối mạng thông thường.
- Cơ sở dữ liệu PostgreSQL phải được lập chỉ mục (Indexes) trên các trường tìm kiếm thường xuyên như `email`, mã bài tập `code`, tên thực phẩm `name` để tối ưu tốc độ truy vấn.

#### 3.3.3 Availability & Scalability (Độ tin cậy & Khả năng mở rộng)
- Hệ thống cơ sở dữ liệu được lưu trữ trên điện toán đám mây Supabase giúp tự động sao lưu định kỳ, bảo vệ an toàn dữ liệu người dùng.
- Cấu trúc thư mục Flutter chia tách rõ ràng theo mẫu BLoC pattern giúp dễ dàng bổ sung các tính năng mới mà không ảnh hưởng tới các luồng logic sẵn có.

### 3.4 Compliance
- Dữ liệu sức khỏe và thông tin sinh trắc học của cá nhân người dùng phải được bảo mật tuyệt đối, không chia sẻ cho bên thứ ba.
- Nội dung tư vấn dinh dưỡng và bài tập từ AI phải đi kèm cảnh báo miễn trừ trách nhiệm y tế (Medical Disclaimer) rõ ràng ở màn hình kết quả: *"Các đề xuất từ AI chỉ mang tính tham khảo khoa học, không thay thế hoàn toàn cho chỉ định chuyên khoa từ bác sĩ hoặc chuyên gia thể chất."*

### 3.5 Design and Implementation Constraints
- Frontend di động bắt buộc phát triển bằng Flutter nhằm xuất bản đồng thời trên cả hai chợ ứng dụng lớn Google Play (Android) và App Store (iOS).
- Backend được viết trên nền tảng Java Spring Boot Framework phiên bản 3.x sử dụng Maven quản lý thư viện.
- Cơ sở dữ liệu quan hệ PostgreSQL bắt buộc sử dụng Spring Data JPA để tối ưu hóa việc ánh xạ thực thể (ORM).

### 3.6 AI/ML Integration

#### 3.6.1 Model Specification
- Sử dụng mô hình **Gemini 2.5 Flash** do Google cung cấp thông qua API HTTP POST.
- Đầu vào gửi đi (System & User Prompt) bao gồm: thông tin mục tiêu, tuổi, giới tính, cân nặng, chiều cao, calo mục tiêu hàng ngày, danh sách dị ứng cần loại bỏ, danh sách chấn thương cần tránh, và ngân sách chi tiêu.
- Định dạng dữ liệu yêu cầu mô hình phản hồi phải tuân thủ nghiêm ngặt cấu trúc Markdown hoặc JSON định sẵn để backend hoặc frontend dễ dàng bóc tách thông tin hiển thị lên giao diện người dùng.

---

## 4. Verification

| Requirement ID | Verification Method | Description / Status |
| :--- | :--- | :--- |
| **REQ-F-001** | Test | Thực hiện đăng ký tài khoản qua API và trên thiết bị, kiểm tra bản ghi tương ứng trong bảng `users`. |
| **REQ-F-002** | Test | Đăng nhập tài khoản, kiểm tra tính hợp lệ của JWT token trả về và hạn sử dụng của token. |
| **REQ-F-003** | Test | Thử nghiệm thực hiện khảo sát 12 bước Onboarding, kiểm tra các giá trị BMI, BMR, TDEE tính toán trên Database. |
| **REQ-F-006** | Inspection | Gửi yêu cầu đề xuất thực đơn dinh dưỡng, xác thực xem Gemini có loại trừ các nguyên liệu dị ứng của người dùng đã cấu hình. |
| **REQ-F-009** | Inspection | Gửi yêu cầu đề xuất lịch tập, xác thực xem các bài tập ảnh hưởng chấn thương của người dùng đã bị loại bỏ khỏi danh sách gợi ý. |
| **REQ-F-011** | Test | Ghi nhận một bài tập có thời gian thực hiện, kiểm tra xem lượng calo tiêu hao tính bằng MET có lưu trữ chính xác. |
| **REQ-F-016** | Test | Admin đăng nhập vào Web Dashboard, tạo một nguyên liệu mới và kiểm tra sự xuất hiện của nó trên ứng dụng di động. |

---

## 5. Appendixes

- **Sơ đồ thực thể quan hệ (ERD)**: Xem chi tiết tại tài liệu Thiết kế Hệ thống (System Design Document - SDD).
- **Cảnh báo sức khỏe**: Thông báo miễn trừ trách nhiệm y tế hiển thị lần đầu khi người dùng hoàn thành quy trình khảo sát 12 bước.
