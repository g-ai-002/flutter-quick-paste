import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quick_paste/models/preset_text.dart';
import 'package:flutter_quick_paste/services/preset_io_service.dart';

/// 复现 PresetProvider.importFromJson 中的合并/覆盖纯逻辑，
/// 与 Provider 内的 _save() 副作用解耦，专测策略行为。
({List<PresetText> presets, ImportResult result}) applyImport(
  List<PresetText> existing,
  List<PresetText> incoming, {
  required ImportStrategy strategy,
}) {
  final list = List<PresetText>.from(existing);
  int added = 0;
  int skipped = 0;
  if (strategy == ImportStrategy.replace) {
    list
      ..clear()
      ..addAll(incoming);
    added = incoming.length;
  } else {
    final ids = list.map((p) => p.id).toSet();
    for (final p in incoming) {
      if (ids.contains(p.id)) {
        skipped++;
      } else {
        list.add(p);
        ids.add(p.id);
        added++;
      }
    }
  }
  return (
    presets: list,
    result: ImportResult(
      parsed: incoming.length,
      added: added,
      skipped: skipped,
      strategy: strategy,
    ),
  );
}

void main() {
  group('导入合并/覆盖策略', () {
    final existing = [
      PresetText(id: '1', title: 'old1', content: 'a'),
      PresetText(id: '2', title: 'old2', content: 'b'),
    ];

    test('合并：跳过 id 重复条目', () {
      final incoming = [
        PresetText(id: '2', title: 'dup', content: 'x'),
        PresetText(id: '3', title: 'new3', content: 'c'),
      ];
      final r = applyImport(existing, incoming, strategy: ImportStrategy.merge);
      expect(r.presets.length, 3);
      expect(r.presets.map((p) => p.id), ['1', '2', '3']);
      expect(r.presets[1].title, 'old2'); // 重复未覆盖
      expect(r.result.added, 1);
      expect(r.result.skipped, 1);
    });

    test('合并：全是新 id 全部加入', () {
      final incoming = [
        PresetText(id: '10', title: 'a', content: 'x'),
        PresetText(id: '11', title: 'b', content: 'y'),
      ];
      final r = applyImport(existing, incoming, strategy: ImportStrategy.merge);
      expect(r.presets.length, 4);
      expect(r.result.added, 2);
      expect(r.result.skipped, 0);
    });

    test('覆盖：清空原有数据替换为导入数据', () {
      final incoming = [
        PresetText(id: '99', title: 'only', content: 'z'),
      ];
      final r = applyImport(existing, incoming,
          strategy: ImportStrategy.replace);
      expect(r.presets.length, 1);
      expect(r.presets.first.id, '99');
      expect(r.result.added, 1);
      expect(r.result.skipped, 0);
    });

    test('覆盖：传入空列表清空所有数据', () {
      final r = applyImport(existing, const [],
          strategy: ImportStrategy.replace);
      expect(r.presets, isEmpty);
      expect(r.result.added, 0);
    });
  });
}
