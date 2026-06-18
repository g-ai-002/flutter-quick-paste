import 'dart:io';
import 'package:ffi/ffi.dart';
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
        final inputs = calloc<INPUT>(4);
        _fillKeybdInput(inputs[0], VIRTUAL_KEY.VK_CONTROL, false);
        _fillKeybdInput(inputs[1], 0x56, false);
        _fillKeybdInput(inputs[2], 0x56, true);
        _fillKeybdInput(inputs[3], VIRTUAL_KEY.VK_CONTROL, true);
        SendInput(4, inputs, sizeOf<INPUT>());
        calloc.free(inputs);
      }

      LogService.info('粘贴操作完成');
    } catch (e, st) {
      LogService.error('粘贴失败', e, st);
      rethrow;
    }
  }

  void _fillKeybdInput(INPUT input, int vk, bool keyUp) {
    input.type = INPUT_TYPE.INPUT_KEYBOARD;
    input.ki.wVk = vk;
    input.ki.dwFlags = keyUp ? KEYBD_EVENT_FLAGS.KEYEVENTF_KEYUP : 0;
  }
}
