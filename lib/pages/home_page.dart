import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/preset_text.dart';
import '../providers/preset_provider.dart';
import '../services/paste_service.dart';
import '../services/log_service.dart';
import '../widgets/preset_tile.dart';
import '../widgets/scale_animation.dart';
import '../widgets/edit_preset_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchCtrl = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PresetProvider>();
    final presets = provider.filteredPresets;

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: const InputDecoration(
                  hintText: '搜索标题或内容...',
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (v) => provider.setSearchQuery(v),
              )
            : const Text('快速粘贴'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search, size: 22),
            tooltip: _showSearch ? '关闭搜索' : '搜索',
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchCtrl.clear();
                  provider.setSearchQuery('');
                }
              });
            },
          ),
          if (!_showSearch) ...[
            IconButton(
              icon: const Icon(Icons.add, size: 22),
              tooltip: '添加预置文本',
              onPressed: () => _showEditDialog(context),
            ),
            IconButton(
              icon: const Icon(Icons.settings, size: 22),
              tooltip: '设置',
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ],
      ),
      body: presets.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.content_paste,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text(
                    provider.searchQuery.isNotEmpty ? '无匹配结果' : '暂无预置文本',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider.searchQuery.isNotEmpty
                        ? '尝试其他关键词'
                        : '点击右上角 + 添加',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            )
          : ReorderableListView.builder(
              itemCount: presets.length,
              onReorderItem: (oldIndex, newIndex) {
                context.read<PresetProvider>().move(oldIndex, newIndex);
              },
              buildDefaultDragHandles: true,
              proxyDecorator: (child, index, animation) {
                return ScaleAnimation(
                  listenable: animation,
                  child: child,
                );
              },
              itemBuilder: (context, index) {
                final preset = presets[index];
                return PresetTile(
                  key: ValueKey(preset.id),
                  preset: preset,
                  onDoubleTap: () => _pasteText(preset),
                  onEdit: () => _showEditDialog(context, preset: preset),
                  onDelete: () => _confirmDelete(context, preset),
                );
              },
            ),
    );
  }

  void _pasteText(PresetText preset) {
    PasteService.instance.paste(preset.content).catchError((e) {
      LogService.instance.error('粘贴失败: ${preset.title}', e);
    });
  }

  void _confirmDelete(BuildContext context, PresetText preset) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除「${preset.title}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              context.read<PresetProvider>().remove(preset.id);
              Navigator.pop(ctx);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, {PresetText? preset}) {
    showDialog<Map<String, String>>(
      context: context,
      builder: (_) => EditPresetDialog(preset: preset),
    ).then((result) {
      if (result == null || !mounted) return;
      final title = result['title']!;
      final content = result['content']!;
      if (preset != null) {
        context.read<PresetProvider>().update(preset.id, title, content);
      } else {
        context.read<PresetProvider>().add(title, content);
      }
    });
  }
}
