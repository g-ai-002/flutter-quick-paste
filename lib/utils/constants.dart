import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

/// 应用全局常量
class AppConstants {
  AppConstants._();

  static const String appName = '快速粘贴';
  static const String version = '0.2.4';

  /// 热键修饰键位掩码
  static const int modCtrl = 1;
  static const int modShift = 2;
  static const int modAlt = 4;
  static const int modMeta = 8;

  /// 默认热键: Ctrl+Shift+V
  static const int defaultHotkeyModifiers = modCtrl | modShift;
  static const int defaultHotkeyKey = 0x19; // USB HID usage for V

  /// 将位掩码转换为 HotKeyModifier 列表
  static List<HotKeyModifier> modifiersFromMask(int mask) {
    final list = <HotKeyModifier>[];
    if (mask & modCtrl != 0) list.add(HotKeyModifier.control);
    if (mask & modShift != 0) list.add(HotKeyModifier.shift);
    if (mask & modAlt != 0) list.add(HotKeyModifier.alt);
    if (mask & modMeta != 0) list.add(HotKeyModifier.meta);
    return list;
  }

  /// 将 USB HID usage 转换为 PhysicalKeyboardKey
  static PhysicalKeyboardKey keyFromHidUsage(int usage) {
    return PhysicalKeyboardKey(usage);
  }

  /// 将修饰键掩码格式化为可读字符串
  static String formatHotkey(int modifiers, int key) {
    final parts = <String>[];
    if (modifiers & modCtrl != 0) parts.add('Ctrl');
    if (modifiers & modShift != 0) parts.add('Shift');
    if (modifiers & modAlt != 0) parts.add('Alt');
    if (modifiers & modMeta != 0) parts.add('Win');
    final keyName = PhysicalKeyboardKey(key).debugName ?? 'Key($key)';
    parts.add(keyName.toUpperCase());
    return parts.join('+');
  }
}
