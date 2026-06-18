import 'package:flutter/material.dart';
import '../models/preset_text.dart';

/// 预置文本编辑/添加对话框
class EditPresetDialog extends StatefulWidget {
  final PresetText? preset;

  const EditPresetDialog({super.key, this.preset});

  bool get isEdit => preset != null;

  @override
  State<EditPresetDialog> createState() => _EditPresetDialogState();
}

class _EditPresetDialogState extends State<EditPresetDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.preset?.title ?? '');
    _contentCtrl = TextEditingController(text: widget.preset?.content ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEdit ? '编辑预置文本' : '添加预置文本'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: '标题',
              hintText: '输入标题',
            ),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentCtrl,
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
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final title = _titleCtrl.text.trim();
            if (title.isEmpty) return;
            Navigator.pop(context, {
              'title': title,
              'content': _contentCtrl.text,
            });
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
