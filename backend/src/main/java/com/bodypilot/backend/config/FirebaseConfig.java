package com.bodypilot.backend.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;

import jakarta.annotation.PostConstruct;
import java.io.IOException;
import java.io.InputStream;

@Configuration
public class FirebaseConfig {

    private final ResourceLoader resourceLoader;

    @Value("${firebase.config-path}")
    private String configPath;

    public FirebaseConfig(ResourceLoader resourceLoader) {
        this.resourceLoader = resourceLoader;
    }

    @PostConstruct
    public void initializeFirebase() {
        try {
            Resource resource = resourceLoader.getResource(configPath);
            if (!resource.exists() && configPath.startsWith("file:secrets/")) {
                String fallbackPath = "file:backend/secrets/" + configPath.substring("file:secrets/".length());
                Resource fallbackResource = resourceLoader.getResource(fallbackPath);
                if (fallbackResource.exists()) {
                    resource = fallbackResource;
                }
            }

            try (InputStream serviceAccount = resource.getInputStream()) {
                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                        .build();

                if (FirebaseApp.getApps().isEmpty()) {
                    FirebaseApp.initializeApp(options);
                    System.out.println(">>> [Firebase] Khởi tạo Firebase Admin SDK thành công.");
                }
            }
        } catch (IOException e) {
            System.err.println(">>> [Firebase] Lỗi khởi tạo Firebase Admin SDK: " + e.getMessage());
        }
    }
}
