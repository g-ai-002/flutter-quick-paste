import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// 文件系统服务：提供应用数据目录和日志目录
class FileSystemService {
  FileSystemService._();
  static final FileSystemService instance = FileSystemService._();

  Directory? _appDir;
  Directory? _logDir;

  Future<Directory> getAppDir() async {
    _appDir ??= await getApplicationSupportDirectory();
    if (!await _appDir!.exists()) await _appDir!.create(recursive: true);
    return _appDir!;
  }

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
