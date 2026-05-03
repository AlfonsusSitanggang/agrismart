import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static const String tokenKey = 'auth_token';
  static const String biometricEnabledKey = 'biometric_enabled';
  static const String emailKey = 'saved_email';
  static const String passwordKey = 'saved_password';

  Future<void> saveToken(String token) async {
    await _storage.write(key: tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: tokenKey);
  }

  Future<void> saveBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: biometricEnabledKey,
      value: enabled.toString(),
    );
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: biometricEnabledKey);
    return value == 'true';
  }

  Future<void> saveEmail(String email) async {
    await _storage.write(key: emailKey, value: email);
  }

  Future<String?> getEmail() async {
    return await _storage.read(key: emailKey);
  }

  Future<void> savePassword(String password) async {
    await _storage.write(key: passwordKey, value: password);
  }

  Future<String?> getPassword() async {
    return await _storage.read(key: passwordKey);
  }

  Future<void> clearBiometricLoginData() async {
    await _storage.delete(key: biometricEnabledKey);
    await _storage.delete(key: emailKey);
    await _storage.delete(key: passwordKey);
  }
}