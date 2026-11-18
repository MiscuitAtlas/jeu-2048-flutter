import 'dart:math';

import 'direction.dart';
import 'line_merger.dart';
import 'merge_mode.dart';

/// Résultat d'un mouvement sur la grille.
class MoveResult {
  const MoveResult({required this.board, required this.moved, required this.scoreGained, required this.mergedCells});

  final Board board;

  /// Faux si aucune tuile n'a bougé : le coup ne compte pas.
  final bool moved;
  final int scoreGained;

  /// Indices des cases qui contiennent une tuile issue d'une fusion.
  final Set<int> mergedCells;
}

/// Grille carrée de [size] × [size] cases, stockée ligne par ligne.
///
/// Pour une grille 4 × 4, la case d'indice 6 est à la ligne 1, colonne 2.
/// La valeur 0 représente une case vide. La grille est immuable : un mouvement
/// renvoie une nouvelle grille.
class Board {
  Board(this.size, List<int> cells) : cells = List.unmodifiable(cells) {
    if (size < 2) throw ArgumentError.value(size, 'size', 'La grille doit faire au moins 2 × 2');
    if (cells.length != size * size) {
      throw ArgumentError('Une grille $size × $size contient ${size * size} cases, pas ${cells.length}');
    }
  }

  Board.empty(int size) : this(size, List.filled(size * size, 0));

  /// Construit une grille à partir de ses lignes, pratique pour les tests.
  factory Board.fromRows(List<List<int>> rows) => Board(rows.length, [for (final row in rows) ...row]);

  final int size;
  final List<int> cells;

  int at(int row, int column) => cells[row * size + column];

  List<List<int>> get rows => [for (var r = 0; r < size; r++) cells.sublist(r * size, (r + 1) * size)];

  int get maxTile => cells.reduce(max);

  List<int> get emptyCells => [
    for (var i = 0; i < cells.length; i++)
      if (cells[i] == 0) i,
  ];

  /// Vrai s'il reste au moins un mouvement qui change la grille.
  bool get canMove {
    for (var i = 0; i < cells.length; i++) {
      final value = cells[i];
      if (value == 0) return true;
      final column = i % size;
      if (column < size - 1 && cells[i + 1] == value) return true;
      if (i + size < cells.length && cells[i + size] == value) return true;
    }
    return false;
  }

  Board withTile(int index, int value) {
    final copy = List<int>.of(cells);
    copy[index] = value;
    return Board(size, copy);
  }

  /// Indices des cases d'une ligne, dans le sens du mouvement.
  List<int> _lineIndexes(Direction direction, int line) {
    final indexes = switch (direction) {
      Direction.left || Direction.right => [for (var c = 0; c < size; c++) line * size + c],
      Direction.up || Direction.down => [for (var r = 0; r < size; r++) r * size + line],
    };
    return direction == Direction.right || direction == Direction.down ? indexes.reversed.toList() : indexes;
  }

  MoveResult move(Direction direction, MergeMode mode) {
    final next = List<int>.of(cells);
    final merged = <int>{};
    var score = 0;

    for (var line = 0; line < size; line++) {
      final indexes = _lineIndexes(direction, line);
      final result = mergeLine([for (final i in indexes) cells[i]], mode);
      for (var k = 0; k < size; k++) {
        next[indexes[k]] = result.values[k];
      }
      merged.addAll(result.mergedIndexes.map((k) => indexes[k]));
      score += result.scoreGained;
    }

    var moved = false;
    for (var i = 0; i < cells.length && !moved; i++) {
      moved = cells[i] != next[i];
    }
    return MoveResult(board: Board(size, next), moved: moved, scoreGained: score, mergedCells: merged);
  }

  /// Ajoute une tuile au hasard dans une case vide : un 2 neuf fois sur dix,
  /// sinon un 4, comme dans le jeu original. Renvoie null si la grille est pleine.
  ({Board board, int index})? spawnTile(Random random) {
    final empty = emptyCells;
    if (empty.isEmpty) return null;
    final index = empty[random.nextInt(empty.length)];
    return (board: withTile(index, random.nextInt(10) == 0 ? 4 : 2), index: index);
  }

  /// Grille de départ aléatoire, comme le propose l'énoncé : entre 40 et 60 %
  /// des cases remplies, avec des valeurs inférieures au quart de l'objectif.
  /// Il reste toujours des cases vides, et donc des mouvements possibles.
  static Board random(int size, int goal, Random random) {
    final total = size * size;
    final count = (total * (0.4 + random.nextDouble() * 0.2)).round().clamp(2, total - 2);
    final maxExponent = max(2, (log(goal) / ln2).round() - 2);
    final positions = List<int>.generate(total, (i) => i)..shuffle(random);
    final cells = List<int>.filled(total, 0);
    for (final index in positions.take(count)) {
      cells[index] = 1 << (1 + random.nextInt(maxExponent));
    }
    return Board(size, cells);
  }

  @override
  bool operator ==(Object other) => other is Board && other.size == size && _sameCells(other.cells, cells);

  @override
  int get hashCode => Object.hash(size, Object.hashAll(cells));

  @override
  String toString() => rows.map((row) => row.join(' ')).join('\n');
}

bool _sameCells(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
