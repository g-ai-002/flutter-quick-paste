import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quick_paste/models/preset_text.dart';

void main() {
  group('PresetText 边界情况', () {
    test('空标题和内容', () {
      final preset = PresetText(id: '1', title: '', content: '');
      expect(preset.title, '');
      expect(preset.content, '');
    });

    test('长文本内容', () {
      final longText = 'A' * 10000;
      final preset = PresetText(id: '1', title: '长文本', content: longText);
      expect(preset.content.length, 10000);
    });

    test('特殊字符', () {
      final preset = PresetText(
        id: '1',
        title: '特殊字符',
        content: '你好\n世界\t!@#\$%^&*()',
      );
      final json = preset.toJson();
      final restored = PresetText.fromJson(json);
      expect(restored.content, '你好\n世界\t!@#\$%^&*()');
    });

    test('多个预置文本去重', () {
      final presets = <PresetText>[
        PresetText(id: '1', title: 'A', content: ''),
        PresetText(id: '2', title: 'A', content: ''),
      ];
      final ids = presets.map((p) => p.id).toSet();
      expect(ids.length, 2);
    });
  });
}
