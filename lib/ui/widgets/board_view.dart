import 'package:material_ui/material_ui.dart';

import '../../game/board.dart';
import '../../game/direction.dart';
import '../palettes.dart';
import 'board_painter.dart';

/// Grille de jeu : dessin, animation après chaque coup et détection des glissements.
class BoardView extends StatefulWidget {
  const BoardView({
    super.key,
    required this.board,
    required this.palette,
    required this.turn,
    required this.onSwipe,
    this.spawnedCell,
    this.mergedCells = const {},
    this.overlay,
  });

  final Board board;
  final TilePalette palette;

  /// Change à chaque coup : relance l'animation.
  final int turn;
  final ValueChanged<Direction> onSwipe;
  final int? spawnedCell;
  final Set<int> mergedCells;

  /// Message affiché par-dessus la grille (victoire, fin de partie).
  final Widget? overlay;

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView> with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: 1,
  );
  Offset _drag = Offset.zero;

  @override
  void didUpdateWidget(BoardView old) {
    super.didUpdateWidget(old);
    if (old.turn != widget.turn) {
      if (MediaQuery.of(context).disableAnimations) {
        _animation.value = 1;
      } else {
        _animation.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  void _onPanEnd(DragEndDetails details) {
    // Le glissement compte s'il est assez long, ou assez rapide pour un geste bref.
    final velocity = details.velocity.pixelsPerSecond;
    final delta = _drag.distance >= 24 ? _drag : (velocity.distance >= 300 ? velocity : Offset.zero);
    _drag = Offset.zero;
    if (delta == Offset.zero) return;
    if (delta.dx.abs() > delta.dy.abs()) {
      widget.onSwipe(delta.dx > 0 ? Direction.right : Direction.left);
    } else {
      widget.onSwipe(delta.dy > 0 ? Direction.down : Direction.up);
    }
  }

  String _describe() {
    final rows = widget.board.rows;
    final lines = [
      for (var r = 0; r < rows.length; r++) 'ligne ${r + 1} : ${rows[r].map((v) => v == 0 ? 'vide' : '$v').join(', ')}',
    ];
    return 'Grille ${widget.board.size} par ${widget.board.size}. ${lines.join('. ')}.';
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) => _drag = Offset.zero,
        onPanUpdate: (details) => _drag += details.delta,
        onPanEnd: _onPanEnd,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Semantics(
              label: _describe(),
              image: true,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, _) => CustomPaint(
                  painter: BoardPainter(
                    board: widget.board,
                    palette: widget.palette,
                    progress: _animation.value,
                    spawnedCell: widget.spawnedCell,
                    mergedCells: widget.mergedCells,
                  ),
                ),
              ),
            ),
            if (widget.overlay != null) widget.overlay!,
          ],
        ),
      ),
    );
  }
}
