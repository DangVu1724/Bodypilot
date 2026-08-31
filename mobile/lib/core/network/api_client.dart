import 'package:dio/dio.dart';
import 'package:mobile/core/routes/app_pages.dart';
import 'package:mobile/core/routes/app_routes.dart';
import 'package:mobile/data/services/token_service.dart';

import 'package:mobile/core/network/network_connectivity_service.dart';

class ApiClient {
  late final Dio dio;

  // --- SERVER URL CONFIGURATION ---
  // 1. Máy thật cùng Wi-Fi với máy tính: 'http://192.168.100.20:8080/api/v1'
  // 2. Android Emulator (Giả lập): 'http://10.0.2.2:8080/api/v1'
  // 3. iOS Simulator / Web / Windows: 'http://localhost:8080/api/v1'
  // 4. Render Cloud Production: 'https://bodypilot-to4y.onrender.com/api/v1'

  static const String physicalDeviceUrl = 'http://192.168.1.226:8080/api/v1';
  static const String localAndroidUrl = 'http://10.0.2.2:8080/api/v1';
  static const String localIosUrl = 'http://localhost:8080/api/v1';
  static const String renderCloudUrl = 'https://bodypilot-to4y.onrender.com/api/v1';

  // Chọn URL backend phù hợp:
  // - Nếu dùng máy thật kết nối Backend local trên PC: trả về physicalDeviceUrl
  // - Nếu dùng Render Cloud: trả về renderCloudUrl
  // - Nếu dùng máy giả lập: chọn localAndroidUrl hoặc localIosUrl
  static String get baseUrl {
    // Kết nối Render Cloud Backend
    return renderCloudUrl;
  }

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 300),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Chặn ngay lập tức các request khi thiết bị đang Offline để tránh spam và xung đột dữ liệu
          if (!networkConnectivityService.isOnline) {
            return handler.reject(
              DioException(
                requestOptions: options,
                error: 'Không có kết nối mạng. Vui lòng kết nối Internet để thực hiện thao tác!',
                type: DioExceptionType.connectionError,
              ),
            );
          }

          final token = TokenService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            options.headers.remove('Authorization');
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          if (e.response?.statusCode == 401) {
            TokenService.removeToken();
            AppPages.router.go(AppRoutes.welcome);
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    return await dio.post(path, data: data, queryParameters: queryParameters);
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    return await dio.put(path, data: data, queryParameters: queryParameters);
  }

  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    return await dio.patch(path, data: data, queryParameters: queryParameters);
  }

  Future<Response> delete(String path, {Map<String, dynamic>? queryParameters}) async {
    return await dio.delete(path, queryParameters: queryParameters);
  }
}

final apiClient = ApiClient();
