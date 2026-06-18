import 'dart:io';

/// 文件系统服务：提供日志目录
class FileSystemService {
  FileSystemService._();
  static final FileSystemService instance = FileSystemService._();

  Directory? _logDir;

  Future<Directory> getLogRoot() async {
    if (_logDir != null) return _logDir!;
    final home = Platform.isWindows
        ? Platform.environment['USERPROFILE'] ?? '.'
        : Platform.environment['HOME'] ?? '.';
    _logDir = Directory('$home${Platform.pathSeparator}logs');
    if (!await _logDir!.exists()) await _logDir!.create(recursive: true);
    return _logDir!;
  }
}
