import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/dio_client.dart';
import '../core/constants/api_constants.dart';
import '../models/models.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(dioProvider));
});

class AuthService {
  final Dio _dio;
  AuthService(this._dio);

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(ApiConstants.login, data: {
        'email': email,
        'password': password,
      });
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final response = await _dio.post(ApiConstants.register, data: {
        'name': name,
        'email': email,
        'password': password,
        if (phone != null) 'phone': phone,
      });
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiConstants.logout);
    } catch (_) {
      // Ignore logout errors — clear local state anyway
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post(ApiConstants.forgotPassword, data: {'email': email});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _dio.post(ApiConstants.resetPassword, data: {
        'token': token,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> sendOtp(String phone) async {
    try {
      await _dio.post(ApiConstants.sendOtp, data: {'phone': phone});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<AuthResponse> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(ApiConstants.verifyOtp, data: {
        'phone': phone,
        'otp': otp,
      });
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<AuthResponse> loginWithGoogle(String idToken) async {
    try {
      final response = await _dio.post(ApiConstants.googleAuth, data: {
        'idToken': idToken,
      });
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
