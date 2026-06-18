import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quick_paste/models/preset_text.dart';

void main() {
  group('PresetText', () {
    test('创建预置文本', () {
      final preset = PresetText(
        id: '1',
        title: '问候语',
        content: '你好，欢迎！',
      );
      expect(preset.id, '1');
      expect(preset.title, '问候语');
      expect(preset.content, '你好，欢迎！');
    });

    test('JSON 序列化与反序列化', () {
      final preset = PresetText(
        id: '1',
        title: '问候语',
        content: '你好',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      );
      final json = preset.toJson();
      final restored = PresetText.fromJson(json);
      expect(restored.id, preset.id);
      expect(restored.title, preset.title);
      expect(restored.content, preset.content);
      expect(restored.createdAt, preset.createdAt);
      expect(restored.updatedAt, preset.updatedAt);
    });

    test('copyWith 更新字段', () {
      final preset = PresetText(
        id: '1',
        title: '旧标题',
        content: '旧内容',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final updated = preset.copyWith(title: '新标题', content: '新内容');
      expect(updated.id, '1');
      expect(updated.title, '新标题');
      expect(updated.content, '新内容');
      expect(updated.createdAt, DateTime(2026, 1, 1));
      expect(updated.updatedAt, isNot(DateTime(2026, 1, 1)));
    });

    test('copyWith 部分更新', () {
      final preset = PresetText(
        id: '1',
        title: '标题',
        content: '内容',
      );
      final updated = preset.copyWith(title: '新标题');
      expect(updated.title, '新标题');
      expect(updated.content, '内容');
    });
  });
}
