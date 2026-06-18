import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quick_paste/models/preset_text.dart';

void main() {
  group('PresetProvider 逻辑', () {
    test('PresetText 列表操作', () {
      final presets = <PresetText>[];
      expect(presets.isEmpty, true);

      presets.add(PresetText(id: '1', title: 'A', content: '内容A'));
      presets.add(PresetText(id: '2', title: 'B', content: '内容B'));
      expect(presets.length, 2);

      presets.removeWhere((p) => p.id == '1');
      expect(presets.length, 1);
      expect(presets.first.id, '2');
    });

    test('PresetText 更新', () {
      final presets = <PresetText>[
        PresetText(id: '1', title: 'A', content: '内容A'),
      ];
      final idx = presets.indexWhere((p) => p.id == '1');
      presets[idx] = presets[idx].copyWith(title: '新A', content: '新内容A');
      expect(presets.first.title, '新A');
      expect(presets.first.content, '新内容A');
    });

    test('PresetText 排序移动', () {
      final presets = <PresetText>[
        PresetText(id: '1', title: 'A', content: ''),
        PresetText(id: '2', title: 'B', content: ''),
        PresetText(id: '3', title: 'C', content: ''),
      ];
      // 将索引0移到索引2
      final item = presets.removeAt(0);
      presets.insert(1, item); // newIndex=2, 但removeAt后索引变了
      expect(presets[0].id, '2');
      expect(presets[1].id, '1');
      expect(presets[2].id, '3');
    });
  });
}
