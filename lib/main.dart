import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:provider/provider.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

import 'pages/home_page.dart';
import 'pages/settings_page.dart';
import 'providers/preset_provider.dart';
import 'providers/settings_provider.dart';
import 'services/log_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';

Future<void> main() async {
  // 尽早初始化日志，确保所有启动阶段的错误可记录
  WidgetsFlutterBinding.ensureInitialized();
  await LogService.instance.init();
  LogService.instance
      .info('==== 应用启动: ${AppConstants.appName} v${AppConstants.version} ====');

  if (Platform.isWindows) {
    await _initWindows();
  }

  final storage = await StorageService.instance;
  LogService.instance.info('UI 初始化完成，启动 Flutter 框架');
  runApp(QuickPasteApp(storage: storage));
}

Future<void> _initWindows() async {
  // --- 窗口初始化 ---
  try {
    await windowManager.ensureInitialized();
    const opts = WindowOptions(
      size: Size(420, 560),
      minimumSize: Size(320, 400),
      center: true,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: AppConstants.appName,
    );
    await windowManager.waitUntilReadyToShow(opts, () async {
      // 首次启动默认显示窗口，不再立即隐藏
      LogService.instance.info('窗口已创建，首次启动默认显示');
    });
  } catch (e, st) {
    LogService.instance.error('窗口初始化失败', e, st);
  }

  // --- 窗口关闭 → 隐藏到托盘 ---
  try {
    await windowManager.setPreventClose(true);
    windowManager.addListener(_WindowCloseHandler());
    LogService.instance.info('窗口关闭事件拦截已注册');
  } catch (e, st) {
    LogService.instance.error('窗口关闭事件注册失败', e, st);
  }

  // --- 系统托盘 ---
  try {
    await _initSystemTray();
    LogService.instance.info('系统托盘已创建');
  } catch (e, st) {
    LogService.instance.error('系统托盘初始化失败（不影响核心功能）', e, st);
  }

  // --- 全局热键 ---
  try {
    final storage = await StorageService.instance;
    final modifiers = storage.hotkeyModifiers != 0
        ? storage.hotkeyModifiers
        : AppConstants.defaultHotkeyModifiers;
    final key = storage.hotkeyKey != 0
        ? storage.hotkeyKey
        : AppConstants.defaultHotkeyKey;

    await hotKeyManager.unregisterAll();
    await hotKeyManager.register(
      HotKey(
        key: AppConstants.keyFromHidUsage(key),
        modifiers: AppConstants.modifiersFromMask(modifiers),
        scope: HotKeyScope.system,
      ),
      keyDownHandler: (hotKey) {
        windowManager.isVisible().then((visible) {
          if (visible) {
            windowManager.hide();
          } else {
            windowManager.show();
            windowManager.focus();
          }
        });
      },
    );
    LogService.instance
        .info('全局热键已注册: ${AppConstants.formatHotkey(modifiers, key)}');
  } catch (e, st) {
    LogService.instance.error('全局热键注册失败（仍可通过托盘图标操作）', e, st);
  }
}

/// 窗口关闭事件处理器：拦截原生关闭 → 隐藏到托盘而非退出
class _WindowCloseHandler with WindowListener {
  @override
  void onWindowClose() async {
    await windowManager.hide();
    LogService.instance.info('窗口关闭按钮 → 隐藏到托盘');
  }
}

/// 初始化系统托盘：创建图标、构建右键菜单、注册左键事件
Future<SystemTray> _initSystemTray() async {
  final systemTray = SystemTray();

  // 在内存中绘制 32×32 绿色圆形图标，写入临时文件
  final iconPath = await _createTrayIconFile();

  await systemTray.initSystemTray(
    iconPath: iconPath,
    toolTip: AppConstants.appName,
  );

  // 右键菜单
  final menu = Menu();
  await menu.buildFrom([
    MenuItemLabel(
      label: '显示窗口',
      onClicked: (_) async {
        await windowManager.show();
        await windowManager.focus();
      },
    ),
    MenuSeparator(),
    MenuItemLabel(
      label: '退出',
      onClicked: (_) async {
        LogService.instance.info('用户通过托盘菜单退出应用');
        await systemTray.destroy();
        await windowManager.destroy();
        exit(0);
      },
    ),
  ]);
  await systemTray.setContextMenu(menu);

  // 左键单击托盘图标 → 显示/隐藏窗口
  systemTray.registerSystemTrayEventHandler((eventName) {
    if (eventName == kSystemTrayEventClick) {
      windowManager.isVisible().then((visible) {
        if (visible) {
          windowManager.hide();
        } else {
          windowManager.show();
          windowManager.focus();
        }
      });
    }
  });

  return systemTray;
}

