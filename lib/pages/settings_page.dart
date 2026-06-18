import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/preset_provider.dart';
import '../providers/settings_provider.dart';
import '../services/log_service.dart';
import '../services/preset_io_service.dart';
import '../utils/constants.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    final hotkeyLabel = AppConstants.formatHotkey(
      settings.hotkeyModifiers != 0
          ? settings.hotkeyModifiers
          : AppConstants.defaultHotkeyModifiers,
      settings.hotkeyKey != 0
          ? settings.hotkeyKey
          : AppConstants.defaultHotkeyKey,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('深色模式'),
            subtitle: const Text('切换浅色/深色主题'),
            value: settings.darkMode,
            onChanged: (v) => settings.setDarkMode(v),
          ),
          const Divider(),
          ListTile(
            title: const Text('全局热键'),
            subtitle: Text(hotkeyLabel),
            leading: const Icon(Icons.keyboard),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: const Text('导出预置文本'),
            subtitle: const Text('保存为 JSON 文件，便于备份或迁移'),
            onTap: () => _exportPresets(context),
          ),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('导入预置文本'),
            subtitle: const Text('从 JSON 文件导入，支持合并或覆盖'),
            onTap: () => _importPresets(context),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('关于', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Text('快速粘贴 v${AppConstants.version}',
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  '快捷键弹出预置文本列表，双击自动粘贴到当前光标处',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPresets(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<PresetProvider>();
    if (provider.presets.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('暂无预置文本可导出')),
      );
      return;
    }

    final json = provider.exportToJson();
    final defaultName =
        'quick_paste_presets_${_timestamp()}.json';
    try {
      final location = await getSaveLocation(
        suggestedName: defaultName,
        acceptedTypeGroups: const [
          XTypeGroup(label: 'JSON', extensions: ['json']),
        ],
      );
      if (location == null) return;
      final file = File(location.path);
      await file.writeAsString(json);
      LogService.instance.info('导出预置文本到 ${location.path}');
      messenger.showSnackBar(
        SnackBar(content: Text('已导出 ${provider.presets.length} 条到 ${location.path}')),
      );
    } catch (e, st) {
      LogService.instance.error('导出失败', e, st);
      messenger.showSnackBar(
        SnackBar(content: Text('导出失败: $e')),
      );
    }
  }

  Future<void> _importPresets(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<PresetProvider>();

    XFile? file;
    try {
      file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(label: 'JSON', extensions: ['json']),
        ],
      );
    } catch (e, st) {
      LogService.instance.error('打开导入文件失败', e, st);
      messenger.showSnackBar(SnackBar(content: Text('打开文件失败: $e')));
      return;
    }
    if (file == null) return;

    final raw = await file.readAsString();
    if (!context.mounted) return;

    final strategy = await showDialog<ImportStrategy>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('选择导入方式'),
        content: const Text(
          '合并：保留现有预置文本，仅添加 ID 不重复的条目。\n覆盖：清空现有预置文本，使用文件中的内容替换。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ImportStrategy.replace),
            child: const Text('覆盖'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ImportStrategy.merge),
            child: const Text('合并'),
          ),
        ],
      ),
    );
    if (strategy == null) return;

    try {
      final result = await provider.importFromJson(raw, strategy: strategy);
      messenger.showSnackBar(SnackBar(content: Text(result.summarize())));
    } catch (e, st) {
      LogService.instance.error('导入失败', e, st);
      messenger.showSnackBar(SnackBar(content: Text('导入失败: $e')));
    }
  }

  String _timestamp() {
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${n.year}${two(n.month)}${two(n.day)}_${two(n.hour)}${two(n.minute)}${two(n.second)}';
  }
}
