import 'dart:ffi' show sizeOf;
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
        final inputs = calloc.allocate<INPUT>(4);
        final i0 = inputs.ref;
        i0.type = INPUT_TYPE.INPUT_KEYBOARD;
        i0.ki.wVk = VIRTUAL_KEY.VK_CONTROL;
        i0.ki.dwFlags = 0;

        final i1 = (inputs + 1).ref;
        i1.type = INPUT_TYPE.INPUT_KEYBOARD;
        i1.ki.wVk = 0x56;
        i1.ki.dwFlags = 0;

        final i2 = (inputs + 2).ref;
        i2.type = INPUT_TYPE.INPUT_KEYBOARD;
        i2.ki.wVk = 0x56;
        i2.ki.dwFlags = KEYBD_EVENT_FLAGS.KEYEVENTF_KEYUP;

        final i3 = (inputs + 3).ref;
        i3.type = INPUT_TYPE.INPUT_KEYBOARD;
        i3.ki.wVk = VIRTUAL_KEY.VK_CONTROL;
        i3.ki.dwFlags = KEYBD_EVENT_FLAGS.KEYEVENTF_KEYUP;

        SendInput(4, inputs, sizeOf<INPUT>());
        calloc.free(inputs);
      }

      LogService.info('粘贴操作完成');
    } catch (e, st) {
      LogService.error('粘贴失败', e, st);
      rethrow;
    }
  }
}
