import 'dart:math';

import 'package:flutter/foundation.dart' show setEquals;

import 'package:material_ui/material_ui.dart';

import '../../game/board.dart';
import '../palettes.dart';

/// Dessine la grille avec un CustomPainter, comme le demande l'énoncé du TP.
///
/// [progress] va de 0 à 1 après chaque coup : la nouvelle tuile apparaît en grossissant
/// et les tuiles fusionnées « rebondissent ».
class BoardPainter extends CustomPainter {
  BoardPainter({
    required this.board,
    required this.palette,
    required this.progress,
    this.spawnedCell,
    this.mergedCells = const {},
  });

  final Board board;
  final TilePalette palette;
  final double progress;
  final int? spawnedCell;
  final Set<int> mergedCells;

  /// Écart entre deux cases, proportionnel à la taille de la grille.
  static double gapFor(int size, double side) =>
      side *
      switch (size) {
        <= 4 => 0.03,
        <= 6 => 0.022,
        _ => 0.016,
      };

  @override
  void paint(Canvas canvas, Size size) {
    final n = board.size;
    final side = size.shortestSide;
    final gap = gapFor(n, side);
    final cell = (side - gap * (n + 1)) / n;
    final radius = Radius.circular(cell * 0.12);

    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & Size.square(side), Radius.circular(gap * 2)),
      Paint()..color = palette.board,
    );

    final emptyPaint = Paint()..color = palette.emptyCell;
    for (var i = 0; i < board.cells.length; i++) {
      canvas.drawRRect(RRect.fromRectAndRadius(_cellRect(i, cell, gap), radius), emptyPaint);
    }

    for (var i = 0; i < board.cells.length; i++) {
      final value = board.cells[i];
      if (value == 0) continue;
      final scale = _scaleFor(i);
      if (scale <= 0) continue;

      final base = _cellRect(i, cell, gap);
      final rect = Rect.fromCenter(center: base.center, width: base.width * scale, height: base.height * scale);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, radius * scale), Paint()..color = palette.tileColor(value));
      _paintValue(canvas, value, rect, cell * scale);
    }
  }

  Rect _cellRect(int index, double cell, double gap) {
    final row = index ~/ board.size;
    final column = index % board.size;
    return Rect.fromLTWH(gap + column * (cell + gap), gap + row * (cell + gap), cell, cell);
  }

  double _scaleFor(int index) {
    if (index == spawnedCell) {
      // Apparition après le glissement : de 0 à 1, avec un léger dépassement.
      final t = ((progress - 0.35) / 0.65).clamp(0.0, 1.0);
      return Curves.easeOutBack.transform(t);
    }
    if (mergedCells.contains(index)) {
      final t = (progress / 0.7).clamp(0.0, 1.0);
      return 1 + 0.12 * sin(pi * t);
    }
    return 1;
  }

  void _paintValue(Canvas canvas, int value, Rect rect, double cell) {
    final text = value.toString();
    final factor = switch (text.length) {
      1 || 2 => 0.46,
      3 => 0.38,
      4 => 0.3,
      _ => 0.24,
    };
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Rubik',
          fontSize: cell * factor,
          fontWeight: FontWeight.w700,
          fontVariations: const [FontVariation('wght', 700)],
          color: palette.textColor(value),
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, rect.center - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(BoardPainter old) =>
      old.board != board ||
      old.palette != palette ||
      old.progress != progress ||
      old.spawnedCell != spawnedCell ||
      !setEquals(old.mergedCells, mergedCells);
}
