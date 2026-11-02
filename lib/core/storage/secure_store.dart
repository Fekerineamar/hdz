import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around flutter_secure_storage for the handful of values the
/// app needs to persist safely (API key, optional credentials, session state).
/// Includes in-memory fallback to gracefully handle locked keyring issues on Linux.
class SecureStore {
  SecureStore._();
  static final SecureStore instance = SecureStore._();

  static const _storage = FlutterSecureStorage();
  final Map<String, String> _memoryFallback = {};
  bool _storageDisabled = false;

  static const _keyGeminiApiKey = 'gemini_api_key';
  static const _keyUsername = 'dzds_username';
  static const _keyPassword = 'dzds_password';

  Future<String?> _readSafe(String key) async {
    if (_storageDisabled) return _memoryFallback[key];
    try {
      final val = await _storage.read(key: key);
      if (val != null) {
        _memoryFallback[key] = val;
        return val;
      }
    } catch (e) {
      _storageDisabled = true;
      debugPrint('[SecureStore] Storage read error ($key): $e, using in-memory fallback');
    }
    return _memoryFallback[key];
  }

  Future<void> _writeSafe(String key, String value) async {
    _memoryFallback[key] = value;
    if (_storageDisabled) return;
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      _storageDisabled = true;
      debugPrint('[SecureStore] Storage write error ($key): $e, saved in fallback');
    }
  }

  Future<void> _deleteSafe(String key) async {
    _memoryFallback.remove(key);
    if (_storageDisabled) return;
    try {
      await _storage.delete(key: key);
    } catch (e) {
      _storageDisabled = true;
      debugPrint('[SecureStore] Storage delete error ($key): $e');
    }
  }

  Future<String?> get geminiApiKey => _readSafe(_keyGeminiApiKey);
  Future<void> setGeminiApiKey(String value) =>
      _writeSafe(_keyGeminiApiKey, value);

  Future<String?> get username => _readSafe(_keyUsername);
  Future<void> setUsername(String value) =>
      _writeSafe(_keyUsername, value);

  Future<String?> get password => _readSafe(_keyPassword);
  Future<void> setPassword(String value) =>
      _writeSafe(_keyPassword, value);

  Future<void> clearCredentials() async {
    await _deleteSafe(_keyUsername);
    await _deleteSafe(_keyPassword);
  }
}
