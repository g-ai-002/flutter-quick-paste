import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quick_paste/utils/constants.dart';

void main() {
  group('AppConstants', () {
    test('应用名称', () {
      expect(AppConstants.appName, '快速粘贴');
    });

    test('版本号', () {
      expect(AppConstants.version, '0.2.1');
    });
  });
}
