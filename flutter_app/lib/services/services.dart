import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/dio_client.dart';
import '../core/constants/api_constants.dart';
import '../models/models.dart';

// ─────────────────────────────────────────
// OCR SERVICE
// ─────────────────────────────────────────
final ocrServiceProvider = Provider<OcrService>((ref) {
  return OcrService(ref.read(dioProvider));
});

class OcrService {
  final Dio _dio;
  OcrService(this._dio);

  Future<OcrResult> scanReceipt(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'receipt': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });
      final response = await _dio.post(
        ApiConstants.scanReceipt,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      return OcrResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

// ─────────────────────────────────────────
// AI SERVICE
// ─────────────────────────────────────────
final aiServiceProvider = Provider<AiService>((ref) {
  return AiService(ref.read(dioProvider));
});

class AiService {
  final Dio _dio;
  AiService(this._dio);

  Future<List<AiInsight>> getInsights() async {
    try {
      final response = await _dio.get(ApiConstants.aiInsights);
      final list = response.data['data'] as List<dynamic>;
      return list
          .map((e) => AiInsight.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<AiInsight> analyzeSpending() async {
    try {
      final response = await _dio.post(ApiConstants.aiAnalyze);
      return AiInsight.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<String>> getBudgetRecommendations() async {
    try {
      final response = await _dio.get(ApiConstants.aiRecommend);
      return (response.data['recommendations'] as List<dynamic>)
          .map((e) => e as String)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> getBudgetSuggestions() async {
    try {
      final response = await _dio.get(ApiConstants.aiBudgetSuggest);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

// ─────────────────────────────────────────
// PAYMENT SERVICE
// ─────────────────────────────────────────
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService(ref.read(dioProvider));
});

class PaymentService {
  final Dio _dio;
  PaymentService(this._dio);

  /// Returns snapToken to open Midtrans WebView
  Future<Map<String, dynamic>> createPayment() async {
    try {
      final response = await _dio.post(ApiConstants.createPayment);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<SubscriptionStatus> getSubscriptionStatus() async {
    try {
      final response =
          await _dio.get(ApiConstants.subscriptionStatus);
      return SubscriptionStatus.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<PaymentModel>> getPaymentHistory() async {
    try {
      final response = await _dio.get(ApiConstants.paymentHistory);
      final list = response.data['data'] as List<dynamic>;
      return list
          .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

// ─────────────────────────────────────────
// USER SERVICE
// ─────────────────────────────────────────
final userServiceProvider = Provider<UserService>((ref) {
  return UserService(ref.read(dioProvider));
});

class UserService {
  final Dio _dio;
  UserService(this._dio);

  Future<UserModel> getProfile() async {
    try {
      final response = await _dio.get(ApiConstants.profile);
      return UserModel.fromJson(
          response.data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<UserModel> updateProfile({
    String? name,
    String? phone,
  }) async {
    try {
      final response = await _dio.put(ApiConstants.updateProfile, data: {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
      });
      return UserModel.fromJson(
          response.data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<String> uploadAvatar(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });
      final response = await _dio.post(
        ApiConstants.uploadAvatar,
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );
      return response.data['avatarUrl'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.put(ApiConstants.changePassword, data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _dio.get(ApiConstants.categories);
      final list = response.data['data'] as List<dynamic>;
      return list
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<CategoryModel> createCategory({
    required String name,
    required String icon,
    required String color,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.categories,
        data: {
          'name': name,
          'icon': icon,
          'color': color,
        },
      );
      return CategoryModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _dio.get(ApiConstants.notifications);
      final list = response.data['data'] as List<dynamic>;
      return list
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
