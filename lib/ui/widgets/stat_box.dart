import 'package:material_ui/material_ui.dart';

/// Une valeur de la partie (score, record, coups) avec son libellé.
class StatBox extends StatelessWidget {
  const StatBox({super.key, required this.label, required this.value, this.highlight = false});

  final String label;
  final String value;

  /// Mis en avant, par exemple quand le score bat le record.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: '$label : $value',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: highlight ? scheme.primaryContainer : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
            Text(
              value,
              style: text.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: highlight ? scheme.onPrimaryContainer : scheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
            ),
          ],
        ),
      ),
    );
  }
}
