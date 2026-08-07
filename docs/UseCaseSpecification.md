# UseCaseSpecification.md - Đặc tả Use Case Chi tiết Hệ thống BodyPilot

Tài liệu này chứa đặc tả nghiệp vụ chi tiết cho **5 Use Case cốt lõi** thuộc hệ thống **BodyPilot** (Ứng dụng di động hỗ trợ quản lý dinh dưỡng và luyện tập cá nhân hóa). Tài liệu được biên soạn phục vụ cho nội dung **Chương 2 - Phân tích Yêu cầu Phần mềm** trong Đồ án Tốt nghiệp.

---

# UC01 - Đánh giá Thể trạng

## 1. Thông tin chung

- **Mã Use Case:** UC01
- **Tên Use Case:** Đánh giá thể trạng
- **Mục đích:** Thu thập các chỉ số sinh học, mức độ vận động, tình trạng sức khỏe và mục tiêu cá nhân của người dùng; từ đó tính toán tự động các chỉ số sinh lý (BMI, BMR, TDEE) và phân bổ nhu cầu calo cùng dinh dưỡng vĩ mô mục tiêu.
- **Tác nhân:** Người dùng (Mobile Client)
- **Điều kiện tiên quyết:** Người dùng đã đăng ký/đăng nhập tài khoản thành công vào hệ thống.
- **Điều kiện sau khi hoàn thành:** Hồ sơ chỉ số thể trạng và hạn mức dinh dưỡng mục tiêu được cập nhật vào cơ sở dữ liệu.

## 2. Luồng chính

| Bước | Tác nhân    | Mô tả                                                                                                                                                                                                                                                              |
| :----- | :------------ | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1      | Người dùng | Yêu cầu thực hiện đánh giá thể trạng (truy cập màn hình khảo sát).                                                                                                                                                                                     |
| 2      | Hệ thống    | Hiển thị các bước thu thập thông tin chỉ số sinh học và nhu cầu cá nhân.                                                                                                                                                                               |
| 3      | Người dùng | Lần lượt khai báo thông tin bao gồm: mục tiêu thể trạng, giới tính, tuổi, chiều cao, cân nặng hiện tại, cân nặng mục tiêu, mức độ vận động, chấn thương xương khớp, bệnh lý nền, dị ứng thực phẩm và tùy chọn khẩu vị. |
| 4      | Người dùng | Xác nhận hoàn thành và gửi dữ liệu đánh giá.                                                                                                                                                                                                              |
| 5      | Hệ thống    | Kiểm tra tính hợp lệ của dữ liệu đầu vào.                                                                                                                                                                                                                  |
| 6      | Hệ thống    | Áp dụng thuật toán y khoa tự động tính toán các chỉ số: BMI, BMR, TDEE, Calo nạp vào mục tiêu và Tỷ lệ dinh dưỡng vĩ mô (Protein, Carbs, Fat).                                                                                                |
| 7      | Hệ thống    | Lưu thông tin hồ sơ thể trạng và lịch sử chỉ số của người dùng vào cơ sở dữ liệu.                                                                                                                                                                |
| 8      | Hệ thống    | Hiển thị báo cáo kết quả đánh giá thể trạng chi tiết kèm bảng chỉ số mục tiêu cho người dùng.                                                                                                                                                   |

## 3. Luồng thay thế

### 3.1. A1: Người dùng cập nhật lại chỉ số thể trạng (Đánh giá lại)

| Bước | Tác nhân    | Mô tả                                                                                           |
| :----- | :------------ | :------------------------------------------------------------------------------------------------ |
| 1      | Hệ thống    | Phát hiện người dùng đã hoàn thành đánh giá thể trạng từ trước.                  |
| 2      | Hệ thống    | Tải và hiển thị các thông tin thể trạng cũ đang lưu trong cơ sở dữ liệu.           |
| 3      | Người dùng | Điều chỉnh các chỉ số thay đổi (ví dụ: cập nhật cân nặng mới).                     |
| 4      | Người dùng | Xác nhận cập nhật thông tin.                                                                 |
| 5      | Hệ thống    | Tiếp tục từ**Bước 5** của Luồng chính để tính toán và lưu lại chỉ số mới. |

### 3.2. A2: Người dùng nhập dữ liệu không hợp lệ

