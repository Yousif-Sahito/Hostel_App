import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'token', value: token);
  }

  static Future<String?> getToken() async {
    return _storage.read(key: 'token');
  }

  static Future<void> saveRole(String role) async {
    await _storage.write(key: 'role', value: role);
  }

  static Future<String?> getRole() async {
    return _storage.read(key: 'role');
  }

  static Future<void> saveUserName(String name) async {
    await _storage.write(key: 'fullName', value: name);
  }

  static Future<String?> getUserName() async {
    return _storage.read(key: 'fullName');
  }

  static Future<void> clear() async {
    await _storage.deleteAll();
  }
}
