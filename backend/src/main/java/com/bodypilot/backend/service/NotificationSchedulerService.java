package com.bodypilot.backend.service;

import java.util.Map;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

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
                "Năng lượng chào ngày mới cùng BodyPilot! 🌅🍳",
                "Khởi đầu ngày mới với một bữa sáng dinh dưỡng và xem lịch tập hôm nay để duy trì phong độ nhé!",
                Map.of("category", "MEAL", "routeToPush", "/meal-plan"));
    }

    /**
     * Thông báo nhắc nhở ăn trưa & lập thực đơn lúc 11:45 hàng ngày (múi giờ
     * Asia/Ho_Chi_Minh)
     */
    @Scheduled(cron = "0 45 11 * * ?", zone = "Asia/Ho_Chi_Minh")
    public void sendLunchReminder() {
        log.info("⏰ [CRON 11:45] Đang phát thông báo nhắc bữa trưa & lập thực đơn...");
        fcmService.sendNotificationToTopicWithData(
                TOPIC_ALL_USERS,
                "Đã đến giờ nạp năng lượng bữa trưa! 🥗✨",
                "Dành 1 phút ghi nhận món ăn để BodyPilot giúp bạn theo dõi Calo & chuẩn hóa TDEE hôm nay nhé!",
                Map.of("category", "MEAL", "routeToPush", "/meal-plan"));
    }

    /**
     * Thông báo tập luyện chiều cá nhân hóa lúc 17:00 hàng ngày (múi giờ
     * Asia/Ho_Chi_Minh)
     */
    @Scheduled(cron = "0 0 17 * * ?", zone = "Asia/Ho_Chi_Minh")
    public void sendAfternoonWorkoutReminder() {
        log.info("⏰ [CRON 17:00] Đang phát thông báo giờ tập luyện chiều...");
        fcmService.sendNotificationToTopicWithData(
                TOPIC_ALL_USERS,
                "Bật chế độ tập luyện cùng BodyPilot! 💪🔥",
                "Buổi tập chiều đã sẵn sàng. Cùng hoàn thành các hiệp tập hôm nay để đốt cháy Calo hiệu quả nào!",
                Map.of("category", "WORKOUT", "routeToPush", "/workout-diary"));
    }

    /**
     * Thông báo đánh giá calo tối lúc 20:30 hàng ngày (múi giờ Asia/Ho_Chi_Minh)
     */
    @Scheduled(cron = "0 30 20 * * ?", zone = "Asia/Ho_Chi_Minh")
    public void sendEveningReviewReminder() {
        log.info("⏰ [CRON 20:30] Đang phát thông báo tổng kết calo tối...");
        fcmService.sendNotificationToTopicWithData(
                TOPIC_ALL_USERS,
                "Tổng kết mục tiêu dinh dưỡng ngày hôm nay 🌛📊",
                "Ghi lại bữa tối để xem bạn đã hoàn thành bao nhiêu % Calo & Macro mục tiêu ngày hôm nay nhé.",
                Map.of("category", "MEAL", "routeToPush", "/meal-plan"));
    }

    /**
     * Thông báo tổng kết tuần vào 20:00 Chủ Nhật hàng tuần (múi giờ
     * Asia/Ho_Chi_Minh)
     */
    @Scheduled(cron = "0 0 20 * * SUN", zone = "Asia/Ho_Chi_Minh")
    public void sendWeeklyReportReminder() {
        log.info("⏰ [CRON SUN 20:00] Đang phát thông báo báo cáo tuần...");
        fcmService.sendNotificationToTopicWithData(
                TOPIC_ALL_USERS,
                "Báo cáo sức khỏe & tiến độ tuần này! 📈🎉",
                "BodyPilot đã sẵn sàng bảng tổng kết 7 ngày qua. Hãy xem sự thay đổi tuyệt vời của bạn ngay thôi!",
                Map.of("category", "CHECKIN", "routeToPush", "/profile"));
    }
}
