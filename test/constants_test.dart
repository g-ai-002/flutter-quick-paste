import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quick_paste/utils/constants.dart';

void main() {
  group('AppConstants', () {
    test('应用名称', () {
      expect(AppConstants.appName, '快速粘贴');
    });

    test('版本号', () {
      expect(AppConstants.version, '0.2.2');
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