| Bước | Tác nhân    | Mô tả                                                                                                                             |
| :----- | :------------ | :---------------------------------------------------------------------------------------------------------------------------------- |
| 1      | Hệ thống    | Phát hiện chỉ số nhập vào vượt giới hạn hợp lý (chiều cao < 50cm hoặc > 250cm, cân nặng$\le$ 0, tuổi $\le$ 0). |
| 2      | Hệ thống    | Hiển thị thông báo lỗi chi tiết tại ô nhập liệu tương ứng.                                                             |
| 3      | Hệ thống    | Tạm dừng chuyển bước cho đến khi dữ liệu được chỉnh sửa đúng quy định.                                            |
| 4      | Người dùng | Nhập lại chỉ số hợp lệ và tiếp tục Luồng chính.                                                                          |

### 3.3. A3: Người dùng bỏ trống các trường thông tin không bắt buộc

| Bước | Tác nhân    | Mô tả                                                                                             |
| :----- | :------------ | :-------------------------------------------------------------------------------------------------- |
| 1      | Người dùng | Bỏ qua các bước khai báo chấn thương, bệnh lý hoặc dị ứng thực phẩm.                 |
| 2      | Hệ thống    | Mặc định giá trị "Không có chấn thương/bệnh lý/dị ứng".                               |
| 3      | Hệ thống    | Tiếp tục thực hiện tính toán chỉ số ở**Bước 6** của Luồng chính bình thường. |

## 4. Quy tắc nghiệp vụ

- **Chỉ số khối cơ thể (BMI):**
  $$
  \text{BMI} = \frac{\text{Cân nặng (kg)}}{\left[\text{Chiều cao (m)}\right]^2}
  $$

  - Phân loại: $\text{BMI} < 18.5$ (Gầy); $18.5 \le \text{BMI} \le 22.9$ (Bình thường); $23.0 \le \text{BMI} \le 24.9$ (Tiền béo phì); $\text{BMI} \ge 25.0$ (Béo phì).
- **Tỷ lệ chuyển hóa cơ bản (BMR) theo công thức Mifflin-St Jeor:**
  - Nam: $\text{BMR} = 10 \times \text{Cân nặng (kg)} + 6.25 \times \text{Chiều cao (cm)} - 5 \times \text{Tuổi} + 5$
  - Nữ: $\text{BMR} = 10 \times \text{Cân nặng (kg)} + 6.25 \times \text{Chiều cao (cm)} - 5 \times \text{Tuổi} - 161$
- **Tổng năng lượng tiêu thụ hàng ngày (TDEE):**
  $$
  \text{TDEE} = \text{BMR} \times \text{Hệ số vận động (PAL)}
  $$

  - Hệ số vận động (PAL): Thụ động ($1.2$), Vận động nhẹ ($1.375$), Vận động vừa ($1.55$), Năng động ($1.725$), Rất năng động ($1.9$).
- **Calo nạp vào mục tiêu (Target Calories):**
  - Giảm cân nhanh: $\text{TDEE} - 1000\text{ kcal/ngày}$.
  - Giảm cân vừa: $\text{TDEE} - 500\text{ kcal/ngày}$.
  - Duy trì cân nặng / Sống khỏe: $\text{TDEE}$.
  - Tăng cân / Tăng cơ: $\text{TDEE} + 300\text{ đến } 500\text{ kcal/ngày}$.
- **Tỷ lệ phân bổ dinh dưỡng vĩ mô (Macros Ratio):**
  - Mục tiêu Giảm cân: 40% Protein, 40% Carbs, 20% Fat.
  - Mục tiêu Tăng cơ / Thể hình: 35% Protein, 45% Carbs, 20% Fat.
  - Mục tiêu Duy trì / Lối sống lành mạnh: 25% Protein, 50% Carbs, 25% Fat.

## 5. Dữ liệu vào

- **Thông tin nhân khẩu học:** Giới tính, Tuổi.
- **Chỉ số sinh học:** Chiều cao (cm), Cân nặng hiện tại (kg), Cân nặng mục tiêu (kg).
- **Định hướng thể trạng:** Mục tiêu cá nhân (Tăng/Giảm cân, Tăng cơ, Duy trì), Mức độ vận động hàng ngày.
- **Ràng buộc sức khỏe:** Danh sách bệnh lý nền, Danh sách chấn thương xương khớp, Danh sách dị ứng thực phẩm, Danh sách nhóm thực phẩm không thích, Ngân sách ăn uống.

## 6. Dữ liệu ra

- **Các chỉ số sinh lý:** Chỉ số BMI, Phân loại thể trạng, Chỉ số BMR (kcal), Chỉ số TDEE (kcal).
- **Hạn mức dinh dưỡng mục tiêu:** Calo nạp vào hàng ngày (kcal), Lượng Protein (g), Lượng Carbs (g), Lượng Fat (g).
- **Trạng thái hồ sơ:** Trạng thái hoàn thành đánh giá thể trạng (`Completed = True`).

---

