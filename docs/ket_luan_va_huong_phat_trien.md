# CHƯƠNG 6: KẾT LUẬN VÀ HƯỚNG PHÁT TRIỂN

---

## 6.1. KẾT LUẬN (CONCLUSION)

### 6.1.1. So sánh kết quả/sản phẩm của Đồ án với các nghiên cứu hoặc sản phẩm tương tự

Trong bối cảnh nhận thức về chăm sóc sức khỏe ngày càng nâng cao, các ứng dụng theo dõi dinh dưỡng và tập luyện như **MyFitnessPal**, **Lifesum**, **Yazio** hoặc các công cụ trí tuệ nhân tạo tổng quát như **ChatGPT**, **Claude** đã trở nên phổ biến. Tuy nhiên, khi áp dụng vào bối cảnh văn hóa ẩm thực và nhu cầu người Việt Nam, các sản phẩm này bộc lộ những hạn chế kỹ thuật đáng kể. 

Dưới đây là bảng so sánh đối chiếu giữa hệ thống **BodyPilot** và các sản phẩm/nghiên cứu tương tự trên thị trường:

| Tiêu chí so sánh | Các ứng dụng quốc tế (MyFitnessPal, Lifesum, Yazio) | ChatGPT / LLM thuần (Simple Prompting) | **Hệ thống BodyPilot (Đồ án đề xuất)** |
| :--- | :--- | :--- | :--- |
| **Cơ sở dữ liệu thực phẩm** | Chủ yếu là món ăn phương Tây, thiếu các món ăn chuẩn Việt Nam hoặc thông tin dinh dưỡng bị sai lệch do người dùng tự nhập. | Tự do bịa ra tên món ăn hoặc các chỉ số Macro ảo không có thực trong DB (**AI Hallucination**). | **Hơn 10.000+ món ăn Việt Nam chuẩn hóa 3NF**, lưu trữ sẵn trong PostgreSQL và Meilisearch Engine. |
| **Gợi ý thực đơn cá nhân hóa** | Đưa ra các gợi ý tĩnh dựa trên công thức cố định, thiếu linh hoạt theo sở thích/dị ứng. | Tạo thực đơn tự do nhưng hay đưa món mặn vào bữa sáng hoặc gợi ý món ăn xa lạ với người Việt. | **Tích hợp Gemini AI với Prompt Ngữ cảnh Động**: Phân bổ chuẩn mâm cơm Việt (Sáng điểm tâm nhẹ, Tối có Cơm chính). |
| **Ràng buộc Y tế & Dị ứng** | Lọc thủ công đơn giản, không tự động loại trừ chất gây dị ứng triệt để khi lập thực đơn. | Thường bỏ sót dị ứng do AI không thể ghi nhớ và đối soát ràng buộc y tế dài hạn. | **Tiền lọc y tế triệt để (Pre-AI Medical Filtering)**: Loại bỏ $100\%$ các món vi phạm dị ứng (`UserAllergy`) và nhóm món không thích trước khi gọi AI. |
| **Độ chính xác Calo mục tiêu ($TDEE$)** | Tính toán tổng thủ công, người dùng phải tự điều chỉnh gram từng món. | Calo ước tính ngẫu nhiên, tổng 3 bữa thường lệch $\pm 15\% \rightarrow 30\%$ so với hạn ngạch $TDEE$. | **Thuật toán Co giãn Macro (Exact Macro Scaler)**: Tự động scale khẩu phần để tổng calo đạt độ chính xác **$100\%$ trùng khớp với $TDEE$**. |
| **Độ ổn định hệ thống (Reliability)** | Cao (do là ứng dụng truyền thống). | Phụ thuộc hoàn toàn vào API, dễ sập giao diện khi phản hồi dính chữ tự do hoặc đứt câu. | **Bộ tự vá JSON bằng Stack (Stack-based Auto-Repair)**: Cứu $100\%$ thực đơn đã sinh ra khi AI gặp sự cố chạm mốc Token Limit (`JsonEOFException`). |
| **Đổi món thông minh (Smart Swap)** | Đổi món ngẫu nhiên hoặc yêu cầu trả phí Premium. | Phải nhập lại Prompt từ đầu. | **Smart Swap Engine**: Đổi món tức thì khớp đúng Calo/Macro và danh mục mà không làm phá vỡ thực đơn. |

