import 'dart:io';

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
  // 尽早初始化日志，确保所有错误可记录
  WidgetsFlutterBinding.ensureInitialized();
  await LogService.instance.init();
  LogService.instance
      .info('==== 应用启动: ${AppConstants.appName} v${AppConstants.version} ====');

  // 先初始化存储服务（后续窗口 / 托盘 / 热键都需要）
  final storage = await StorageService.instance;

  if (Platform.isWindows) {
    // 创建并显示原生窗口（此时尚未渲染 Flutter 内容）
    await _initWindowFrame();
  }

  LogService.instance.info('启动 Flutter 框架');
  runApp(QuickPasteApp(storage: storage));

  if (Platform.isWindows) {
    // 首帧渲染完成后，再初始化托盘和热键，
    // 避免原生 API 在引擎未就绪时触发异常导致进程崩溃
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initTrayAndHotkey();
    });
  }
}

/// 创建原生 Win32 窗口框架，此时窗口显示但内容为空
Future<void> _initWindowFrame() async {
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
      LogService.instance.info('窗口框架已创建');
    });

    // 窗口关闭 → 隐藏到托盘（不退出）
    await windowManager.setPreventClose(true);
    windowManager.addListener(_WindowCloseHandler());
    LogService.instance.info('窗口关闭事件拦截已注册');
  } catch (e, st) {
    LogService.instance.error('窗口框架初始化失败', e, st);
  }
}

/// 在首帧渲染后初始化托盘和热键
Future<void> _initTrayAndHotkey() async {
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

/// 初始化系统托盘：加载 asset 图标、构建右键菜单、注册左键事件
Future<SystemTray> _initSystemTray() async {
  final systemTray = SystemTray();

  // 使用构建时打包的 asset 图标（ICO 格式），
  // Utils.getIcon 将其解析为 <exe>/data/flutter_assets/assets/tray_icon.ico
  await systemTray.initSystemTray(
    iconPath: 'assets/tray_icon.ico',
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