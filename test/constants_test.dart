import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quick_paste/utils/constants.dart';

String _readPubspecVersion() {
  final file = File('pubspec.yaml');
  for (final line in file.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.startsWith('version:')) {
      return trimmed.substring('version:'.length).trim();
    }
  }
  fail('pubspec.yaml 缺少 version 字段');
}

void main() {
  group('AppConstants', () {
    test('应用名称', () {
      expect(AppConstants.appName, '快速粘贴');
    });

    test('版本号与 pubspec.yaml 保持一致', () {
      expect(AppConstants.version, _readPubspecVersion());
    });

    test('热键修饰键掩码互不重叠', () {
      final masks = [
        AppConstants.modCtrl,
        AppConstants.modShift,
        AppConstants.modAlt,
        AppConstants.modMeta,
      ];
      for (int i = 0; i < masks.length; i++) {
        for (int j = i + 1; j < masks.length; j++) {
          expect(masks[i] & masks[j], 0);
        }
      }
    });

    test('modifiersFromMask 正确转换', () {
      final result = AppConstants.modifiersFromMask(
        AppConstants.modCtrl | AppConstants.modShift,
      );
      expect(result.length, 2);
    });

    test('formatHotkey 格式化', () {
      final label = AppConstants.formatHotkey(
        AppConstants.modCtrl | AppConstants.modShift,
        0x19, // V
      );
      expect(label, contains('Ctrl'));
      expect(label, contains('Shift'));
    });

    test('默认热键为 Ctrl+Shift+V', () {
      expect(AppConstants.defaultHotkeyModifiers,
          AppConstants.modCtrl | AppConstants.modShift);
      expect(AppConstants.defaultHotkeyKey, 0x19);
    });
  });
}
