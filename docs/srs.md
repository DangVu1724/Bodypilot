# Software Requirements Specification

## For NutriFit AI

Version 0.1
Prepared by Vũ Đặng
{{organization}}
2026-04-14

## Table of Contents

<!-- TOC -->

* [1. Introduction](#1-introduction)

  * [1.1 Document Purpose](#11-document-purpose)
  * [1.2 Product Scope](#12-product-scope)
  * [1.3 Definitions, Acronyms, and Abbreviations](#13-definitions-acronyms-and-abbreviations)
  * [1.4 References](#14-references)
  * [1.5 Document Overview](#15-document-overview)
* [2. Product Overview](#2-product-overview)

  * [2.1 Product Perspective](#21-product-perspective)
  * [2.2 Product Functions](#22-product-functions)
  * [2.3 Product Constraints](#23-product-constraints)
  * [2.4 User Characteristics](#24-user-characteristics)
  * [2.5 Assumptions and Dependencies](#25-assumptions-and-dependencies)
  * [2.6 Apportioning of Requirements](#26-apportioning-of-requirements)
* [3. Requirements](#3-requirements)

  * [3.1 External Interfaces](#31-external-interfaces)
  * [3.2 Functional](#32-functional)
  * [3.3 Quality of Service](#33-quality-of-service)
  * [3.4 Compliance](#34-compliance)
  * [3.5 Design and Implementation](#35-design-and-implementation)
  * [3.6 AI/ML](#36-aiml)
* [4. Verification](#4-verification)
* [5. Appendixes](#5-appendixes)

<!-- TOC -->

## Revision History

| Name    | Date       | Reason For Changes | Version |
| ------- | ---------- | ------------------ | ------- |
| Vũ Đặng | 2026-04-14 | Initial draft      | 0.1     |

## 1. Introduction

Tài liệu này mô tả đặc tả yêu cầu phần mềm (SRS) cho hệ thống NutriFit AI – một ứng dụng di động hỗ trợ thiết lập chế độ dinh dưỡng và lộ trình tập luyện cá nhân hóa. Tài liệu cung cấp cái nhìn tổng quan về mục tiêu, phạm vi, và các yêu cầu chức năng cũng như phi chức năng của hệ thống.

### 1.1 Document Purpose

Tài liệu SRS này nhằm xác định các yêu cầu mà hệ thống phải đáp ứng, làm cơ sở cho việc thiết kế, phát triển, kiểm thử và triển khai. Đối tượng sử dụng bao gồm đội phát triển, QA, và các bên liên quan nhằm đảm bảo hệ thống được xây dựng đúng mục tiêu.

### 1.2 Product Scope

NutriFit AI là ứng dụng di động giúp người dùng xây dựng chế độ ăn uống và luyện tập cá nhân hóa dựa trên dữ liệu sinh trắc học và mục tiêu cá nhân. Hệ thống cung cấp tính năng tính toán calo (BMR, TDEE), đề xuất thực đơn và bài tập bằng AI, theo dõi tiến trình và phân tích dữ liệu.

### 1.3 Definitions, Acronyms, and Abbreviations

| Term | Definition                                                          |
| ---- | ------------------------------------------------------------------- |
| BMR  | Basal Metabolic Rate - Lượng calo cơ thể tiêu thụ khi nghỉ ngơi     |
| TDEE | Total Daily Energy Expenditure - Tổng năng lượng tiêu thụ hàng ngày |
| AI   | Artificial Intelligence                                             |
| API  | Application Programming Interface                                   |

### 1.4 References

* WHO Nutrition Guidelines (Informative)
* Flutter Documentation (Informative)
* Spring Boot Documentation (Informative)

### 1.5 Document Overview

Tài liệu gồm các phần chính: tổng quan hệ thống, yêu cầu chi tiết, và phương pháp kiểm chứng. Các yêu cầu được tổ chức theo chuẩn có thể kiểm thử.

## 2. Product Overview

### 2.1 Product Perspective

Hệ thống là một ứng dụng độc lập bao gồm frontend (Flutter) và backend (Spring Boot), tích hợp AI và cơ sở dữ liệu dinh dưỡng.

### 2.2 Product Functions

* Đăng ký/đăng nhập người dùng
* Tính toán BMR, TDEE
* Đề xuất thực đơn
* Đề xuất lộ trình tập luyện
* Chatbot AI
* Theo dõi tiến trình

### 2.3 Product Constraints

* Hệ thống phải sử dụng Flutter cho frontend
* Backend phải sử dụng Spring Boot
* Phải hỗ trợ Android

### 2.4 User Characteristics

* Người dùng phổ thông
* Người tập gym
* Người cần giảm cân/tăng cân

### 2.5 Assumptions and Dependencies

* Người dùng cung cấp dữ liệu chính xác
* Phụ thuộc API dinh dưỡng

### 2.6 Apportioning of Requirements

| Module | Requirement    |
| ------ | -------------- |
| Auth   | Đăng nhập      |
| AI     | Gợi ý thực đơn |

## 3. Requirements

### 3.1 External Interfaces

#### 3.1.1 User Interfaces

* Giao diện mobile thân thiện

#### 3.1.2 Software Interfaces

* API dinh dưỡng
* API AI

### 3.2 Functional

Danh sách các chức năng chính của hệ thống (chưa bao gồm flow chi tiết):

#### Nhóm 1: Quản lý người dùng

* Đăng ký tài khoản
* Đăng nhập/đăng xuất
* Cập nhật hồ sơ cá nhân (chiều cao, cân nặng, tuổi, giới tính)
* Thiết lập mục tiêu (giảm cân, tăng cân, giữ dáng)

#### Nhóm 2: Tính toán dinh dưỡng

* Tính toán BMR
* Tính toán TDEE
* Gợi ý lượng calo cần nạp theo mục tiêu
* Phân bổ macro (protein, carb, fat)

#### Nhóm 3: Thực đơn (Meal Plan)

* Tạo thực đơn hàng ngày bằng AI
* Tùy chỉnh thực đơn theo sở thích
* Tra cứu món ăn và giá trị dinh dưỡng
* Lưu thực đơn yêu thích

#### Nhóm 4: Lộ trình tập luyện (Workout Plan)

* Tạo kế hoạch tập luyện cá nhân hóa
* Gợi ý bài tập theo mục tiêu
* Xem chi tiết bài tập (hình ảnh/video)
* Lưu và chỉnh sửa kế hoạch tập

#### Nhóm 5: Theo dõi tiến trình

* Ghi nhận bữa ăn hàng ngày
* Ghi nhận buổi tập
* Theo dõi cân nặng theo thời gian
* Hiển thị biểu đồ tiến trình

#### Nhóm 6: Chatbot AI

* Hỏi đáp về dinh dưỡng
* Hỏi đáp về bài tập
* Gợi ý nhanh thực đơn/bài tập

#### Nhóm 7: Quản lý dữ liệu & hệ thống

* Lưu trữ lịch sử người dùng
* Đồng bộ dữ liệu giữa thiết bị và server
* Quản lý thư viện món ăn và bài tập

### 3.3 Quality of Service

#### 3.3.1 Performance

* Thời gian phản hồi < 2s

#### 3.3.2 Security

* Xác thực JWT

### 3.6 AI/ML

#### 3.6.1 Model Specification

* Gợi ý thực đơn và bài tập

## 4. Verification

| Requirement ID | Verification Method | Status  |
| -------------- | ------------------- | ------- |
| REQ-FUNC-001   | Test                | Pending |

## 5. Appendixes

* Sơ đồ kiến trúc hệ thống
