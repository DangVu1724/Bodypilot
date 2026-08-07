package com.bodypilot.backend.service;

import com.bodypilot.backend.model.dto.admin.AdminStatsDTO;

public interface AdminService {
    AdminStatsDTO getDashboardStats();
}
