import 'package:dio/dio.dart';
import 'package:mobile/core/routes/app_routes.dart';
import 'package:mobile/data/services/token_service.dart';
import 'package:mobile/core/routes/app_pages.dart';

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
          final token = TokenService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            options.headers.remove('Authorization');
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          print("🚨 [ApiClient Error] Request to ${e.requestOptions.uri} failed!");
          print("   Method: ${e.requestOptions.method}");
          print("   Type: ${e.type}");
          print("   Message: ${e.message}");
          if (e.response != null) {
            print("   Status Code: ${e.response?.statusCode}");
            print("   Response Data: ${e.response?.data}");
          } else {
            print("   No response received from server.");
          }
          if (e.response?.statusCode == 401) {
            print("🚨 [ApiClient] 401 Unauthorized received. Logging out...");
            TokenService.removeToken();
            AppPages.router.go(AppRoutes.welcome);
          } else if (e.response?.statusCode == 502 ||
              e.response?.statusCode == 503 ||
              e.response?.statusCode == 504) {
            print("🛠️ [ApiClient] Server maintenance / busy status (${e.response?.statusCode}). Switching to offline mode.");
          } else if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.connectionError) {
            print("⚡ [ApiClient] Network connection timeout/error. Fallback to offline mode.");
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
