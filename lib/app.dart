import 'package:material_ui/material_ui.dart';

import 'game/game_controller.dart';
import 'game/game_settings.dart';
import 'storage/game_storage.dart';
import 'ui/screens/game_screen.dart';
import 'ui/screens/splash_screen.dart';

class Jeu2048App extends StatefulWidget {
  const Jeu2048App({super.key, this.storage, this.splashDuration = const Duration(milliseconds: 1600)});

  final GameStorage? storage;

  /// Durée de l'écran d'accueil ; zéro pour l'ignorer (tests).
  final Duration splashDuration;

  @override
  State<Jeu2048App> createState() => _Jeu2048AppState();
}

class _Jeu2048AppState extends State<Jeu2048App> {
  late final GameController _controller = GameController(
    settings: widget.storage?.loadSettings() ?? const GameSettings(),
    storage: widget.storage,
  );
  late bool _splash = widget.splashDuration > Duration.zero;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static ThemeData _theme(Brightness brightness) {
    final light = brightness == Brightness.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFE07A2E),
      brightness: brightness,
      surface: light ? const Color(0xFFFAF6EF) : const Color(0xFF1D1A17),
    );
    return ThemeData(
      colorScheme: scheme,
      fontFamily: 'Rubik',
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        titleTextStyle: TextStyle(
          fontFamily: 'Rubik',
          fontSize: 26,
          fontWeight: FontWeight.w700,
          fontVariations: const [FontVariation('wght', 700)],
          color: scheme.onSurface,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jeu 2048',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _splash
            ? SplashScreen(duration: widget.splashDuration, onDone: () => setState(() => _splash = false))
            : GameScreen(controller: _controller),
      ),
    );
  }
}