/// 用 dart:ui 绘制 32×32 绿色圆形图标 → 导出 PNG → 包裹为 ICO → 写入临时文件
Future<String> _createTrayIconFile() async {
  const size = 32.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));

  // 绿色填充圆形
  canvas.drawCircle(
    Offset(size / 2, size / 2),
    size / 2 - 2,
    Paint()..color = const Color(0xFF4CAF50),
  );

  // 白色描边外圈
  canvas.drawCircle(
    Offset(size / 2, size / 2),
    size / 2 - 2,
    Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2,
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw Exception('生成托盘图标失败：toByteData 返回 null');
  }

  final pngBytes = byteData.buffer.asUint8List();
  // ICO 容器要求：Windows LoadImage(IMAGE_ICON) 只能加载 .ico 文件，
  // ICO 格式允许内部嵌入 PNG 数据块。
  final icoBytes = _pngToIco(pngBytes);

  final tmpDir = Directory.systemTemp.createTempSync('quick_paste_icon_');
  final iconFile =
      File('${tmpDir.path}${Platform.pathSeparator}tray_icon.ico');
  await iconFile.writeAsBytes(icoBytes);
  return iconFile.path;
}

/// 将 PNG 字节包裹为 ICO 格式，使 Windows LoadImage 能正常加载。
///
/// ICO 文件结构：
///   [6 字节头部] + [16 字节目录项] + [PNG 数据]
List<int> _pngToIco(List<int> pngBytes) {
  final bytes = <int>[];

  // --- ICO 头部 (6 bytes) ---
  bytes.addAll([0x00, 0x00]); // 保留
  bytes.addAll([0x01, 0x00]); // 类型: 1=ICO
  bytes.addAll([0x01, 0x00]); // 图像数量: 1

  // --- 目录项 (16 bytes) ---
  final imageSize = pngBytes.length;
  const imageOffset = 22; // 6 + 16

  bytes.addAll([
    0x20, // 宽度: 32
    0x20, // 高度: 32
    0x00, // 颜色数: 0 (>256)
    0x00, // 保留
    0x01, 0x00, // 颜色平面: 1
    0x20, 0x00, // 每像素位数: 32
    // 图像数据大小 (little-endian)
    imageSize & 0xFF,
    (imageSize >> 8) & 0xFF,
    (imageSize >> 16) & 0xFF,
    (imageSize >> 24) & 0xFF,
    // 图像数据偏移 (little-endian)
    imageOffset & 0xFF,
    (imageOffset >> 8) & 0xFF,
    (imageOffset >> 16) & 0xFF,
    (imageOffset >> 24) & 0xFF,
  ]);

  // --- PNG 数据 ---
  bytes.addAll(pngBytes);

  return bytes;
}

class QuickPasteApp extends StatelessWidget {
  final StorageService storage;
  const QuickPasteApp({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    final fontFamily = Platform.isWindows ? 'Microsoft YaHei UI' : null;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider(storage)),
        ChangeNotifierProvider(create: (_) => PresetProvider(storage)),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: buildLightTheme(fontFamily: fontFamily),
            darkTheme: buildDarkTheme(fontFamily: fontFamily),
            themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('zh', 'CN')],
            locale: const Locale('zh', 'CN'),
            initialRoute: '/',
            routes: {
              '/': (_) => const HomePage(),
              '/settings': (_) => const SettingsPage(),
            },
          );
        },
      ),
    );
  }
}