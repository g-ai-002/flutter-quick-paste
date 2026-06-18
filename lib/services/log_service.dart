import 'dart:io';
import 'file_system_service.dart';

class LogService {
  LogService._();
  static final LogService instance = LogService._();

  File? _logFile;
  bool _initialized = false;
  final List<String> _buffer = [];
  static const int _maxBufferLines = 1000;

  Future<void> init() async {
    if (_initialized) return;
    final dir = await FileSystemService.instance.getLogRoot();
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final file = File('${dir.path}${Platform.pathSeparator}quick_paste_$dateStr.log');
    if (!await file.exists()) await file.create();
    _logFile = file;
    _initialized = true;
    _write('INFO', '==== LogService 已初始化, 日志文件: ${file.path} ====');
  }

  void info(String message) => _write('INFO', message);

  void warning(String message) => _write('WARN', message);

  void error(String message, [Object? error, StackTrace? stack]) {
    final msg = error != null ? '$message | $error' : message;
    _write('ERROR', msg);
    if (stack != null) _write('ERROR', stack.toString());
  }

  void _write(String level, String message) {
    final now = DateTime.now();
    final ts =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}';
    final line = '[$ts][$level] $message';
    _buffer.add(line);
    if (_buffer.length > _maxBufferLines) _buffer.removeAt(0);
    try {
      _logFile?.writeAsStringSync('$line\n', mode: FileMode.append);
    } catch (_) {}
  }

  String get logFilePath => _logFile?.path ?? '';

  List<String> getRecentLogs([int n = 200]) {
    if (_buffer.length <= n) return List.from(_buffer);
    return _buffer.sublist(_buffer.length - n);
  }
}