# UC02 - Gợi ý Thực đơn AI

## 1. Thông tin chung

- **Mã Use Case:** UC02
- **Tên Use Case:** Gợi ý thực đơn AI
- **Mục đích:** Khởi tạo thực đơn ăn uống 7 ngày cá nhân hóa được tính toán tự động bằng Trí tuệ Nhân tạo, đáp ứng chính xác hạn mức calo/macro và loại trừ các thực phẩm gây dị ứng hoặc không phù hợp với bệnh lý nền.
- **Tác nhân:** Người dùng (Mobile Client), Hệ thống Trí tuệ Nhân tạo (AI Engine)
- **Điều kiện tiên quyết:** Người dùng đã hoàn thành Use Case **UC01 - Đánh giá thể trạng**.
- **Điều kiện sau khi hoàn thành:** Thực đơn 7 ngày thuần Việt được lưu vào lịch ăn uống và sẵn sàng phục vụ theo dõi nhật ký dinh dưỡng.

## 2. Luồng chính

| Bước | Tác nhân    | Mô tả                                                                                                                                                     |
| :----- | :------------ | :---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1      | Người dùng | Yêu cầu hệ thống khởi tạo thực đơn gợi ý (chọn số ngày gợi ý).                                                                              |
| 2      | Hệ thống    | Truy vấn hồ sơ thể trạng người dùng bao gồm: TDEE, Calo mục tiêu, tỷ lệ Macros, dị ứng thực phẩm, bệnh lý nền và tùy chọn khẩu vị. |
| 3      | Hệ thống    | Tổng hợp bối cảnh thông tin và gửi yêu cầu sinh thực đơn sang Hệ thống Trí tuệ Nhân tạo.                                                  |
| 4      | AI Engine     | Phân tích các ràng buộc dinh dưỡng và suy luận cấu trúc thực đơn 7 ngày thuần Việt chia theo 4 bữa (Sáng, Trưa, Tối, Phụ).            |
| 5      | AI Engine     | Trả về dữ liệu danh sách món ăn chi tiết kèm định lượng calo và macros của từng bữa.                                                       |
| 6      | Hệ thống    | Kiểm tra đối soát cấu trúc thực đơn trả về từ AI Engine.                                                                                        |
| 7      | Hệ thống    | Hiển thị thực đơn gợi ý chi tiết theo từng ngày cho người dùng xem trước.                                                                    |
| 8      | Người dùng | Xác nhận áp dụng thực đơn gợi ý.                                                                                                                   |
| 9      | Hệ thống    | Lưu thực đơn vào kế hoạch dinh dưỡng hàng ngày trong cơ sở dữ liệu.                                                                          |

## 3. Luồng thay thế

### 3.1. A1: Người dùng gửi phản hồi điều chỉnh thực đơn

| Bước | Tác nhân    | Mô tả                                                                                                                                             |
| :----- | :------------ | :-------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1      | Người dùng | Nhập văn bản phản hồi tại màn hình hiển thị thực đơn (ví dụ:*"Tôi không thích ăn cá ngừ, hãy đổi sang món thịt lợn"*). |
| 2      | Hệ thống    | Đóng gói phản hồi của người dùng kèm bối cảnh thực đơn hiện tại gửi tới AI Engine.                                               |
| 3      | AI Engine     | Phân tích yêu cầu thay thế và tái tạo danh sách món ăn mới tương thích.                                                              |
| 4      | Hệ thống    | Cập nhật và hiển thị lại thực đơn đã điều chỉnh cho người dùng xem trước.                                                        |
| 5      | Hệ thống    | Tiếp tục từ**Bước 8** của Luồng chính.                                                                                                |

### 3.2. A2: Người dùng chưa hoàn thành đánh giá thể trạng

| Bước | Tác nhân | Mô tả                                                                                               |
| :----- | :--------- | :---------------------------------------------------------------------------------------------------- |
| 1      | Hệ thống | Kiểm tra thấy người dùng chưa hoàn thành khảo sát UC01.                                     |
| 2      | Hệ thống | Hiển thị thông báo yêu cầu thực hiện đánh giá thể trạng trước khi gợi ý thực đơn. |
| 3      | Hệ thống | Chuyển hướng người dùng sang giao diện**UC01 - Đánh giá thể trạng**.                |

### 3.3. A3: Hệ thống Trí tuệ Nhân tạo phản hồi chậm hoặc gián đoạn

| Bước | Tác nhân | Mô tả                                                                        |
| :----- | :--------- | :----------------------------------------------------------------------------- |
| 1      | AI Engine  | Không phản hồi hoặc quá thời gian chờ quy định (Timeout > 15 giây).  |
| 2      | Hệ thống | Hiển thị thông báo lỗi kết nối và gợi ý người dùng thử lại sau. |
| 3      | Hệ thống | Khôi phục giao diện về trạng thái trước khi yêu cầu.                 |

