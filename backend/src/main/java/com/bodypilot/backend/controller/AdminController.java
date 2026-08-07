package com.bodypilot.backend.controller;

import com.bodypilot.backend.model.dto.admin.AdminStatsDTO;
import com.bodypilot.backend.model.dto.common.ApiResponse;
import com.bodypilot.backend.service.AdminService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/admin")
@RequiredArgsConstructor
public class AdminController {

    private final AdminService adminService;

    @GetMapping("/dashboard-stats")
    public ResponseEntity<ApiResponse<AdminStatsDTO>> getDashboardStats() {
        AdminStatsDTO stats = adminService.getDashboardStats();
        return ResponseEntity.ok(ApiResponse.ok("Dashboard stats retrieved successfully", stats));
    }
}
