import 'merge_mode.dart';

/// Résultat de la fusion d'une ligne.
class LineResult {
  const LineResult(this.values, this.scoreGained, this.mergedIndexes);

  /// Valeurs de la ligne après le mouvement, tassées vers l'indice 0.
  final List<int> values;

  /// Somme des tuiles créées par fusion : c'est ce que le coup rapporte.
  final int scoreGained;

  /// Indices des cases qui contiennent une tuile issue d'une fusion.
  final Set<int> mergedIndexes;
}

/// Fait glisser une ligne vers l'indice 0 et fusionne les tuiles identiques.
///
/// La ligne est toujours lue dans le sens du mouvement : pour un glissement
/// vers la gauche, l'indice 0 est la case de gauche ; vers la droite, c'est
/// la case de droite. Les cases vides valent 0.
LineResult mergeLine(List<int> line, MergeMode mode) {
  final tiles = [
    for (final value in line)
      if (value != 0) value,
  ];
  final result = <int>[];
  final merged = <int>{};
  var score = 0;

  switch (mode) {
    case MergeMode.classic:
    case MergeMode.express:
      final factor = mode == MergeMode.express ? 4 : 2;
      var i = 0;
      while (i < tiles.length) {
        if (i + 1 < tiles.length && tiles[i] == tiles[i + 1]) {
          final value = tiles[i] * factor;
          merged.add(result.length);
          result.add(value);
          score += value;
          i += 2;
        } else {
          result.add(tiles[i]);
          i++;
        }
      }
    case MergeMode.cascade:
      // Pile : chaque tuile arrive contre la précédente ; tant que les deux
      // dernières sont égales, elles fusionnent, et le résultat peut fusionner
      // à nouveau avec celle d'avant.
      for (final tile in tiles) {
        result.add(tile);
        while (result.length >= 2 && result[result.length - 1] == result[result.length - 2]) {
          final value = result.removeLast() * 2;
          merged.remove(result.length);
          result[result.length - 1] = value;
          merged.add(result.length - 1);
          score += value;
        }
      }
  }

  while (result.length < line.length) {
    result.add(0);
  }
  return LineResult(List.unmodifiable(result), score, Set.unmodifiable(merged));
}
