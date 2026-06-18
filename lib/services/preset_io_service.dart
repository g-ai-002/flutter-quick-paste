import 'dart:convert';

import '../models/preset_text.dart';
import 'log_service.dart';

/// 导入/导出预置文本的纯逻辑层。
///
/// 与文件系统/选择器解耦，只负责字符串 ⇄ `List<PresetText>` 的双向转换，
/// 便于单元测试，并在 UI 层组合使用 file_selector。
class PresetIoService {
  PresetIoService._();
  static final PresetIoService instance = PresetIoService._();

  /// 导出文件的格式版本，向前兼容时升级。
  static const int exportFormatVersion = 1;

  /// 将预置文本列表序列化成可读 JSON 字符串。
  ///
  /// 输出示例：
  /// ```json
  /// {
  ///   "format": "quick_paste_presets",
  ///   "version": 1,
  ///   "exportedAt": "2026-06-18T14:30:00.000Z",
  ///   "presets": [ {...}, ... ]
  /// }
  /// ```
  String exportToJson(List<PresetText> presets) {
    final payload = <String, dynamic>{
      'format': 'quick_paste_presets',
      'version': exportFormatVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'presets': presets.map((p) => p.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// 解析导入文件内容为预置文本列表。
  ///
  /// 容错：
  /// - 同时支持完整对象（`{format, version, presets: [...]}`）和裸数组 `[...]`
  /// - 单条解析失败仅跳过该条并写日志，不中断整体导入
  /// - 完全无法解析返回空列表并记录错误日志
  List<PresetText> parseImport(String raw) {
    if (raw.trim().isEmpty) return const [];
    dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (e, st) {
      LogService.instance.error('导入解析失败: 非合法 JSON', e, st);
      return const [];
    }

    final List<dynamic> rawList;
    if (decoded is Map<String, dynamic>) {
      final presets = decoded['presets'];
      if (presets is List) {
        rawList = presets;
      } else {
        LogService.instance.warning('导入文件缺少 presets 数组字段');
        return const [];
      }
    } else if (decoded is List) {
      rawList = decoded;
    } else {
      LogService.instance.warning('导入文件根类型非对象/数组');
      return const [];
    }

    final result = <PresetText>[];
    for (var i = 0; i < rawList.length; i++) {
      final item = rawList[i];
      if (item is! Map<String, dynamic>) {
        LogService.instance.warning('跳过第 $i 条：非对象');
        continue;
      }
      try {
        result.add(_presetFromLooseJson(item, i));
      } catch (e, st) {
        LogService.instance.error('跳过第 $i 条：解析失败', e, st);
      }
    }
    LogService.instance.info('成功解析 ${result.length}/${rawList.length} 条预置文本');
    return result;
  }

  /// 比 `PresetText.fromJson` 更宽松：允许缺少 id/时间戳，自动补齐。
  PresetText _presetFromLooseJson(Map<String, dynamic> json, int index) {
    final title = (json['title'] as String?)?.trim() ?? '';
    final content = (json['content'] as String?) ?? '';
    if (title.isEmpty && content.isEmpty) {
      throw const FormatException('title 与 content 同时为空');
    }
    final now = DateTime.now();
    return PresetText(
      id: (json['id'] as String?) ??
          '${now.microsecondsSinceEpoch}_$index',
      title: title.isEmpty ? '未命名 ${index + 1}' : title,
      content: content,
      createdAt: _parseDate(json['createdAt']) ?? now,
      updatedAt: _parseDate(json['updatedAt']) ?? now,
    );
  }

  DateTime? _parseDate(dynamic v) {
    if (v is! String || v.isEmpty) return null;
    return DateTime.tryParse(v);
  }
}

/// 导入策略
enum ImportStrategy {
  /// 合并：保留现有数据，新增列表中 id 不重复的条目
  merge,

  /// 覆盖：清空现有数据，使用导入列表替换
  replace,
}

/// 导入结果摘要，用于在 UI 上回显
class ImportResult {
  final int parsed;
  final int added;
  final int skipped;
  final ImportStrategy strategy;

  const ImportResult({
    required this.parsed,
    required this.added,
    required this.skipped,
    required this.strategy,
  });

  String summarize() {
    final action = strategy == ImportStrategy.merge ? '合并' : '覆盖';
    return '$action 完成：解析 $parsed 条，新增 $added 条，跳过 $skipped 条';
  }
}
