# Nhật Ký Hỏi - Đáp & Bộ Câu Hỏi Phản Biện DATN: Trang Chủ (Home Flow Q&A Log) - BodyPilot

Tài liệu này lưu trữ các câu hỏi thắc mắc kỹ thuật và **Bộ Câu Hỏi Phản Biện Đồ Án Tốt Nghiệp (DATN Defense Q&A)** dành riêng cho luồng điều hướng, kiến trúc, 4 màn hình chi tiết Metric Cards, luồng đếm bước chân và các hàm tính toán cốt lõi trong dự án **BodyPilot**.

---

## 🎓 BỘ CÂU HỎI & ĐÁP PHẢN BIỆN ĐỒ ÁN TỐT NGHIỆP (HOME SCREEN DEFENSE Q&A)

### 🏃 1. Nhóm Tính Năng Đếm Bước Chân (Step Tracker & Pedometer Architecture)

#### ❓ Q1: Cảm biến Pedometer trên điện thoại vốn trả về tổng số bước tích lũy từ khi BẬT MÁY (Boot time), làm thế nào em tính được số bước chính xác của RIÊNG NGÀY HÔM NAY?
* **Cách trả lời chuẩn**:
  - Nhờ thuật toán **Tính Baseline linh hoạt** trong `StepTrackerService._calculateTodaySteps(rawHardwareSteps)` ([step_tracker_service.dart:L60-L105](file:///c:/Personal/DATN/BodyPilot/mobile/lib/data/services/step_tracker_service.dart#L60-L105)):
    - Lưu `step_baseline_steps` và `step_baseline_date` vào `SharedPreferences`.
    - **Khi sang ngày mới (`savedDate != todayStr`)**: Cập nhật `baseline = rawHardwareSteps`.
    - **Khi máy bị khởi động lại (Reboot)**: Nhận biết `rawHardwareSteps < baseline` ➔ Cập nhật lại `baseline = (rawHardwareSteps - savedTodaySteps)`.
    - Số bước hôm nay chính xác: $\text{todaySteps} = \text{rawHardwareSteps} - \text{baseline}$.

#### ❓ Q2: Làm sao để ứng dụng đếm bước chân không làm hao pin hoặc gây nghẽn mạng do gọi API quá nhiều?
* **Cách trả lời chuẩn**:
  - Áp dụng chiến lược **Smart Sync Strategy** trong `StepCubit`:
    1. **Về Cảm biến**: Đăng ký `Pedometer.stepCountStream` dạng Passive Stream lắng nghe sự kiện từ chip cảm biến phần cứng (Hardware Event Listener), không dùng `Timer.periodic` chạy vòng lặp vô hạn gây hao pin.
    2. **Về Network**: Không gửi API theo từng bước chân lẻ. Chỉ kích hoạt `syncTodayStepsToBackend` khi số bước tăng **$\ge 50$ bước** kể từ lần sync trước, hoặc khi app chuyển từ Background lên Foreground (`AppLifecycleState.resumed`).

#### ❓ Q3: Công thức tính Calo đốt cháy và Quãng đường từ bước chân được thiết lập ra sao?
* **Cách trả lời chuẩn**:
  - Quãng đường: $\text{Distance (Km)} = \text{Steps} \times 0.00075$
  - Calo đốt cháy (Cá nhân hóa theo cân nặng người dùng từ `UserCubit`):
    $$\text{Calories Burned} = \text{Steps} \times 0.0005 \times \text{userWeight (kg)}$$

---

### 🔴 2. Nhóm Các Hàm Tính Toán Cốt Lõi (Core Calculation Functions FE & BE)

#### ❓ Q4: Backend tính toán lại tổng Calo nạp vào (`totalCaloriesEaten`) và tổng Calo đốt cháy (`totalCaloriesBurned`) như thế nào khi người dùng sửa nhật ký?
* **Cách trả lời chuẩn**:
  - `NutritionDiaryServiceImpl.recalculateDailyTotals(diary)`: Mỗi khi log món mới/xóa/toggle `isEaten`, duyệt các bữa ăn, lọc món `isEaten = true` ➔ tự động cộng dồn Calo, Protein, Fat, Carbs.
  - `WorkoutDiaryServiceImpl.recalculateWorkoutTotals(diary)`: Mỗi khi hoàn thành bài tập, lọc bài `isCompleted = true` ➔ tự động cộng dồn Calo đốt cháy và Phút vận động.

#### ❓ Q5: Hàm tính BMR, TDEE và Target Calories được đặt ở đâu trên Backend và được kích hoạt ở những luồng nào?
* **Cách trả lời chuẩn**:
  - Đặt tại **`CalorieCalculatorService.calculateMetrics(user, profile, goals)`** dùng công thức Mifflin-St Jeor và hệ số PAL.
  - Được kích hoạt ở 3 luồng: Hoàn thành khảo sát ban đầu (`AssessmentServiceImpl`), Check-in cân nặng tuần (`CheckInServiceImpl`), và Cập nhật Profile (`UserServiceImpl`).

---

### 🟡 3. Nhóm Các Màn Hình Chi Tiết (Metric Detail Screens Implementation)

#### ❓ Q6: Khi bấm vào Thẻ Cân bằng Calo trên Trang chủ, màn hình chi tiết `CalorieBalanceDetailScreen` xử lý dữ liệu dải ngày thế nào?
* **Cách trả lời chuẩn**:
  - Màn hình sử dụng `Future.wait` gọi 2 API dải ngày: `getDailyEatingRange` và `getDailyWorkoutRange`.
  - Quét dải 7 ngày hoặc 30 ngày, gọi `_getDataForDate(date)` lấy `intake` và `burned`.
  - Render `DoubleBarChart` và danh sách chi tiết từng ngày có cột `Net Balance`.
