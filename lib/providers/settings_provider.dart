import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';

/// 设置状态管理
class SettingsProvider extends ChangeNotifier {
  final StorageService _storage;

  SettingsProvider(this._storage);

  bool get darkMode => _storage.darkMode;
  int get hotkeyModifiers => _storage.hotkeyModifiers;
  int get hotkeyKey => _storage.hotkeyKey;

  Future<void> setDarkMode(bool v) async {
    await _storage.setDarkMode(v);
    notifyListeners();
  }

  Future<void> setHotkey(int modifiers, int key) async {
    await _storage.setHotkeyModifiers(modifiers);
    await _storage.setHotkeyKey(key);
    notifyListeners();
  }
}
