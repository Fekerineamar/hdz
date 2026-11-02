import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around flutter_secure_storage for the handful of values the
/// app needs to persist safely (API key, optional credentials, session state).
class SecureStore {
  SecureStore._();
  static final SecureStore instance = SecureStore._();

  static const _storage = FlutterSecureStorage();

  static const _keyGeminiApiKey = 'gemini_api_key';
  static const _keyUsername = 'dzds_username';
  static const _keyPassword = 'dzds_password';

  Future<String?> get geminiApiKey => _storage.read(key: _keyGeminiApiKey);
  Future<void> setGeminiApiKey(String value) =>
      _storage.write(key: _keyGeminiApiKey, value: value);

  Future<String?> get username => _storage.read(key: _keyUsername);
  Future<void> setUsername(String value) =>
      _storage.write(key: _keyUsername, value: value);

  Future<String?> get password => _storage.read(key: _keyPassword);
  Future<void> setPassword(String value) =>
      _storage.write(key: _keyPassword, value: value);

  Future<void> clearCredentials() async {
    await _storage.delete(key: _keyUsername);
    await _storage.delete(key: _keyPassword);
  }
}
