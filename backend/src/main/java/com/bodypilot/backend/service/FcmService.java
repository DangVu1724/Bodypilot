package com.bodypilot.backend.service;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
public class FcmService {

    /**
     * Gửi thông báo đến 1 thiết bị cụ thể qua FCM Token
     *
     * @param targetToken Token của thiết bị nhận (lấy từ Mobile gửi lên)
     * @param title       Tiêu đề thông báo
     * @param body        Nội dung thông báo
     * @return String     ID của tin nhắn gửi đi từ Firebase (nếu thành công)
     */
    public String sendNotification(String targetToken, String title, String body) {
        try {
            Notification notification = Notification.builder()
                    .setTitle(title)
                    .setBody(body)
                    .build();

            Message message = Message.builder()
                    .setToken(targetToken)
                    .setNotification(notification)
                    .build();

            String response = FirebaseMessaging.getInstance().send(message);
            System.out.println(">>> [FCM] Gửi thông báo thành công: " + response);
            return response;
        } catch (Exception e) {
            System.err.println(">>> [FCM] Lỗi gửi thông báo: " + e.getMessage());
            return null;
        }
    }

    /**
     * Gửi thông báo kèm theo dữ liệu tùy biến (Data Payload)
     *
     * @param targetToken Token của thiết bị nhận
     * @param title       Tiêu đề
     * @param body        Nội dung
     * @param data        Dữ liệu kèm theo
     * @return String     ID tin nhắn từ Firebase
     */
    public String sendNotificationWithData(String targetToken, String title, String body, Map<String, String> data) {
        try {
            Notification notification = Notification.builder()
                    .setTitle(title)
                    .setBody(body)
                    .build();

            Message message = Message.builder()
                    .setToken(targetToken)
                    .setNotification(notification)
                    .putAllData(data)
                    .build();

            String response = FirebaseMessaging.getInstance().send(message);
            System.out.println(">>> [FCM] Gửi thông báo kèm data thành công: " + response);
            return response;
        } catch (Exception e) {
            System.err.println(">>> [FCM] Lỗi gửi thông báo kèm data: " + e.getMessage());
            return null;
        }
    }

    /**
     * Gửi thông báo đến tất cả thiết bị đã đăng ký một Topic cụ thể
     *
     * @param topic tên Topic (ví dụ: "all_users")
     * @param title Tiêu đề
     * @param body  Nội dung
     * @return String ID tin nhắn từ Firebase
     */
    public String sendNotificationToTopic(String topic, String title, String body) {
        try {
            Notification notification = Notification.builder()
                    .setTitle(title)
                    .setBody(body)
                    .build();

            Message message = Message.builder()
                    .setTopic(topic)
                    .setNotification(notification)
                    .build();

            String response = FirebaseMessaging.getInstance().send(message);
            System.out.println(">>> [FCM Topic] Gửi thông báo thành công tới topic '" + topic + "': " + response);
            return response;
        } catch (Exception e) {
            System.err.println(">>> [FCM Topic] Lỗi gửi thông báo tới topic '" + topic + "': " + e.getMessage());
            return null;
        }
    }
}
