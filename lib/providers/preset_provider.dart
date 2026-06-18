import 'package:flutter/foundation.dart';
import '../models/preset_text.dart';
import '../services/storage_service.dart';
import '../services/log_service.dart';

/// 预置文本状态管理
class PresetProvider extends ChangeNotifier {
  final StorageService _storage;
  List<PresetText> _presets = [];
  String _searchQuery = '';

  PresetProvider(this._storage) {
    _presets = _storage.loadPresets();
  }

  List<PresetText> get presets => List.unmodifiable(_presets);

  String get searchQuery => _searchQuery;

  List<PresetText> get filteredPresets {
    if (_searchQuery.isEmpty) return _presets;
    final q = _searchQuery.toLowerCase();
    return _presets.where((p) {
      return p.title.toLowerCase().contains(q) ||
          p.content.toLowerCase().contains(q);
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void add(String title, String content) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final preset = PresetText(id: id, title: title, content: content);
    _presets.add(preset);
    _save();
    LogService.instance.info('添加预置文本: $title');
  }

  void update(String id, String title, String content) {
    final idx = _presets.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    _presets[idx] = _presets[idx].copyWith(title: title, content: content);
    _save();
    LogService.instance.info('更新预置文本: $title');
  }

  void remove(String id) {
    final preset = _presets.firstWhere((p) => p.id == id);
    _presets.removeWhere((p) => p.id == id);
    _save();
    LogService.instance.info('删除预置文本: ${preset.title}');
  }

  void move(int oldIndex, int newIndex) {
    // onReorderItem 已自动调整 newIndex，无需手动减一
    final item = _presets.removeAt(oldIndex);
    _presets.insert(newIndex, item);
    _save();
  }

  Future<void> _save() async {
    await _storage.savePresets(_presets);
    notifyListeners();
  }
}