## 4. Quy tắc nghiệp vụ

- **Định mức Năng lượng Thực đơn:** Tổng lượng calo của tất cả các bữa trong 1 ngày phải xấp xỉ Calo mục tiêu của người dùng (dung sai cho phép trong khoảng $\pm 5\%$).
- **Phân bổ Calo theo Bữa ăn:**
  - Bữa sáng: $25\% - 30\%$ tổng Calo ngày.
  - Bữa trưa: $35\% - 40\%$ tổng Calo ngày.
  - Bữa tối: $25\% - 30\%$ tổng Calo ngày.
  - Bữa phụ / Bữa xế: $10\% - 15\%$ tổng Calo ngày.
- **Loại trừ An toàn Thực phẩm (Allergy & Health Exclusion):**
  - Tuyệt đối không chứa nguyên liệu thuộc danh sách dị ứng đã khai báo.
  - Nếu người dùng có bệnh lý Tiền béo phì / Tiểu đường: Hạn chế món ăn có chỉ số đường huyết (GI) cao và lượng đường chế biến $> 15\text{g/ngày}$.
- **Văn hóa Ẩm thực:** Các món ăn gợi ý ưu tiên sử dụng danh mục thực phẩm Việt Nam quen thuộc và dễ chế biến.

## 5. Dữ liệu vào

- **Hồ sơ Dinh dưỡng Người dùng:** Calo mục tiêu (kcal), Tỷ lệ Protein/Carbs/Fat (g), Ngân sách ăn uống.
- **Danh sách Ràng buộc:** Nhóm chất dị ứng, Nhóm thực phẩm hạn chế, Bệnh lý nền.
- **Tham số Điều khiển:** Số ngày cần gợi ý (ví dụ: 7 ngày), Ngày bắt đầu áp dụng, Phản hồi điều chỉnh của người dùng (nếu có).

## 6. Dữ liệu ra

- **Cấu trúc Thực đơn Gợi ý:** Danh sách món ăn theo từng ngày, Phân bố món ăn theo 4 bữa (Sáng, Trưa, Tối, Phụ).
- **Thông số Dinh dưỡng Món ăn:** Định lượng phần ăn (g), Hàm lượng Calo (kcal), Lượng Protein (g), Lượng Carbs (g), Lượng Fat (g) của từng món.

---

# UC03 - Gợi ý Lịch tập AI

## 1. Thông tin chung

- **Mã Use Case:** UC03
- **Tên Use Case:** Gợi ý lịch tập AI
- **Mục đích:** Xây dựng giáo án và lịch luyện tập cá nhân hóa tự động dựa trên mục tiêu thể hình, kinh nghiệm tập luyện, thiết bị sẵn có và loại trừ các bài tập gây áp lực lên vùng chấn thương xương khớp của người dùng.
- **Tác nhân:** Người dùng (Mobile Client), Hệ thống Trí tuệ Nhân tạo (AI Engine)
- **Điều kiện tiên quyết:** Người dùng đã hoàn thành Use Case **UC01 - Đánh giá thể trạng**.
- **Điều kiện sau khi hoàn thành:** Giáo án luyện tập tuần được lưu vào kế hoạch tập luyện cá nhân.

## 2. Luồng chính

| Bước | Tác nhân    | Mô tả                                                                                                                                                         |
| :----- | :------------ | :-------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1      | Người dùng | Yêu cầu khởi tạo lịch tập gợi ý.                                                                                                                        |
| 2      | Hệ thống    | Truy vấn thông tin hồ sơ thể trạng: Mục tiêu tập luyện, Kinh nghiệm tập, Thiết bị/Dụng cụ sẵn có và Danh sách chấn thương xương khớp. |
| 3      | Hệ thống    | Đóng gói yêu cầu và gửi dữ liệu sang Hệ thống Trí tuệ Nhân tạo.                                                                                  |
| 4      | AI Engine     | Phân tích mức độ vận động, nguyên lý phân bổ nhóm cơ và lọc các bài tập gây nguy cơ tới vùng chấn thương.                             |
| 5      | AI Engine     | Khởi tạo lịch tập luyện tuần bao gồm danh sách buổi tập, danh mục bài tập, số hiệp (Sets), số lần lặp (Reps) và thời gian nghỉ.            |
| 6      | Hệ thống    | Hiển thị giáo án tập luyện chi tiết cho người dùng kiểm tra.                                                                                         |
| 7      | Người dùng | Xác nhận đồng ý áp dụng lịch tập.                                                                                                                      |
| 8      | Hệ thống    | Lưu giáo án vào lịch trình luyện tập cá nhân trong cơ sở dữ liệu.                                                                                 |

