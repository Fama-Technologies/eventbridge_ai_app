import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    // Initialize Hive
    await Hive.initFlutter();

    // Initialize SharedPreferences
    _prefs = await SharedPreferences.getInstance();
  }

  // --- SharedPreferences Helpers ---
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);
  String? getString(String key) => _prefs.getString(key);
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);
  bool? getBool(String key) => _prefs.getBool(key);
  Future<void> remove(String key) => _prefs.remove(key);

  // --- Token Helpers ---
  Future<void> saveToken(String token) async {
    await _prefs.setString('auth_token', token);
  }

  Future<String?> getToken() async {
    return _prefs.getString('auth_token');
  }

  Future<void> deleteToken() async {
    await _prefs.remove('auth_token');
  }

  // --- Hive Helpers ---
  Future<Box<T>> openBox<T>(String name) async {
    return await Hive.openBox<T>(name);
  }
}
