import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../game/direction.dart';
import '../../game/game_controller.dart';
import '../../game/game_settings.dart';
import '../../storage/game_storage.dart';
import '../format.dart';
import '../palettes.dart';
import '../widgets/board_view.dart';
import '../widgets/stat_box.dart';
import 'settings_screen.dart';

/// Écran principal : scores, grille et commandes.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.controller});

  final GameController controller;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final FocusNode _focus = FocusNode(debugLabel: 'grille');

  GameController get _game => widget.controller;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  static final _keys = <LogicalKeyboardKey, Direction>{
    LogicalKeyboardKey.arrowUp: Direction.up,
    LogicalKeyboardKey.arrowDown: Direction.down,
    LogicalKeyboardKey.arrowLeft: Direction.left,
    LogicalKeyboardKey.arrowRight: Direction.right,
    // ZQSD (AZERTY) et WASD (QWERTY).
    LogicalKeyboardKey.keyZ: Direction.up,
    LogicalKeyboardKey.keyW: Direction.up,
    LogicalKeyboardKey.keyS: Direction.down,
    LogicalKeyboardKey.keyQ: Direction.left,
    LogicalKeyboardKey.keyA: Direction.left,
    LogicalKeyboardKey.keyD: Direction.right,
  };

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    if (HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed) {
      return KeyEventResult.ignored;
    }
    final direction = _keys[event.logicalKey];
    if (direction != null) {
      _game.move(direction);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _game.undo();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _confirmNewGame() async {
    final inProgress = _game.moves > 0 && _game.status == GameStatus.playing;
    if (inProgress) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Recommencer ?'),
          content: Text(
            'La partie en cours (${formatMoves(_game.moves)}, ${formatNumber(_game.score)} points) sera perdue.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Continuer la partie')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Recommencer')),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    _game.newGame();
    _focus.requestFocus();
  }

  Future<void> _openSettings() async {
    final settings = await Navigator.of(context).push<GameSettings>(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(initial: _game.settings, gameInProgress: _game.moves > 0),
      ),
    );
    if (settings != null) _game.applySettings(settings);
    _focus.requestFocus();
  }

  void _showRules() {
    final mode = _game.settings.mode;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Règles du jeu'),
        content: SingleChildScrollView(
          child: Text(
            'Faites glisser les tuiles vers le haut, le bas, la gauche ou la droite. '
            'Deux tuiles de même valeur qui se rencontrent fusionnent et leur somme s\'ajoute au score. '
            'Après chaque coup, une tuile 2 ou 4 apparaît dans une case vide.\n\n'
            'Créez une tuile de ${formatNumber(_game.settings.goal)} pour gagner. Vous pourrez ensuite continuer '
            'la partie. Elle se termine quand la grille est pleine et qu\'aucune fusion n\'est possible.\n\n'
            'Mode ${mode.label.toLowerCase()} : ${mode.description}\n\n'
            'Au clavier : flèches, ZQSD ou WASD pour jouer, retour arrière pour annuler.\n\n'
            'Astuce : gardez votre plus grosse tuile dans un coin.',
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer'))],
      ),
    );
  }

  void _showRecords() {
    final records = _game.storage?.loadRecords() ?? const <String, GameRecord>{};
    final current = _game.settings.recordKey;
    final keys = records.keys.toList()..sort((a, b) => a == current ? -1 : (b == current ? 1 : a.compareTo(b)));
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Records'),
        content: SizedBox(
          width: 420,
          child: keys.isEmpty
              ? const Text('Aucun record pour l\'instant. Jouez une partie pour inscrire votre premier score.')
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final key in keys)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(describeRecordKey(key) + (key == current ? ' (partie actuelle)' : '')),
                        subtitle: Text(
                          'Meilleur score : ${formatNumber(records[key]!.bestScore)}\n'
                          '${records[key]!.fewestMoves == null ? 'Objectif pas encore atteint' : 'Objectif atteint en ${formatMoves(records[key]!.fewestMoves!)}'}',
                        ),
                      ),
                  ],
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer'))],
      ),
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Jeu 2048',
      applicationVersion: '2.0',
      applicationLegalese: 'Maxence Français\nProjet réalisé en licence professionnelle DLWM, puis retravaillé.',
      children: const [
        SizedBox(height: 16),
        Text('Le code source est publié sur GitHub : github.com/MiscuitAtlas/jeu-2048-flutter'),
      ],
    );
  }

  Widget? _overlay(TilePalette palette) {
    final status = _game.status;
    if (status == GameStatus.playing) return null;
    final won = status == GameStatus.won;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(color: scheme.surface.withValues(alpha: 0.86), borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              liveRegion: true,
              child: Text(
                won ? 'Objectif atteint !' : 'Plus aucun mouvement',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              won
                  ? 'Tuile ${formatNumber(_game.settings.goal)} créée en ${formatMoves(_game.moves)}.'
                  : 'Score final : ${formatNumber(_game.score)} points.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (won)
                  FilledButton(onPressed: _game.continueAfterWin, child: const Text('Continuer'))
                else if (_game.canUndo)
                  OutlinedButton(onPressed: _game.undo, child: const Text('Annuler le dernier coup')),
                if (won)
                  OutlinedButton(onPressed: _game.newGame, child: const Text('Nouvelle partie'))
                else
                  FilledButton(onPressed: _game.newGame, child: const Text('Nouvelle partie')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('2048'),
        actions: [
          IconButton(tooltip: 'Règles du jeu', icon: const Icon(Icons.help_outline), onPressed: _showRules),
          IconButton(tooltip: 'Records', icon: const Icon(Icons.emoji_events_outlined), onPressed: _showRecords),
          IconButton(tooltip: 'Réglages', icon: const Icon(Icons.tune), onPressed: _openSettings),
          IconButton(tooltip: 'À propos', icon: const Icon(Icons.info_outline), onPressed: _showAbout),
        ],
      ),
      body: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: ListenableBuilder(listenable: _game, builder: (context, _) => _buildBody(context)),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final settings = _game.settings;
    final palette = paletteById(settings.paletteId);
    final record = _game.record;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final scaler = MediaQuery.textScalerOf(context);
    final beatsRecord = _game.score > 0 && _game.score >= record.bestScore;

    final stats = Row(
      children: [
        Expanded(
          child: StatBox(label: 'Score', value: formatNumber(_game.score), highlight: beatsRecord),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatBox(label: 'Record', value: formatNumber(record.bestScore)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatBox(label: 'Coups', value: formatNumber(_game.moves)),
        ),
      ],
    );
    final tags = Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _Tag('Objectif ${formatNumber(settings.goal)}'),
        _Tag('${settings.size} × ${settings.size}'),
        _Tag('Mode ${settings.mode.label.toLowerCase()}'),
        if (settings.randomStart) const _Tag('Départ aléatoire'),
        if (settings.invertedControls) const _Tag('Commandes inversées'),
        if (_game.keepPlaying) const _Tag('Objectif atteint'),
      ],
    );
    final buttons = Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _game.canUndo ? _game.undo : null,
            icon: const Icon(Icons.undo),
            label: const Text('Annuler', maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: _confirmNewGame,
            icon: const Icon(Icons.refresh),
            label: const Text('Nouvelle partie', maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
    );
    final hint = Text(
      'Glissez sur la grille, ou jouez avec les flèches du clavier.',
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
    );
    final board = BoardView(
      board: _game.board,
      palette: palette,
      turn: _game.turn,
      spawnedCell: _game.spawnedCell,
      mergedCells: _game.mergedCells,
      onSwipe: _game.move,
      overlay: _overlay(palette),
    );

    // Pas de défilement : un glissement vertical sur la grille doit déplacer les tuiles, pas la page.
    return LayoutBuilder(
      builder: (context, constraints) {
        final landscape = constraints.maxWidth > constraints.maxHeight * 1.2 && constraints.maxHeight < 600;
        if (landscape) {
          // Téléphone à l'horizontale : la grille à droite, le reste à gauche.
          final side = constraints.maxHeight - 24;
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [stats, const SizedBox(height: 10), tags, const SizedBox(height: 16), buttons],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox.square(dimension: side, child: board),
              ],
            ),
          );
        }

        final showHint = constraints.maxHeight > 600 && scaler.scale(12) <= 14;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  stats,
                  const SizedBox(height: 10),
                  tags,
                  const SizedBox(height: 12),
                  // La grille et les boutons forment un bloc : la place libre reste en bas de l'écran.
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, box) {
                        final below =
                            14 +
                            (scaler.scale(20) + 28).clamp(48.0, double.infinity) +
                            (showHint ? 12 + scaler.scale(12) * 1.5 : 0) +
                            2;
                        final side = (box.maxWidth < box.maxHeight - below ? box.maxWidth : box.maxHeight - below)
                            .clamp(0.0, double.infinity);
                        return Column(
                          children: [
                            SizedBox.square(dimension: side, child: board),
                            const SizedBox(height: 14),
                            SizedBox(width: side < 260 ? box.maxWidth : side, child: buttons),
                            if (showHint) ...[const SizedBox(height: 12), hint],
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}
