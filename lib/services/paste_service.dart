import 'dart:io';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'log_service.dart';

/// 粘贴服务：将文本复制到剪贴板，隐藏窗口后模拟 Ctrl+V
class PasteService {
  PasteService._();
  static final PasteService instance = PasteService._();

  static const _pasteTimeout = Duration(seconds: 3);

  /// 粘贴文本：复制到剪贴板 → 隐藏窗口 → 模拟 Ctrl+V
  Future<void> paste(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      LogService.instance.info('文本已复制到剪贴板: ${text.length} 字符');

      if (Platform.isWindows) {
        await windowManager.hide();
        await Future.delayed(const Duration(milliseconds: 150));

        final result = await Process.run(
          'powershell',
          [
            '-NoProfile',
            '-Command',
            r'Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.SendKeys]::SendWait("^v")',
          ],
        ).timeout(_pasteTimeout);

        if (result.exitCode != 0) {
          final stderr = (result.stderr as String).trim();
          if (stderr.isNotEmpty) {
            LogService.instance.warning('PowerShell 粘贴警告: $stderr');
          }
        }
      }

      LogService.instance.info('粘贴操作完成');
    } on TimeoutException {
      LogService.instance.error('粘贴超时');
    } catch (e, st) {
      LogService.instance.error('粘贴失败', e, st);
      rethrow;
    }
  }
}
