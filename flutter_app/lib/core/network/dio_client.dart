import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';

// ─────────────────────────────────────────
// Secure Storage Provider
// ─────────────────────────────────────────
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});

// ─────────────────────────────────────────
// Dio Client Provider
// ─────────────────────────────────────────
final dioProvider = Provider<Dio>((ref) {
  final storage = ref.read(secureStorageProvider);

  final dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  // Add interceptors
  dio.interceptors.addAll([
    _AuthInterceptor(storage, dio),
    _LoggingInterceptor(),
  ]);

  return dio;
});

// ─────────────────────────────────────────
// Auth Interceptor — auto-attach JWT token
// ─────────────────────────────────────────
class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  final Dio _dio;

  _AuthInterceptor(this._storage, this._dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for public endpoints
    final publicPaths = [
      ApiConstants.login,
      ApiConstants.register,
      ApiConstants.forgotPassword,
      ApiConstants.googleAuth,
      ApiConstants.sendOtp,
      ApiConstants.verifyOtp,
      ApiConstants.paymentWebhook,
    ];

    if (!publicPaths.any((p) => options.path.contains(p))) {
      final token = await _storage.read(key: AppConstants.tokenKey);
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Token expired — try refresh
      try {
        final refreshToken = await _storage.read(key: 'finpals_refresh_token');
        if (refreshToken != null) {
          final response = await _dio.post(
            ApiConstants.refreshToken,
            data: {'refreshToken': refreshToken},
          );
          final newToken = response.data['token'] as String;
          await _storage.write(key: AppConstants.tokenKey, value: newToken);

          // Retry original request
          final retryOptions = err.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $newToken';
          final retryResponse = await _dio.fetch(retryOptions);
          handler.resolve(retryResponse);
          return;
        }
      } catch (_) {
        // Refresh failed — clear session
        await _storage.deleteAll();
      }
    }
    handler.next(err);
  }
}

// ─────────────────────────────────────────
// Logging Interceptor (dev only)
// ─────────────────────────────────────────
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // ignore: avoid_print
    print('→ ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // ignore: avoid_print
    print('← ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // ignore: avoid_print
    print('✗ ${err.response?.statusCode} ${err.requestOptions.path}: ${err.message}');
    handler.next(err);
  }
}

// ─────────────────────────────────────────
// API Error Parser
// ─────────────────────────────────────────
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({required this.message, this.statusCode});

  factory ApiException.fromDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    String message = 'Terjadi kesalahan, coba lagi';
    if (data is Map && data.containsKey('error')) {
      message = data['error'] as String;
    } else if (data is Map && data.containsKey('message')) {
      message = data['message'] as String;
    } else if (e.type == DioExceptionType.connectionTimeout ||
               e.type == DioExceptionType.receiveTimeout) {
      message = 'Koneksi timeout, periksa internet Anda';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'Tidak dapat terhubung ke server';
    }

    return ApiException(message: message, statusCode: statusCode);
  }

  @override
  String toString() => message;
}
