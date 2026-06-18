import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('关于', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Text('快速粘贴 v0.1.0', style: theme.textTheme.bodyMedium),
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
}
