import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/dio_client.dart';
import '../core/constants/api_constants.dart';
import '../models/models.dart';

final transactionServiceProvider = Provider<TransactionService>((ref) {
  return TransactionService(ref.read(dioProvider));
});

class TransactionService {
  final Dio _dio;
  TransactionService(this._dio);

  Future<List<TransactionModel>> getTransactions({
    int page = 1,
    int limit = 20,
    int? categoryId,
    String? startDate,
    String? endDate,
    String? search,
  }) async {
    try {
      final response = await _dio.get(ApiConstants.transactions, queryParameters: {
        'page': page,
        'limit': limit,
        if (categoryId != null) 'category_id': categoryId,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        if (search != null && search.isNotEmpty) 'search': search,
      });
      final list = response.data['data'] as List<dynamic>;
      return list
          .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<TransactionModel> createTransaction(
      Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.post(ApiConstants.transactions, data: data);
      return TransactionModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<TransactionModel> updateTransaction(
      int id, Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.put('${ApiConstants.transaction}/$id', data: data);
      return TransactionModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteTransaction(int id) async {
    try {
      await _dio.delete('${ApiConstants.transaction}/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> getSummary({String? month, String? year}) async {
    try {
      final response = await _dio.get(ApiConstants.summary, queryParameters: {
        if (month != null) 'month': month,
        if (year != null) 'year': year,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getMonthlyStats() async {
    try {
      final response = await _dio.get(ApiConstants.monthlyStats);
      return (response.data['data'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
