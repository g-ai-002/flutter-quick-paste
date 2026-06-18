import 'dart:io';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'log_service.dart';

/// 粘贴服务：将文本复制到剪贴板，隐藏窗口后模拟 Ctrl+V
class PasteService {
  PasteService._();
  static final PasteService instance = PasteService._();

  /// 粘贴文本：复制到剪贴板 → 隐藏窗口 → 模拟 Ctrl+V
  Future<void> paste(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      LogService.info('文本已复制到剪贴板: ${text.length} 字符');

      if (Platform.isWindows) {
        await windowManager.hide();
        await Future.delayed(const Duration(milliseconds: 150));

        // 使用 PowerShell SendKeys 模拟 Ctrl+V
        await Process.run('powershell', [
          '-NoProfile',
          '-Command',
          r'Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.SendKeys]::SendWait("^v")',
        ]);
      }

      LogService.info('粘贴操作完成');
    } catch (e, st) {
      LogService.error('粘贴失败', e, st);
      rethrow;
    }
  }
}