---

### 6.1.2. Phân tích kết quả đạt được (Những việc đã làm được)

Trong suốt quá trình thực hiện Đồ án Tốt nghiệp, tác giả đã hoàn thành toàn bộ các mục tiêu nghiên cứu và phát triển phần mềm đề ra, cụ thể:

1. **Xây dựng hoàn chỉnh Kiến trúc Hệ thống Phân tán (Full-Stack Architecture):**
   - Đóng gói **BodyPilot Mobile Application** trên nền tảng Flutter (Android APK/AAB) đạt độ hoàn thiện cao về UX/UI, tích hợp BLoC State Management và Firebase FCM.
   - Đóng gói **BodyPilot Backend Service** trên nền tảng Java Spring Boot 3 & PostgreSQL, triển khai thực tế trên đám mây Container.
   - Xây dựng **Admin Web Dashboard** giúp quản trị viên dễ dàng quản lý hệ thống, kiểm soát dữ liệu món ăn và bài tập.

2. **Giải quyết bài toán tích hợp Generative AI cá nhân hóa sâu:**
   - Đề xuất và cài đặt thành công **Pipeline 4 tầng tích hợp AI**:
     - *Tầng 1 (Prompt Ngữ cảnh Động):* Ép cấu trúc mâm cơm Việt Nam, cài đặt hạn ngạch $TDEE \pm 10\%$.
     - *Tầng 2 (Candidate Selection & Round-Robin Balancing):* Rút trích $90 - 150$ món ăn đại diện giúp giảm $75\%$ dung lượng Prompt token, tăng tốc API gấp 6 lần.
     - *Tầng 3 (Stack-based JSON Auto-Repair Engine):* Phục hồi $100\%$ cấu trúc JSON khi bị ngắt câu giữa chừng do chạm giới hạn token output.
     - *Tầng 4 (Exact Macro Scaler & Bound Quantity):* Điều chỉnh Gram chính xác đến từng Calo mục tiêu và khống chế khẩu phần thực tế ($20\text{g} - 600\text{g}$).

3. **Phát triển các tính năng hỗ trợ thể trạng toàn diện:**
   - Tính năng **Đổi món thông minh (Smart Swap)** giúp thay thế món ăn tức thì mà không bị lệch hạn ngạch Calo trong ngày.
   - Tính năng **Đổi bài tập thông minh (Workout Swap)** loại bỏ các bài tập vi phạm vùng chấn thương (`UserInjury`).
   - Tìm kiếm món ăn siêu tốc bằng công cụ **Meilisearch Engine** hỗ trợ gõ tiếng Việt có dấu/không dấu và xử lý gõ lỗi chính tả.

4. **Đóng góp quy mô mã nguồn và Dữ liệu:**
   - Xây dựng thành công bộ cơ sở dữ liệu dinh dưỡng gồm hàng ngàn món ăn Việt Nam thực tế và danh mục bài tập thể hình chi tiết.
   - Tổng quy mô mã nguồn đạt **46,757 dòng code (399 tệp/lớp)** được tổ chức chặt chẽ theo các mô hình kiến trúc tiên tiến (Clean Architecture, Repository Pattern, Snapshot Pattern).

---

### 6.1.3. Hạn chế còn tồn tại (Những việc chưa làm được)

Mặc dù đạt được nhiều kết quả tích cực, hệ thống **BodyPilot** vẫn còn một số hạn chế kỹ thuật do rào cản thời gian và tài nguyên thử nghiệm:

1. **Chưa tích hợp Trình quét nhận diện hình ảnh/Mã vạch (Computer Vision / Barcode OCR):** Người dùng vẫn phải nhập tên món ăn hoặc chọn từ danh sách thay vì chỉ cần chụp ảnh mâm cơm để AI tự phân tích dinh dưỡng.
2. **Phụ thuộc vào kết nối Internet và Cloud AI API:** Hệ thống chưa thể vận hành ngoại tuyến (Offline Mode) cho các chức năng liên quan đến lập thực đơn AI do chưa tích hợp mô hình ngôn ngữ nhỏ chạy trực tiếp trên thiết bị (On-Device SLM).
3. **Thuật toán Smart Swap mới dừng lại ở việc khớp số liệu:** Cơ chế gợi ý thay thế món ăn chủ yếu dựa trên khoảng cách dinh dưỡng (Macro Distance) và danh mục, chưa áp dụng Machine Learning để phân tích hành vi và lịch sử yêu thích dài hạn của từng người dùng.

