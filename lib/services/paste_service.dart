import 'dart:ffi' show sizeOf;
import 'dart:io';
import 'package:ffi/ffi.dart' show malloc;
import 'package:flutter/services.dart';
import 'package:win32/win32.dart';
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

        _sendKey(VIRTUAL_KEY.VK_CONTROL, false);
        _sendKey(0x56, false);
        _sendKey(0x56, true);
        _sendKey(VIRTUAL_KEY.VK_CONTROL, true);
      }

      LogService.info('粘贴操作完成');
    } catch (e, st) {
      LogService.error('粘贴失败', e, st);
      rethrow;
    }
  }

  void _sendKey(int vk, bool keyUp) {
    final input = malloc<INPUT>(sizeOf<INPUT>());
    input.ref.type = INPUT_TYPE.INPUT_KEYBOARD;
    input.ref.ki.wVk = vk;
    input.ref.ki.dwFlags = keyUp ? KEYBD_EVENT_FLAGS.KEYEVENTF_KEYUP : 0;
    SendInput(1, input, sizeOf<INPUT>());
    malloc.free(input);
  }
}
