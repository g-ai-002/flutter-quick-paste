import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quick_paste/models/preset_text.dart';
import 'package:flutter_quick_paste/services/preset_io_service.dart';

void main() {
  final svc = PresetIoService.instance;

  group('PresetIoService 导出', () {
    test('导出包含 format/version/exportedAt/presets 字段', () {
      final list = [
        PresetText(id: '1', title: 'A', content: 'a'),
        PresetText(id: '2', title: 'B', content: 'b'),
      ];
      final raw = svc.exportToJson(list);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      expect(decoded['format'], 'quick_paste_presets');
      expect(decoded['version'], PresetIoService.exportFormatVersion);
      expect(decoded['exportedAt'], isA<String>());
      final presets = decoded['presets'] as List;
      expect(presets.length, 2);
      expect((presets.first as Map)['id'], '1');
    });

    test('空列表也能导出为合法 JSON', () {
      final raw = svc.exportToJson(const []);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      expect(decoded['presets'], isEmpty);
    });
  });

  group('PresetIoService 导入', () {
    test('完整导出对象可被原样解析', () {
      final original = [
        PresetText(id: '1', title: 'A', content: 'a'),
        PresetText(id: '2', title: 'B', content: 'b'),
      ];
      final raw = svc.exportToJson(original);
      final parsed = svc.parseImport(raw);
      expect(parsed.length, 2);
      expect(parsed[0].id, '1');
      expect(parsed[0].title, 'A');
      expect(parsed[1].content, 'b');
    });

    test('裸数组也能解析（兼容简易导入）', () {
      final raw = jsonEncode([
        {'id': 'x', 'title': 'X', 'content': 'xx'},
      ]);
      final parsed = svc.parseImport(raw);
      expect(parsed.length, 1);
      expect(parsed.first.id, 'x');
    });

    test('缺少 id/时间戳 时自动补齐', () {
      final raw = jsonEncode({
        'presets': [
          {'title': 'NoId', 'content': '内容'},
        ],
      });
      final parsed = svc.parseImport(raw);
      expect(parsed.length, 1);
      expect(parsed.first.id, isNotEmpty);
      expect(parsed.first.title, 'NoId');
    });

    test('单条非对象会被跳过，整体仍可导入', () {
      final raw = jsonEncode({
        'presets': [
          {'id': '1', 'title': 'OK', 'content': 'ok'},
          'not-an-object',
          42,
          {'id': '2', 'title': 'OK2', 'content': 'ok2'},
        ],
      });
      final parsed = svc.parseImport(raw);
      expect(parsed.length, 2);
      expect(parsed.map((p) => p.id), ['1', '2']);
    });

    test('title 和 content 同时为空的条目被跳过', () {
      final raw = jsonEncode({
        'presets': [
          {'id': '1', 'title': '', 'content': ''},
          {'id': '2', 'title': 'OK', 'content': ''},
        ],
      });
      final parsed = svc.parseImport(raw);
      expect(parsed.length, 1);
      expect(parsed.first.id, '2');
    });

    test('非法 JSON 返回空列表', () {
      expect(svc.parseImport('not a json').isEmpty, true);
      expect(svc.parseImport('').isEmpty, true);
    });

    test('根类型既非对象也非数组返回空列表', () {
      expect(svc.parseImport('123').isEmpty, true);
      expect(svc.parseImport('"string"').isEmpty, true);
    });

    test('对象缺少 presets 字段返回空列表', () {
      final raw = jsonEncode({'format': 'x'});
      expect(svc.parseImport(raw).isEmpty, true);
    });
  });

  group('ImportResult 摘要', () {
    test('合并策略文案', () {
      const r = ImportResult(
        parsed: 5,
        added: 3,
        skipped: 2,
        strategy: ImportStrategy.merge,
      );
      expect(r.summarize(), contains('合并'));
      expect(r.summarize(), contains('5'));
      expect(r.summarize(), contains('3'));
      expect(r.summarize(), contains('2'));
    });

    test('覆盖策略文案', () {
      const r = ImportResult(
        parsed: 4,
        added: 4,
        skipped: 0,
        strategy: ImportStrategy.replace,
      );
      expect(r.summarize(), contains('覆盖'));
    });
  });
}
