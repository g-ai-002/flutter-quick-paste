import 'dart:io';
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

        // 模拟 Ctrl+V 使用 SendInput
        final inputs = [
          _keybdInput(VIRTUAL_KEY.VK_CONTROL, false),
          _keybdInput(0x56, false),
          _keybdInput(0x56, true),
          _keybdInput(VIRTUAL_KEY.VK_CONTROL, true),
        ];
        SendInput(inputs.length, inputs, sizeOf<INPUT>());
      }

      LogService.info('粘贴操作完成');
    } catch (e, st) {
      LogService.error('粘贴失败', e, st);
      rethrow;
    }
  }

  INPUT _keybdInput(int vk, bool keyUp) {
    final input = calloc<INPUT>();
    input.ref.type = INPUT_KEYBOARD;
    input.ref.ki.wVk = vk;
    input.ref.ki.dwFlags = keyUp ? KEYBD_EVENT_FLAGS.KEYEVENTF_KEYUP : 0;
    return input.ref;
  }
}
