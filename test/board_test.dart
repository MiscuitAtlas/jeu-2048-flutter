import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:jeu_2048/game/board.dart';
import 'package:jeu_2048/game/direction.dart';
import 'package:jeu_2048/game/merge_mode.dart';

void main() {
  final board = Board.fromRows([
    [2, 2, 4, 8],
    [0, 4, 4, 8],
    [8, 4, 2, 2],
    [0, 0, 0, 2],
  ]);

  group('Mouvements', () {
    test('vers la gauche et la droite', () {
      expect(board.move(Direction.left, MergeMode.classic).board.rows, [
        [4, 4, 8, 0],
        [8, 8, 0, 0],
        [8, 4, 4, 0],
        [2, 0, 0, 0],
      ]);
      expect(board.move(Direction.right, MergeMode.classic).board.rows, [
        [0, 4, 4, 8],
        [0, 0, 8, 8],
        [0, 8, 4, 4],
        [0, 0, 0, 2],
      ]);
    });

    test('vers le haut et le bas', () {
      expect(board.move(Direction.up, MergeMode.classic).board.rows, [
        [2, 2, 8, 16],
        [8, 8, 2, 4],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      expect(board.move(Direction.down, MergeMode.classic).board.rows, [
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [2, 2, 8, 16],
        [8, 8, 2, 4],
      ]);
    });

    test('en cascade, reproduit les exemples de l\'énoncé vers la droite', () {
      final result = board.move(Direction.right, MergeMode.cascade).board;
      expect(result.rows[0], [0, 0, 0, 16]);
      expect(result.rows[1], [0, 0, 0, 16]);
    });

    test('indique le score et les cases fusionnées', () {
      final result = board.move(Direction.left, MergeMode.classic);
      expect(result.scoreGained, 4 + 8 + 4);
      expect(result.mergedCells, {0, 4, 10});
    });

    test('un coup qui ne change rien n\'est pas un mouvement', () {
      final stuck = Board.fromRows([
        [2, 4],
        [4, 2],
      ]);
      for (final direction in Direction.values) {
        expect(stuck.move(direction, MergeMode.classic).moved, isFalse);
      }
      expect(stuck.canMove, isFalse);
    });
  });

  group('Fin de partie', () {
    test('une grille pleine sans voisins égaux est bloquée', () {
      expect(
        Board.fromRows([
          [2, 4, 2],
          [4, 2, 4],
          [2, 4, 2],
        ]).canMove,
        isFalse,
      );
    });

    test('une grille pleine avec deux voisins égaux peut encore bouger', () {
      expect(
        Board.fromRows([
          [2, 4, 2],
          [4, 2, 4],
          [2, 4, 4],
        ]).canMove,
        isTrue,
      );
      expect(
        Board.fromRows([
          [2, 4, 2],
          [4, 2, 4],
          [2, 2, 8],
        ]).canMove,
        isTrue,
      );
    });
  });

  group('Nouvelles tuiles', () {
    test('apparaissent dans une case vide, avec un 2 ou un 4', () {
      final random = Random(1);
      var current = Board.empty(4);
      for (var i = 0; i < 16; i++) {
        final spawn = current.spawnTile(random)!;
        expect(current.cells[spawn.index], 0);
        expect(spawn.board.cells[spawn.index], anyOf(2, 4));
        current = spawn.board;
      }
      expect(current.spawnTile(random), isNull);
    });

    test('sont surtout des 2', () {
      final random = Random(7);
      var fours = 0;
      for (var i = 0; i < 1000; i++) {
        final spawn = Board.empty(4).spawnTile(random)!;
        if (spawn.board.cells[spawn.index] == 4) fours++;
      }
      expect(fours, inInclusiveRange(60, 140));
    });
  });

  group('Grille aléatoire', () {
    for (final size in [4, 8]) {
      test('$size × $size : laisse des trous et reste sous le quart de l\'objectif', () {
        final random = Random(size);
        for (var i = 0; i < 50; i++) {
          final grid = Board.random(size, 512, random);
          final filled = grid.cells.where((v) => v != 0).length;
          expect(filled, inInclusiveRange((size * size * 0.4).floor(), (size * size * 0.6).ceil()));
          expect(grid.maxTile, lessThanOrEqualTo(128));
          expect(grid.cells.where((v) => v != 0).every((v) => v & (v - 1) == 0), isTrue, reason: 'puissances de 2');
          expect(grid.canMove, isTrue);
        }
      });
    }
  });

  test('refuse une grille dont la taille ne correspond pas', () {
    expect(() => Board(4, [0, 0]), throwsArgumentError);
  });
}