## 3. Luồng thay thế

### 3.1. A1: Người dùng thay đổi địa điểm hoặc dụng cụ tập luyện

| Bước | Tác nhân    | Mô tả                                                                                                                         |
| :----- | :------------ | :------------------------------------------------------------------------------------------------------------------------------ |
| 1      | Người dùng | Chọn tùy chọn thay đổi điều kiện tập (ví dụ: Tập tại nhà không dụng cụ / Tập tại phòng Gym đầy đủ tạ). |
| 2      | Hệ thống    | Cập nhật lại điều kiện thiết bị mới.                                                                                   |
| 3      | Hệ thống    | Thực hiện lại từ**Bước 3** của Luồng chính để AI khởi tạo danh mục bài tập tương ứng.                  |

### 3.2. A2: Người dùng có chấn thương nghiêm trọng cần bỏ qua nhóm cơ

| Bước | Tác nhân | Mô tả                                                                                                                                        |
| :----- | :--------- | :--------------------------------------------------------------------------------------------------------------------------------------------- |
| 1      | Hệ thống | Phát hiện người dùng khai báo chấn thương khớp vai hoặc đau lưng dưới cấp tính.                                               |
| 2      | AI Engine  | Tự động loại bỏ hoàn toàn các bài tập gánh tạ nén cột sống (*Squat/Deadlift*) hoặc đẩy tạ qua đầu (*Overhead Press*). |
| 3      | AI Engine  | Thay thế bằng các bài tập hỗ trợ nhẹ nhàng trên máy tập cô lập hoặc bài tập phục hồi chức năng.                           |
| 4      | Hệ thống | Tiếp tục từ**Bước 6** của Luồng chính.                                                                                           |

### 3.3. A3: Hệ thống Trí tuệ Nhân tạo không phản hồi

| Bước | Tác nhân | Mô tả                                                                                     |
| :----- | :--------- | :------------------------------------------------------------------------------------------ |
| 1      | AI Engine  | Không phản hồi hoặc phát sinh lỗi xử lý.                                            |
| 2      | Hệ thống | Hiển thị thông báo không thể khởi tạo lịch tập lúc này.                         |
| 3      | Hệ thống | Khuyên người dùng chọn các giáo án bài tập mẫu chuẩn bị sẵn trong thư viện. |

## 4. Quy tắc nghiệp vụ

- **Loại trừ Chấn thương (Injury Safety Rules):**
  - Chấn thương Khớp gối / Dây chằng (ACL): Loại bỏ bài tập bật nhảy cường độ cao (*Jumping Jacks, Plyometrics*), Squat sâu quá 90 độ.
  - Chấn thương Lưng dưới / Thoát vị đĩa đệm: Loại bỏ bài tập gánh tạ đòn (*Barbell Squat*), gập lưng nâng tạ (*Deadlift*), gập bụng nén lưng.
  - Chấn thương Khớp vai / Chóp xoay: Loại bỏ bài tập đẩy tạ vai nặng quá đầu (*Overhead Shoulder Press*), xà kép sâu (*Dips*).
- **Phân bổ Khối lượng Tập (Volume & Intensity):**
  - Người mới bắt đầu (*Beginner*): 3 - 4 buổi/tuần, 3 - 4 bài/buổi, $2 - 3\text{ Sets/bài}$, $10 - 12\text{ Reps/Set}$.
  - Người đã có kinh nghiệm (*Intermediate/Advanced*): 4 - 6 buổi/tuần, 5 - 6 bài/buổi, $3 - 4\text{ Sets/bài}$, $8 - 12\text{ Reps/Set}$.
- **Ước tính Calo Tiêu thụ Bài tập:**
  $$
  \text{Calo đốt cháy (kcal)} = \text{Chỉ số MET} \times \text{Cân nặng (kg)} \times \left(\frac{\text{Thời gian tập (phút)}}{60}\right)
  $$

## 5. Dữ liệu vào

- **Hồ sơ Thể hình Người dùng:** Mục tiêu tập luyện (Tăng cơ, Giảm mỡ, Sức bền), Trình độ kinh nghiệm.
- **Ràng buộc Y tế & Thiết bị:** Danh sách chấn thương xương khớp, Địa điểm tập luyện (Tại nhà / Phòng Gym), Dụng cụ tập hiện có.

## 6. Dữ liệu ra

