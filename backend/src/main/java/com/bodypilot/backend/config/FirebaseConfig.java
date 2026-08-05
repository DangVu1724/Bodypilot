package com.bodypilot.backend.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;

import jakarta.annotation.PostConstruct;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.Base64;

@Configuration
public class FirebaseConfig {

    private final ResourceLoader resourceLoader;

    @Value("${firebase.config-path:file:secrets/firebase-service-account.json}")
    private String configPath;

    public FirebaseConfig(ResourceLoader resourceLoader) {
        this.resourceLoader = resourceLoader;
    }

    @PostConstruct
    public void initializeFirebase() {
        try {
            if (!FirebaseApp.getApps().isEmpty()) {
                return;
            }

            InputStream serviceAccount = null;

            // 1. Check direct JSON in environment variable FIREBASE_CONFIG_JSON
            String envJson = System.getenv("FIREBASE_CONFIG_JSON");
            if (envJson != null && !envJson.isBlank()) {
                serviceAccount = new ByteArrayInputStream(envJson.getBytes(StandardCharsets.UTF_8));
            }

            // 2. Check Base64 encoded JSON in environment variable FIREBASE_BASE64
            if (serviceAccount == null) {
                String envBase64 = System.getenv("FIREBASE_BASE64");
                if (envBase64 != null && !envBase64.isBlank()) {
                    byte[] decoded = Base64.getDecoder().decode(envBase64.trim());
                    serviceAccount = new ByteArrayInputStream(decoded);
                }
            }

            // 3. Fallback to file resource path
            if (serviceAccount == null) {
                Resource resource = resourceLoader.getResource(configPath);
                if (!resource.exists() && configPath.startsWith("file:secrets/")) {
                    String fallbackPath = "file:backend/secrets/" + configPath.substring("file:secrets/".length());
                    Resource fallbackResource = resourceLoader.getResource(fallbackPath);
                    if (fallbackResource.exists()) {
                        resource = fallbackResource;
                    }
                }
                if (resource.exists()) {
                    serviceAccount = resource.getInputStream();
                }
            }

            if (serviceAccount != null) {
                try (InputStream stream = serviceAccount) {
                    FirebaseOptions options = FirebaseOptions.builder()
                            .setCredentials(GoogleCredentials.fromStream(stream))
                            .build();

                    FirebaseApp.initializeApp(options);
                    System.out.println(">>> [Firebase] Khởi tạo Firebase Admin SDK thành công.");
                }
            } else {
                System.out.println(">>> [Firebase] Không tìm thấy file/biến môi trường cấu hình Firebase. Bỏ qua khởi tạo.");
            }
        } catch (Exception e) {
            System.err.println(">>> [Firebase] Lỗi khởi tạo Firebase Admin SDK: " + e.getMessage());
        }
    }
}
