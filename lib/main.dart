import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'core/theme/app_theme.dart';
import 'core/tv/tv_display_service.dart';
import 'features/shell/app_shell.dart';

void main() async {
  // Runs before the first frame, so the screens are never shown mid-release.
  WidgetsFlutterBinding.ensureInitialized();
  // Opens the window channel the app uses for F11 full-screen toggling
  // (the shortcut itself lives in AppShell).
  await windowManager.ensureInitialized();
  runApp(const ProviderScope(child: PlayZoneApp()));
}

class PlayZoneApp extends StatefulWidget {
  const PlayZoneApp({super.key});

  @override
  State<PlayZoneApp> createState() => _PlayZoneAppState();
}

class _PlayZoneAppState extends State<PlayZoneApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Hands the walls back to the console on the way out.
  ///
  /// The wall screens are showing a picture fetched from this program. When
  /// the program stops, that address stops answering, and a screen left
  /// waiting on it does not come back on its own — it sits part-way through
  /// the change and then ignores everything it is sent for the rest of the
  /// evening. Releasing here is the difference between a screen that works
  /// tomorrow and one that needs someone to walk over and switch it off.
  ///
  /// Fire and forget: this runs while the window is closing, and there is
  /// nobody left to read a result, so waiting would only make closing feel
  /// broken.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      TvDisplayService.instance.releaseAllScreens();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlayZone',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      // Arabic RTL by default — flip to LTR when English is selected
      // (see spec section 38, to be wired to a locale provider later).
      locale: const Locale('ar'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar'), Locale('en')],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const AppShell(),
    );
  }
}