- **Giáo án Tập luyện Chi tiết:** Danh sách buổi tập trong tuần, Tên bài tập theo nhóm cơ, Hình ảnh / Video hướng dẫn kỹ thuật.
- **Thông số Hiệp tập:** Số Sets, Số Reps mục tiêu, Mức tạ đề xuất (% 1RM hoặc kg), Thời gian nghỉ giữa các hiệp (giây), Ước tính calo tiêu hao (kcal).

---

# UC04 - Ghi Nhật ký Ăn uống và Theo dõi Dinh dưỡng

## 1. Thông tin chung

- **Mã Use Case:** UC04
- **Tên Use Case:** Ghi nhật ký ăn uống và theo dõi dinh dưỡng
- **Mục đích:** Cho phép người dùng tìm kiếm thực phẩm, lưu ghi nhận lượng thức ăn đã tiêu thụ theo các bữa trong ngày, đồng thời tự động tổng hợp tiến độ Calo và dinh dưỡng vĩ mô thực tế so với hạn mức mục tiêu.
- **Tác nhân:** Người dùng (Mobile Client)
- **Điều kiện tiên quyết:** Người dùng đã có tài khoản và đã hoàn thành tính toán hạn mức calo mục tiêu (UC01).
- **Điều kiện sau khi hoàn thành:** Nhật ký khẩu phần ăn ngày được lưu trữ và thanh tiến độ năng lượng được cập nhật thời gian thực.

## 2. Luồng chính

| Bước | Tác nhân    | Mô tả                                                                                                                       |
| :----- | :------------ | :---------------------------------------------------------------------------------------------------------------------------- |
| 1      | Người dùng | Mở nhật ký dinh dưỡng ngày và chọn bữa ăn cần ghi nhận (Sáng, Trưa, Tối, Phụ).                                |
| 2      | Người dùng | Nhập từ khóa tìm kiếm món ăn hoặc nguyên liệu thực phẩm.                                                          |
| 3      | Hệ thống    | Đẩy danh sách các thực phẩm phù hợp từ cơ sở dữ liệu món ăn Việt Nam kèm thông số dinh dưỡng trên 100g. |
| 4      | Người dùng | Chọn món ăn mong muốn và nhập khẩu phần tiêu thụ (khối lượng gram hoặc đơn vị phần ăn).                    |
| 5      | Hệ thống    | Tính toán tỷ lệ năng lượng và dinh dưỡng tương ứng với khối lượng đã nhập.                                |
| 6      | Người dùng | Nhấn xác nhận lưu món ăn vào bữa.                                                                                     |
| 7      | Hệ thống    | Lưu dữ liệu món ăn vào nhật ký dinh dưỡng ngày của người dùng.                                                 |
| 8      | Hệ thống    | Tính toán lại tổng Calo, Protein, Carbs, Fat nạp vào trong ngày.                                                       |
| 9      | Hệ thống    | Cập nhật và hiển thị biểu đồ thanh tiến độ Calo nạp vào so với hạn mức TDEE mục tiêu.                       |

## 3. Luồng thay thế

### 3.1. A1: Người dùng thay đổi khẩu phần hoặc xóa món ăn đã ghi

| Bước | Tác nhân    | Mô tả                                                                                          |
| :----- | :------------ | :----------------------------------------------------------------------------------------------- |
| 1      | Người dùng | Chọn một món ăn đã ghi nhận trong nhật ký bữa ăn.                                     |
| 2      | Người dùng | Chỉnh sửa lại khối lượng ăn hoặc nhấn chọn xóa món ăn khỏi bữa.                   |
| 3      | Hệ thống    | Trừ bớt hoặc tính toán lại dinh dưỡng tương ứng.                                      |
| 4      | Hệ thống    | Tiếp tục từ**Bước 8** của Luồng chính để cập nhật lại thanh tiến độ tổng. |

### 3.2. A2: Không tìm thấy món ăn trong cơ sở dữ liệu

| Bước | Tác nhân    | Mô tả                                                                                              |
| :----- | :------------ | :--------------------------------------------------------------------------------------------------- |
| 1      | Hệ thống    | Không tìm thấy kết quả phù hợp với từ khóa tìm kiếm.                                     |
| 2      | Hệ thống    | Gợi ý người dùng chọn danh mục thực phẩm tương đương hoặc nhập món ăn tùy chỉnh. |
| 3      | Người dùng | Nhập thông tin món ăn tùy chỉnh (Tên món, Calo ước tính).                                 |
| 4      | Hệ thống    | Lưu món ăn tùy chỉnh vào nhật ký và tiếp tục**Bước 8** Luồng chính.             |

### 3.3. A3: Năng lượng nạp vào vượt quá hạn mức calo mục tiêu ngày

