import 'dart:io';

/// 文件系统服务：提供日志目录
class FileSystemService {
  FileSystemService._();
  static final FileSystemService instance = FileSystemService._();

  Directory? _logDir;

  Future<Directory> getLogRoot() async {
    if (_logDir != null) return _logDir!;
    final base = Platform.isWindows
        ? '${Platform.environment['LOCALAPPDATA'] ?? '.${Platform.pathSeparator}AppData${Platform.pathSeparator}Local'}${Platform.pathSeparator}quick_paste'
        : '${Platform.environment['HOME'] ?? '.'}${Platform.pathSeparator}Library${Platform.pathSeparator}Logs${Platform.pathSeparator}quick_paste';
    _logDir = Directory('$base${Platform.pathSeparator}logs');
    if (!await _logDir!.exists()) await _logDir!.create(recursive: true);
    return _logDir!;
  }
}