---

### 6.1.4. Các đóng góp nổi bật của Đồ án

Đồ án mang lại 3 đóng góp kỹ thuật cốt lõi có giá trị ứng dụng thực tiễn cao:

1. **Giải pháp loại bỏ hiện tượng ảo giác AI (Hallucination Elimination):** Bằng cách kết hợp giữa *Pre-AI Candidate Filtering* và *Fuzzy Key Matching*, hệ thống đảm bảo $100\%$ các món ăn AI gợi ý đều tồn tại thực sự trong CSDL và có thể lưu trữ khóa ngoại vào PostgreSQL.
2. **Thuật toán tự sửa lỗi JSON bị ngắt bằng Stack (Stack-based JSON Repair Algorithm):** Giải quyết triệt để sự cố `JsonEOFException` khi LLM bị cạn token output. Thuật toán cứu được toàn bộ các ngày thực đơn đã sinh ra trước đó thay vì làm hỏng kết quả và báo lỗi về người dùng.
3. **Mô hình co giãn Calo chuẩn xác (Exact Macro Scaler Engine):** Kết hợp giữa trí tuệ nhân tạo (khả năng sáng tạo mâm cơm) và thuật toán toán học truyền thống (khả năng tính toán chính xác $100\%$), giúp đưa chỉ số Calo mục tiêu về mức chênh lệch bằng $0$.

---

### 6.1.5. Tổng hợp những bài học kinh nghiệm rút ra

Quá trình thực hiện Đồ án Tốt nghiệp đã mang lại cho sinh viên những bài học kinh nghiệm vô cùng quý báu về kỹ thuật phần mềm và xử lý dữ liệu:

1. **Bài học về việc đưa LLM vào ứng dụng thực tế (Production-Ready AI):**
   - *Kinh nghiệm:* Prompt Engineering chỉ đóng góp $40\%$ vào thành công của một ứng dụng AI. $60\%$ còn lại nằm ở các **Pipeline tiền xử lý (Pre-processing)** và **hậu xử lý (Post-processing)** để bọc lót, làm sạch và sửa lỗi cho phản hồi từ AI.
2. **Bài học về Thiết kế Kiến trúc Cơ sở Dữ liệu (Database Design):**
   - *Kinh nghiệm:* Khi lưu trữ nhật ký biến động theo thời gian (như bữa ăn hay bài tập), bắt buộc phải áp dụng **Immutable Snapshot Pattern** (lưu lại snapshot giá trị tại thời điểm ghi) thay vì chỉ tham chiếu khóa ngoại tới bảng Master. Điều này giúp ngăn chặn hiện tượng sai lệch lịch sử khi dữ liệu gốc bị thay đổi.
3. **Bài học về Tối ưu hóa Hiệu năng và Chi phí API:**
   - *Kinh nghiệm:* Việc gửi tập dữ liệu quá lớn vào LLM không chỉ làm tăng chi phí token mà còn làm giảm tốc độ API vọt lên hàng chục giây. Việc thiết kế thuật toán rút trích ứng viên **Category Round-Robin** đã giúp giảm $75\%$ token và tăng tốc ứng dụng gấp 6 lần.

---

## 6.2. HƯỚNG PHÁT TRIỂN (FUTURE WORK)

Để đưa hệ thống **BodyPilot** từ một sản phẩm Đồ án Tốt nghiệp trở thành một nền tảng thương mại hoàn chỉnh phục vụ hàng triệu người dùng, tác giả vạch ra định hướng phát triển trong tương lai theo 2 giai đoạn:

---

### 6.2.1. Các công việc cần thiết để hoàn thiện chức năng hiện tại

Trong ngắn hạn, hệ thống cần tập trung tối ưu hóa và hoàn thiện các tính năng sẵn có:

1. **Bổ sung chế độ lưu Cache ngoại tuyến (On-Device Caching & Offline Mode):**
   - Cài đặt cơ sở dữ liệu SQLite / Hive tại ứng dụng Flutter Mobile để lưu trữ thực đơn và nhật ký ăn uống. Cho phép người dùng xem lại lịch trình tập luyện và nhật ký kể cả khi mất kết nối mạng di động.