| Bước | Tác nhân | Mô tả                                                                                                |
| :----- | :--------- | :----------------------------------------------------------------------------------------------------- |
| 1      | Hệ thống | Tính toán thấy Tổng Calo nạp vào vượt quá 100% Calo mục tiêu ngày.                         |
| 2      | Hệ thống | Đổi màu thanh tiến độ sang cảnh báo (màu đỏ) và hiển thị thông tin dư thừa calo.      |
| 3      | Hệ thống | Gợi ý người dùng thực hiện thêm bài tập vận động để đốt cháy lượng calo dư thừa. |

## 4. Quy tắc nghiệp vụ

- **Tính toán Dinh dưỡng Khẩu phần:**

  $$
  \text{Calo khẩu phần} = \text{Calo chuẩn trên 100g} \times \left(\frac{\text{Khối lượng ăn (g)}}{100}\right)
  $$

  $$
  \text{Protein khẩu phần (g)} = \text{Protein chuẩn trên 100g} \times \left(\frac{\text{Khối lượng ăn (g)}}{100}\right)
  $$
- **Tổng Năng lượng Thực nạp (Net Calories Intake):**

  $$
  \text{Tổng Calo nạp} = \sum \text{Calo các món ăn trong 4 bữa (Sáng + Trưa + Tối + Phụ)}
  $$
- **Tỷ lệ Hoàn thành Tiến độ Dinh dưỡng:**

  $$
  \text{Tỷ lệ Calo (\%)} = \left(\frac{\text{Tổng Calo nạp}}{\text{Calo mục tiêu}}\right) \times 100\%
  $$

## 5. Dữ liệu vào

- **Thông tin Bữa ăn:** Danh mục bữa (Sáng / Trưa / Tối / Bữa phụ), Ngày ghi nhận.
- **Thông tin Món ăn:** Từ khóa tìm kiếm món ăn, Khối lượng phần ăn (g hoặc số lượng phần).

## 6. Dữ liệu ra

- **Nhật ký Ăn uống:** Chi tiết các món ăn đã lưu trong từng bữa.
- **Tổng hợp Dinh dưỡng Ngày:** Tổng Calo nạp vào (kcal), Tổng lượng Protein (g), Tổng lượng Carbs (g), Tổng lượng Fat (g).
- **Biểu thị Tiến độ:** Tỷ lệ phần trăm hoàn thành chỉ số dinh dưỡng so với mục tiêu ngày.

---

UC05 - Theo dõi Vận động và Đếm bước chân Tự động

## 1. Thông tin chung

- **Mã Use Case:** UC05
- **Tên Use Case:** Theo dõi vận động và đếm bước chân tự động
- **Mục đích:** Tự động ghi nhận số bước chân vận động hàng ngày của người dùng thông qua cảm biến phần cứng của thiết bị di động, tự động tính toán quãng đường và calo tiêu hao thời gian thực để hỗ trợ duy trì mục tiêu sống khỏe.
- **Tác nhân:** Người dùng (Mobile Client), Cảm biến Phần cứng Thiết bị (Hardware Step Sensor)
- **Điều kiện tiên quyết:** Thiết bị di động có hỗ trợ cảm biến đếm bước chân và ứng dụng được cấp quyền truy cập cảm biến vận động.
- **Điều kiện sau khi hoàn thành:** Dữ liệu bước chân thời gian thực được đồng bộ và năng lượng đốt cháy được cộng vào tổng tiêu hao trong ngày.

## 2. Luồng chính

| Bước | Tác nhân             | Mô tả                                                                                                                                                      |
| :----- | :--------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1      | Cảm biến phần cứng | Nhận biết chuyển động bước chân của người dùng trong sinh hoạt hàng ngày.                                                                     |
| 2      | Cảm biến phần cứng | Phát tín hiệu đếm số bước chân thời gian thực tới ứng dụng.                                                                                    |
| 3      | Hệ thống             | Đọc và xử lý luồng dữ liệu bước chân liên tục chạy ẩn trong nền.                                                                             |
| 4      | Hệ thống             | Áp dụng thuật toán quy đổi số bước chân ra Quãng đường di chuyển (km) và Năng lượng tiêu hao (kcal) dựa trên cân nặng người dùng. |
| 5      | Hệ thống             | Cập nhật chỉ số bước chân thời gian thực lên giao diện theo dõi sức khỏe.                                                                      |
| 6      | Người dùng          | Mở ứng dụng xem tiến độ đếm bước chân và calo tiêu hao trong ngày.                                                                             |
| 7      | Hệ thống             | So sánh số bước đạt được với Mục tiêu bước chân ngày (được thiết lập dựa trên mục tiêu thể trạng ở UC01).                        |
| 8      | Hệ thống             | Hiển thị thanh tiến độ phần trăm bước chân hoàn thành.                                                                                           |

