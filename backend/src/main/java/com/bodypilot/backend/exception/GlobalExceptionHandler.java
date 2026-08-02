package com.bodypilot.backend.exception;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;

import jakarta.servlet.http.HttpServletRequest;
import java.util.HashMap;
import java.util.Map;

@ControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> handleException(Exception e, HttpServletRequest request) {
        log.error("🚨 Unhandled Exception occurred at [{} {}] - Message: {}", request.getMethod(), request.getRequestURI(), e.getMessage(), e);
        Map<String, Object> body = new HashMap<>();
        body.put("message", "An unexpected error occurred");
        body.put("error", e.getMessage());
        body.put("status", HttpStatus.INTERNAL_SERVER_ERROR.value());
        return new ResponseEntity<>(body, HttpStatus.INTERNAL_SERVER_ERROR);
    }

    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<Map<String, Object>> handleRuntimeException(RuntimeException e, HttpServletRequest request) {
        log.error("🚨 Runtime Exception occurred at [{} {}] - Message: {}", request.getMethod(), request.getRequestURI(), e.getMessage(), e);
        Map<String, Object> body = new HashMap<>();
        body.put("message", e.getMessage());
        body.put("status", HttpStatus.INTERNAL_SERVER_ERROR.value());
        return new ResponseEntity<>(body, HttpStatus.INTERNAL_SERVER_ERROR);
    }
}
