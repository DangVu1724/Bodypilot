import 'package:dio/dio.dart';
import 'package:mobile/core/routes/app_routes.dart';
import 'package:mobile/data/services/token_service.dart';
import 'package:mobile/core/routes/app_pages.dart';

class ApiClient {
  late final Dio dio;

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'http://10.0.2.2:8080/api/v1', // Android Emulator IP
        connectTimeout: const Duration(seconds: 30),
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
            print("🚨 [ApiClient] 401 Unauthorized received. Logging out and redirecting to welcome screen...");
            // Handle token expiration - Logout and redirect to login
            TokenService.removeToken();

            // Redirect to welcome screen
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
