package com.bodypilot.backend.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

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
        fcmService.sendNotificationToTopic(
                TOPIC_ALL_USERS,
                "Chào buổi sáng cùng BodyPilot! 🍳🏋️",
                "Đừng quên ghi lại bữa sáng lành mạnh và xem hôm nay chúng ta sẽ tập gì nhé!"
        );
    }

    /**
     * Thông báo nhắc nhở ăn trưa lúc 12:00 hàng ngày (múi giờ Asia/Ho_Chi_Minh)
     */
    @Scheduled(cron = "0 0 12 * * ?", zone = "Asia/Ho_Chi_Minh")
    public void sendLunchReminder() {
        log.info("⏰ [CRON 12:00] Đang phát thông báo nhắc bữa trưa...");
        fcmService.sendNotificationToTopic(
                TOPIC_ALL_USERS,
                "Đến giờ ăn trưa rồi! 🥗💧",
                "Hãy ghi lại thực đơn hôm nay để BodyPilot tính toán lượng calo giúp bạn nhé!"
        );
    }

    /**
     * Thông báo tập luyện chiều lúc 17:30 hàng ngày (múi giờ Asia/Ho_Chi_Minh)
     */
    @Scheduled(cron = "0 30 17 * * ?", zone = "Asia/Ho_Chi_Minh")
    public void sendAfternoonWorkoutReminder() {
        log.info("⏰ [CRON 17:30] Đang phát thông báo giờ tập luyện chiều...");
        fcmService.sendNotificationToTopic(
                TOPIC_ALL_USERS,
                "Thời gian tập luyện lý tưởng đã đến! 💪🏃",
                "Cùng hoàn thành mục tiêu thể thao hôm nay để khỏe mạnh và tràn đầy năng lượng nào!"
        );
    }

    /**
     * Thông báo đánh giá calo tối lúc 20:30 hàng ngày (múi giờ Asia/Ho_Chi_Minh)
     */
    @Scheduled(cron = "0 30 20 * * ?", zone = "Asia/Ho_Chi_Minh")
    public void sendEveningReviewReminder() {
        log.info("⏰ [CRON 20:30] Đang phát thông báo tổng kết calo tối...");
        fcmService.sendNotificationToTopic(
                TOPIC_ALL_USERS,
                "Nhìn lại lượng calo hôm nay thôi! 🌛📊",
                "Đừng quên lưu lại bữa tối và cùng đánh giá mức độ hoàn thành mục tiêu ngày hôm nay nhé."
        );
    }

    /**
     * Thông báo tổng kết tuần vào 20:00 Chủ Nhật hàng tuần (múi giờ Asia/Ho_Chi_Minh)
     */
    @Scheduled(cron = "0 0 20 * * SUN", zone = "Asia/Ho_Chi_Minh")
    public void sendWeeklyReportReminder() {
        log.info("⏰ [CRON SUN 20:00] Đang phát thông báo báo cáo tuần...");
        fcmService.sendNotificationToTopic(
                TOPIC_ALL_USERS,
                "Báo cáo sức khỏe tuần này đã sẵn sàng! 📈🔥",
                "Cùng BodyPilot tổng kết quá trình thay đổi tích cực của bạn trong 7 ngày qua nhé!"
        );
    }
}
