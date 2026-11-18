import 'package:material_ui/material_ui.dart';

import '../palettes.dart';

/// Écran d'accueil : le titre se compose tuile par tuile, puis le jeu s'ouvre.
/// Un appui permet de passer directement au jeu.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone, this.duration = const Duration(milliseconds: 1600)});

  final VoidCallback onDone;
  final Duration duration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: widget.duration);
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) _finish();
    });
    _controller.forward();
  }

  void _finish() {
    if (_done) return;
    _done = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = palettes.first;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final scheme = Theme.of(context).colorScheme;
    const values = [2, 0, 4, 8];

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _finish,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                label: '2048',
                excludeSemantics: true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < values.length; i++)
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          final start = i * 0.12;
                          final t = reduceMotion ? 1.0 : ((_controller.value - start) / 0.3).clamp(0.0, 1.0);
                          return Transform.scale(scale: Curves.easeOutBack.transform(t), child: child);
                        },
                        child: _LogoTile(
                          digit: values[i],
                          color: palette.tileColor(1 << (i * 2 + 2)),
                          palette: palette,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Jeu 2048',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Faites glisser, fusionnez, atteignez l\'objectif.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoTile extends StatelessWidget {
  const _LogoTile({required this.digit, required this.color, required this.palette});

  final int digit;
  final Color color;
  final TilePalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      margin: const EdgeInsets.all(4),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Text(
        '$digit',
        style: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          fontVariations: const [FontVariation('wght', 700)],
          color: color.computeLuminance() > 0.4 ? palette.darkText : palette.lightText,
        ),
      ),
    );
  }
}
