import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:provider/provider.dart';
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
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows) {
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
      await windowManager.hide();
    });

    await hotKeyManager.unregisterAll();
    await hotKeyManager.register(
      HotKey(
        key: PhysicalKeyboardKey.keyV,
        modifiers: [KeyModifier.control, KeyModifier.shift],
        scope: HotKeyScope.system,
      ),
    );
    hotKeyManager.addHotKeyListener((hotKey) {
      windowManager.isVisible().then((visible) {
        if (visible) {
          windowManager.hide();
        } else {
          windowManager.show();
          windowManager.focus();
        }
      });
    });
  }

  final storage = await StorageService.instance;
  await LogService.instance.init();
  LogService.instance.info('应用启动: ${AppConstants.appName} v${AppConstants.version}');

  runApp(QuickPasteApp(storage: storage));
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
