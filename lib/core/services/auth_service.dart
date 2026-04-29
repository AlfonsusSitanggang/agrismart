import 'package:dio/dio.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/secure_storage_service.dart';

class AuthService {
  final Dio _dio = ApiService().dio;
  final SecureStorageService _secureStorageService = SecureStorageService();

  Future<void> login({required String email, required String password}) async {
    final response = await _dio.post(
      '/login',
      data: {'email': email, 'password': password},
    );

    final token = response.data['token'];

    if (token != null) {
      await _secureStorageService.saveToken(token);
    } else {
      throw Exception('Token tidak ditemukan pada response');
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _dio.post(
      '/register',
      data: {'name': name, 'email': email, 'password': password},
    );
  }
}
