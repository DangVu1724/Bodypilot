package com.bodypilot.backend.service;

import com.bodypilot.backend.model.dto.checkin.CheckInRequest;
import com.bodypilot.backend.model.dto.checkin.CheckInResultResponse;
import com.bodypilot.backend.model.dto.checkin.CheckInStatusResponse;

import java.util.UUID;

public interface CheckInService {
    CheckInStatusResponse getCheckInStatus(UUID userId);
    CheckInResultResponse submitCheckIn(UUID userId, CheckInRequest request);
}
