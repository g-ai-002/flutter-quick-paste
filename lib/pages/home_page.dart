import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/preset_text.dart';
import '../providers/preset_provider.dart';
import '../services/paste_service.dart';
import '../services/log_service.dart';
import '../widgets/preset_tile.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final presets = context.watch<PresetProvider>().presets;

    return Scaffold(
      appBar: AppBar(
        title: const Text('快速粘贴'),
        actions: [
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
                    '暂无预置文本',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '点击右上角 + 添加',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            )
          : ReorderableListView.builder(
              itemCount: presets.length,
              onReorder: (oldIndex, newIndex) {
                context.read<PresetProvider>().move(oldIndex, newIndex);
              },
              buildDefaultDragHandles: true,
              proxyDecorator: (child, index, animation) {
                return _ScaleAnimation(
                  animation: animation,
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
      LogService.error('粘贴失败: ${preset.title}', e);
    });
    LogService.info('粘贴预置文本: ${preset.title}');
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
    final titleCtrl = TextEditingController(text: preset?.title ?? '');
    final contentCtrl = TextEditingController(text: preset?.content ?? '');
    final isEdit = preset != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? '编辑预置文本' : '添加预置文本'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: '标题',
                hintText: '输入标题',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentCtrl,
              decoration: const InputDecoration(
                labelText: '内容',
                hintText: '输入要粘贴的文本内容',
              ),
              maxLines: 5,
              minLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleCtrl.text.trim();
              final content = contentCtrl.text;
              if (title.isEmpty) return;
              if (isEdit) {
                context
                    .read<PresetProvider>()
                    .update(preset!.id, title, content);
              } else {
                context.read<PresetProvider>().add(title, content);
              }
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

class _ScaleAnimation extends AnimatedWidget {
  final Widget? child;

  const _ScaleAnimation({
    required super.listenable,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    final scale = 0.95 + (animation.value * 0.05);
    return Transform.scale(
      scale: scale,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: child,
      ),
    );
  }
}
