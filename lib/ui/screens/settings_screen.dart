import 'package:material_ui/material_ui.dart';

import '../../game/game_settings.dart';
import '../../game/merge_mode.dart';
import '../format.dart';
import '../palettes.dart';

/// Réglages de la partie. Renvoie les nouveaux réglages, ou null si le joueur annule.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.initial, this.gameInProgress = false});

  final GameSettings initial;

  /// Une partie est commencée : prévenir si les changements la font recommencer.
  final bool gameInProgress;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late GameSettings _settings = widget.initial;

  bool get _restarts => _settings.recordKey != widget.initial.recordKey;

  void _update(GameSettings settings) => setState(() => _settings = settings);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              _Section(
                title: 'Objectif',
                subtitle: 'La tuile à créer pour gagner.',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final goal in GameSettings.goals)
                      ChoiceChip(
                        label: Text(formatNumber(goal)),
                        selected: _settings.goal == goal,
                        onSelected: (_) => _update(_settings.copyWith(goal: goal)),
                      ),
                  ],
                ),
              ),
              _Section(
                title: 'Taille de la grille',
                subtitle: 'Une grande grille laisse plus de place, mais les parties sont plus longues.',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final size in GameSettings.sizes)
                      ChoiceChip(
                        label: Text('$size × $size'),
                        selected: _settings.size == size,
                        onSelected: (_) => _update(_settings.copyWith(size: size)),
                      ),
                  ],
                ),
              ),
              _Section(
                title: 'Mode de fusion',
                child: RadioGroup<MergeMode>(
                  groupValue: _settings.mode,
                  onChanged: (mode) => _update(_settings.copyWith(mode: mode)),
                  child: Column(
                    children: [
                      for (final mode in MergeMode.values)
                        RadioListTile<MergeMode>(
                          value: mode,
                          title: Text(mode.label),
                          subtitle: Text(mode.description),
                          contentPadding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                ),
              ),
              _Section(
                title: 'Options',
                child: Column(
                  children: [
                    SwitchListTile(
                      value: _settings.randomStart,
                      onChanged: (value) => _update(_settings.copyWith(randomStart: value)),
                      title: const Text('Grille de départ aléatoire'),
                      subtitle: const Text('La partie commence avec une grille déjà à moitié remplie.'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    SwitchListTile(
                      value: _settings.invertedControls,
                      onChanged: (value) => _update(_settings.copyWith(invertedControls: value)),
                      title: const Text('Commandes inversées'),
                      subtitle: const Text('Les tuiles partent dans le sens opposé au geste.'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              _Section(
                title: 'Couleurs',
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final palette in palettes)
                      _PaletteOption(
                        palette: palette,
                        selected: _settings.paletteId == palette.id,
                        onTap: () => _update(_settings.copyWith(paletteId: palette.id)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_restarts && widget.gameInProgress)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Ces changements lancent une nouvelle partie.',
                    style: text.bodyMedium?.copyWith(color: scheme.error),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _settings == widget.initial ? null : () => Navigator.of(context).pop(_settings),
                      child: Text(_restarts ? 'Appliquer et rejouer' : 'Appliquer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle!,
                style: text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _PaletteOption extends StatelessWidget {
  const _PaletteOption({required this.palette, required this.selected, required this.onTap});

  final TilePalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Couleurs ${palette.name}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? scheme.primary : scheme.outlineVariant, width: selected ? 2.5 : 1),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: palette.board, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final value in [2, 8, 64, 512, 2048])
                      Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: palette.tileColor(value),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(palette.name, style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
            ],
          ),
        ),
      ),
    );
  }
}
