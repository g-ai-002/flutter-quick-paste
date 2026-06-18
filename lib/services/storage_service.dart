import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/preset_text.dart';
import 'log_service.dart';

/// 存储服务：预置文本持久化到 SharedPreferences
class StorageService {
  StorageService._();
  static StorageService? _instance;
  static bool _initializing = false;
  late SharedPreferences _prefs;

  static const String _keyPresets = 'presets_v1';
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyHotkeyModifiers = 'hotkey_modifiers';
  static const String _keyHotkeyKey = 'hotkey_key';

  static Future<StorageService> get instance async {
    if (_instance != null) return _instance!;
    if (_initializing) {
      // 等待正在进行的初始化完成
      for (int i = 0; i < 50 && _instance == null; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (_instance != null) return _instance!;
    }
    _initializing = true;
    try {
      _instance = StorageService._();
      await _instance!._init();
      return _instance!;
    } finally {
      _initializing = false;
    }
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- 预置文本 ---

  List<PresetText> loadPresets() {
    final raw = _prefs.getString(_keyPresets);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => PresetText.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      LogService.instance.error('加载预置文本失败', e, st);
      return [];
    }
  }

  Future<void> savePresets(List<PresetText> presets) async {
    final list = presets.map((p) => p.toJson()).toList();
    await _prefs.setString(_keyPresets, jsonEncode(list));
  }

  // --- 设置 ---

  bool get darkMode => _prefs.getBool(_keyDarkMode) ?? false;
  Future<void> setDarkMode(bool v) => _prefs.setBool(_keyDarkMode, v);

  int get hotkeyModifiers => _prefs.getInt(_keyHotkeyModifiers) ?? 0;
  Future<void> setHotkeyModifiers(int v) =>
      _prefs.setInt(_keyHotkeyModifiers, v);

  int get hotkeyKey => _prefs.getInt(_keyHotkeyKey) ?? 0;
  Future<void> setHotkeyKey(int v) => _prefs.setInt(_keyHotkeyKey, v);
}