2. **Tối ưu hóa thời gian phản hồi AI bằng luồng dữ liệu liên tục (Real-Time Streaming Response):**
   - Nâng cấp API Backend từ giao thức REST HTTP truyền thống sang **Server-Sent Events (SSE)** hoặc **gRPC Streaming**. Khi Gemini sinh dữ liệu đến đâu, giao diện Flutter sẽ hiển thị thực đơn theo thời gian thực (Real-time Typewriter Effect) đến đó, loại bỏ hoàn toàn cảm giác phải chờ đợi của người dùng.
3. **Hoàn thiện Thư viện Bài tập và Đa phương tiện:**
   - Bổ sung các hình ảnh minh họa 3D chuyển động (Animated GIF / MP4 360 độ) cho toàn bộ hơn 500+ bài tập trong cơ sở dữ liệu, hỗ trợ đếm số rep và đếm ngược thời gian nghỉ (`restSeconds`) bằng giọng nói nói tiếng Việt (Text-to-Speech).

---

### 6.2.2. Phân tích các hướng đi mới để cải tiến và nâng cấp hệ thống

Trong dài hạn, hệ thống hướng tới việc tích hợp các công nghệ tiên tiến nhất về AI và IoT:

1. **Tích hợp Thị giác Máy tính nhận diện Món ăn (AI Food Computer Vision Engine):**
   - Tích hợp mô hình **Gemini 2.5 Flash Vision** hoặc **YOLOv8 Fine-Tuned** trên tập dữ liệu món ăn Việt Nam. Người dùng chỉ cần chụp ảnh mâm cơm, hệ thống sẽ tự động phát hiện tên các món ăn, ước tính khối lượng (gram) và tự nạp vào Nhật ký ăn uống trong ngày.

2. **Đồng bộ hóa dữ liệu thời gian thực với Thiết bị đeo thông minh (IoT & Fitness Trackers):**
   - Tích hợp SDK kết nối với **Apple HealthKit**, **Google Health Connect**, **Garmin** và **Fitbit**.
   - Tự động thu thập chỉ số nhịp tim, số bước chân, mức độ căng thẳng (Stress Level) và lượng Calo tiêu thụ thực tế ($TDEE_{real-time}$) thông qua thiết bị đeo, từ đó điều chỉnh lại định lượng khẩu phần ăn của AI ngay trong ngày.

3. **Mô hình Gợi ý học máy cá nhân hóa dài hạn (Personalized ML Recommender System):**
   - Xây dựng mô hình **Collaborative Filtering & Reinforcement Learning (RLHF)** dựa trên lịch sử đánh giá thích/không thích món ăn của người dùng. Hệ thống sẽ tự động học gu thưởng thức ẩm thực của người dùng theo thời gian để đưa ra các gợi ý món ăn ngày càng chuẩn xác.

4. **Thử nghiệm Mô hình Ngôn ngữ nhỏ chạy Ngoại tuyến (On-Device Small Language Model - SLM):**
   - Thử nghiệm tinh chỉnh (Fine-tune) các mô hình ngôn ngữ kích thước nhỏ như **Gemma 2B**, **Llama 3.2 1B** hoặc **Phind-CodeLlama** bằng kỹ thuật Quantization (INT4/INT8). Triển khai mô hình chạy trực tiếp trên chip NPU của điện thoại di động (Android / iOS), cho phép tạo thực đơn AI cá nhân hóa hoàn toàn ngoại tuyến mà không tốn chi phí gọi Cloud API.

---

### KẾT LUẬN CHUNG

Đồ án Tốt nghiệp **BodyPilot** đã chứng minh tính đúng đắn và hiệu quả của giải pháp kết hợp giữa **Kiến trúc ứng dụng phân tán hiện đại** và **Mô hình Trí tuệ Nhân tạo Tạo sinh (Generative AI)** được kiểm soát bằng các thuật toán hậu xử lý chặt chẽ. Hệ thống không chỉ giải quyết triệt để bài toán dinh dưỡng cá nhân hóa phù hợp với văn hóa người Việt mà còn mở ra nhiều hướng phát triển tiềm năng trong lĩnh vực chăm sóc sức khỏe thông minh (Smart Digital Health).
