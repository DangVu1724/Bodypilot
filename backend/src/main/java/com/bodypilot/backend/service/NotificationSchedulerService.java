package com.bodypilot.backend.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationSchedulerService {

    private final FcmService fcmService;
    private static final String TOPIC_ALL_USERS = "all_users";

    /**
     * Thông báo chào buổi sáng lúc 07:00 hàng ngày (múi giờ Asia/Ho_Chi_Minh)
     */
    @Scheduled(cron = "0 0 7 * * ?", zone = "Asia/Ho_Chi_Minh")
    public void sendMorningReminder() {
        log.info("⏰ [CRON 07:00] Đang phát thông báo buổi sáng...");
        fcmService.sendNotificationToTopicWithData(
                TOPIC_ALL_USERS,
                "Chào buổi sáng cùng BodyPilot! 🍳🏋️",
                "Đừng quên ghi lại bữa sáng lành mạnh và xem hôm nay chúng ta sẽ tập gì nhé!",
                Map.of("category", "MEAL", "routeToPush", "/meal-plan")
        );
    }

    /**
     * Thông báo nhắc nhở ăn trưa & lập thực đơn lúc 11:45 hàng ngày (múi giờ Asia/Ho_Chi_Minh)
     */
    @Scheduled(cron = "0 45 11 * * ?", zone = "Asia/Ho_Chi_Minh")
    public void sendLunchReminder() {
        log.info("⏰ [CRON 11:45] Đang phát thông báo nhắc bữa trưa & lập thực đơn...");
        fcmService.sendNotificationToTopicWithData(
                TOPIC_ALL_USERS,
                "Bạn chưa chọn thực đơn hôm nay? 🥗",
                "Đến giờ ăn trưa rồi! Dành 1 phút ghi nhận món ăn hoặc nhờ Gemini AI lên thực đơn đạt chuẩn TDEE giúp bạn nhé.",
                Map.of("category", "MEAL", "routeToPush", "/meal-plan")
        );
    }

    /**
     * Thông báo tập luyện chiều cá nhân hóa lúc 17:00 hàng ngày (múi giờ Asia/Ho_Chi_Minh)
     */
    @Scheduled(cron = "0 0 17 * * ?", zone = "Asia/Ho_Chi_Minh")
    public void sendAfternoonWorkoutReminder() {
        log.info("⏰ [CRON 17:00] Đang phát thông báo giờ tập luyện chiều...");
        fcmService.sendNotificationToTopicWithData(
                TOPIC_ALL_USERS,
                "Thời gian tập luyện đã đến! 💪🏃",
                "Hôm nay bạn có lịch tập thể thao! Cùng chuẩn bị năng lượng và hoàn thành bài tập ngày hôm nay để giữ vững phong độ nhé.",
                Map.of("category", "WORKOUT", "routeToPush", "/workout-diary")
        );
    }

    /**
     * Thông báo đánh giá calo tối lúc 20:30 hàng ngày (múi giờ Asia/Ho_Chi_Minh)
     */
    @Scheduled(cron = "0 30 20 * * ?", zone = "Asia/Ho_Chi_Minh")
    public void sendEveningReviewReminder() {
        log.info("⏰ [CRON 20:30] Đang phát thông báo tổng kết calo tối...");
        fcmService.sendNotificationToTopicWithData(
                TOPIC_ALL_USERS,
                "Nhìn lại lượng calo hôm nay thôi! 🌛📊",
                "Đừng quên lưu lại bữa tối và cùng đánh giá mức độ hoàn thành mục tiêu ngày hôm nay nhé.",
                Map.of("category", "MEAL", "routeToPush", "/meal-plan")
        );
    }

    /**
     * Thông báo tổng kết tuần vào 20:00 Chủ Nhật hàng tuần (múi giờ Asia/Ho_Chi_Minh)
     */
    @Scheduled(cron = "0 0 20 * * SUN", zone = "Asia/Ho_Chi_Minh")
    public void sendWeeklyReportReminder() {
        log.info("⏰ [CRON SUN 20:00] Đang phát thông báo báo cáo tuần...");
        fcmService.sendNotificationToTopicWithData(
                TOPIC_ALL_USERS,
                "Báo cáo sức khỏe tuần này đã sẵn sàng! 📈🔥",
                "Cùng BodyPilot tổng kết quá trình thay đổi tích cực của bạn trong 7 ngày qua nhé!",
                Map.of("category", "CHECKIN", "routeToPush", "/profile")
        );
    }
}
