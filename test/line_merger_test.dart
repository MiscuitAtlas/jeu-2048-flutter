import 'package:flutter_test/flutter_test.dart';
import 'package:jeu_2048/game/line_merger.dart';
import 'package:jeu_2048/game/merge_mode.dart';

/// Les lignes sont lues dans le sens du mouvement : l'indice 0 est la case vers laquelle on glisse.
List<int> merge(List<int> line, [MergeMode mode = MergeMode.classic]) => mergeLine(line, mode).values;

void main() {
  group('Mode classique', () {
    test('tasse les tuiles sans fusion', () {
      expect(merge([0, 2, 0, 4]), [2, 4, 0, 0]);
      expect(merge([8, 4, 16, 2]), [8, 4, 16, 2]);
    });

    test('fusionne deux tuiles identiques, même séparées par du vide', () {
      expect(merge([2, 0, 0, 2]), [4, 0, 0, 0]);
    });

    test('une tuile ne fusionne qu\'une fois par coup', () {
      expect(merge([2, 2, 2, 2]), [4, 4, 0, 0]);
      expect(merge([4, 4, 8, 0]), [8, 8, 0, 0]);
    });

    test('avec trois tuiles identiques, les deux plus proches du bord fusionnent', () {
      expect(merge([4, 4, 4, 0]), [8, 4, 0, 0]);
    });

    test('compte le score et les cases fusionnées', () {
      final result = mergeLine([2, 2, 4, 4], MergeMode.classic);
      expect(result.values, [4, 8, 0, 0]);
      expect(result.scoreGained, 12);
      expect(result.mergedIndexes, {0, 1});
    });
  });

  group('Mode cascade : exemples de l\'énoncé du TP', () {
    // Colonnes lues de haut en bas, pour un glissement vers le haut.
    test('trois valeurs qui se suivent : seules les deux premières fusionnent', () {
      expect(merge([4, 4, 4, 0], MergeMode.cascade), [8, 4, 0, 0]);
      expect(merge([2, 2, 2, 0], MergeMode.cascade), [4, 2, 0, 0]);
    });

    test('fusion puis tassement', () {
      expect(merge([8, 0, 2, 2], MergeMode.cascade), [8, 4, 0, 0]);
    });

    test('une somme qui atteint la valeur voisine fusionne à son tour', () {
      expect(merge([8, 0, 4, 4], MergeMode.cascade), [16, 0, 0, 0]);
      expect(merge([8, 4, 4, 0], MergeMode.cascade), [16, 0, 0, 0]);
      expect(merge([8, 4, 2, 2], MergeMode.cascade), [16, 0, 0, 0]);
    });

    test('aucune somme possible : rien ne bouge', () {
      expect(merge([8, 4, 16, 2], MergeMode.cascade), [8, 4, 16, 2]);
    });

    test('glissements vers la droite (lignes lues de droite à gauche)', () {
      // 2 2 4 8 → 0 0 0 16 et 0 4 4 8 → 0 0 0 16
      expect(merge([8, 4, 2, 2], MergeMode.cascade), [16, 0, 0, 0]);
      expect(merge([8, 4, 4, 0], MergeMode.cascade), [16, 0, 0, 0]);
    });

    test('glissements vers la gauche', () {
      // 0 4 4 8 → 16 0 0 0 et 8 4 2 2 → 16 0 0 0
      expect(merge([0, 4, 4, 8], MergeMode.cascade), [16, 0, 0, 0]);
      expect(merge([8, 4, 2, 2], MergeMode.cascade), [16, 0, 0, 0]);
    });

    test('compte chaque fusion de la cascade dans le score', () {
      final result = mergeLine([8, 4, 2, 2], MergeMode.cascade);
      expect(result.scoreGained, 4 + 8 + 16);
      expect(result.mergedIndexes, {0});
    });

    test('ne marque pas comme fusionnée une tuile arrivée après une cascade', () {
      final result = mergeLine([8, 4, 4, 2], MergeMode.cascade);
      expect(result.values, [16, 2, 0, 0]);
      expect(result.mergedIndexes, {0});
    });
  });

  group('Mode express', () {
    test('deux tuiles identiques donnent une tuile quatre fois plus grande', () {
      expect(merge([2, 2, 0, 0], MergeMode.express), [8, 0, 0, 0]);
      expect(merge([2, 2, 2, 2], MergeMode.express), [8, 8, 0, 0]);
      expect(mergeLine([4, 4, 0, 0], MergeMode.express).scoreGained, 16);
    });
  });

  test('fonctionne sur des lignes de 8 cases', () {
    expect(merge([2, 2, 0, 4, 4, 0, 8, 8]), [4, 8, 16, 0, 0, 0, 0, 0]);
  });
}