## 3. Luồng thay thế

### 3.1. A1: Quyền truy cập cảm biến vận động bị từ chối

| Bước | Tác nhân    | Mô tả                                                                                                                     |
| :----- | :------------ | :-------------------------------------------------------------------------------------------------------------------------- |
| 1      | Hệ thống    | Phát hiện ứng dụng chưa được cấp quyền truy cập cảm biến đếm bước chân trên thiết bị.                  |
| 2      | Hệ thống    | Hiển thị hộp thoại hướng dẫn người dùng bật quyền truy cập cảm biến vận động trong Cài đặt thiết bị. |
| 3      | Người dùng | Đồng ý cấp quyền truy cập cảm biến.                                                                                 |
| 4      | Hệ thống    | Khởi tạo lại luồng nhận dữ liệu đếm bước từ**Bước 2** Luồng chính.                                    |

### 3.2. A2: Người dùng tự thay đổi Mục tiêu Bước chân ngày

| Bước | Tác nhân    | Mô tả                                                                                                        |
| :----- | :------------ | :------------------------------------------------------------------------------------------------------------- |
| 1      | Người dùng | Truy cập cài đặt và nhập số bước chân mục tiêu mới (ví dụ: tăng từ 8,000 lên 10,000 bước). |
| 2      | Hệ thống    | Kiểm tra giá trị mục tiêu hợp lệ ($> 1,000$ bước).                                                  |
| 3      | Hệ thống    | Lưu mục tiêu bước chân mới vào cơ sở dữ liệu.                                                      |
| 4      | Hệ thống    | Cập nhật lại định mức phần trăm trên thanh tiến độ hiển thị ở**Bước 8** Luồng chính.  |

### 3.3. A3: Thiết bị khởi động lại hoặc bước sang ngày mới (Reset chỉ số)

| Bước | Tác nhân | Mô tả                                                                                        |
| :----- | :--------- | :--------------------------------------------------------------------------------------------- |
| 1      | Hệ thống | Phát hiện thời gian hệ thống bước qua mốc 00:00 (nửa đêm).                          |
| 2      | Hệ thống | Lưu tổng kết số bước chân ngày cũ vào lịch sử vận động trong cơ sở dữ liệu. |
| 3      | Hệ thống | Đặt lại bộ đếm bước chân ngày mới về giá trị 0 bước.                           |
| 4      | Hệ thống | Bắt đầu luồng đếm mới từ**Bước 1** Luồng chính.                              |

## 4. Quy tắc nghiệp vụ

- **Tính toán Quãng đường Di chuyển:**
  $$
  \text{Quãng đường (km)} = \text{Số bước chân} \times \text{Độ dài bước chân trung bình (m)} / 1000
  $$

  - Độ dài bước chân trung bình: $\text{Chiều cao (cm)} \times 0.415$ (đối với Nam) hoặc $\text{Chiều cao (cm)} \times 0.413$ (đối với Nữ).
- **Tính toán Calo Tiêu thụ từ Bước chân:**
  $$
  \text{Calo đốt cháy (kcal)} = \text{Số bước chân} \times \text{Cân nặng (kg)} \times 0.0005
  $$
- **Thiết lập Mục tiêu Bước chân Mặc định theo Mục tiêu Thể trạng:**
  - Mục tiêu Giảm cân nhanh: 12,000 - 15,000 bước/ngày.
  - Mục tiêu Giảm cân vừa: 10,000 - 12,500 bước/ngày.
  - Mục tiêu Duy trì / Lối sống lành mạnh: 8,000 - 10,000 bước/ngày.
  - Mục tiêu Tăng cơ / Tăng cân: 5,000 - 7,000 bước/ngày.

## 5. Dữ liệu vào

- **Tín hiệu Cảm biến:** Luồng xung đếm bước chân thời gian thực từ cảm biến phần cứng thiết bị.
- **Hồ sơ Cá nhân:** Cân nặng (kg), Chiều cao (cm), Giới tính, Mục tiêu bước chân ngày đã cài đặt.

## 6. Dữ liệu ra

- **Chỉ số Vận động Đếm được:** Tổng số bước chân tích lũy trong ngày, Quãng đường ước tính (km), Calo tiêu hao từ vận động (kcal).
- **Trạng thái Tiến độ:** Tỷ lệ phần trăm hoàn thành mục tiêu bước chân ngày, Thông báo chúc mừng khi đạt mốc mục tiêu.
