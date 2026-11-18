import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:jeu_2048/game/board.dart';
import 'package:jeu_2048/game/direction.dart';
import 'package:jeu_2048/game/game_controller.dart';
import 'package:jeu_2048/game/game_settings.dart';
import 'package:jeu_2048/game/merge_mode.dart';
import 'package:jeu_2048/storage/game_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<GameStorage> emptyStorage([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  return GameStorage(await SharedPreferences.getInstance());
}

/// Contrôleur dont la grille est imposée, pour des scénarios précis.
GameController withBoard(Board board, {GameSettings? settings, GameStorage? storage}) {
  final controller = GameController(
    settings: settings ?? GameSettings(size: board.size, goal: 256),
    storage: storage,
    random: Random(1),
  );
  controller.debugSetBoard(board);
  return controller;
}

void main() {
  test('une nouvelle partie commence avec deux tuiles', () {
    final controller = GameController(settings: const GameSettings(), random: Random(3));
    expect(controller.board.cells.where((v) => v != 0), hasLength(2));
    expect(controller.score, 0);
    expect(controller.moves, 0);
    expect(controller.status, GameStatus.playing);
  });

  test('un coup valide ajoute une tuile, compte le coup et le score', () {
    final controller = withBoard(
      Board.fromRows([
        [2, 2, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]),
    );
    expect(controller.move(Direction.left), isTrue);
    expect(controller.board.at(0, 0), 4);
    expect(controller.board.cells.where((v) => v != 0), hasLength(2));
    expect(controller.moves, 1);
    expect(controller.score, 4);
    expect(controller.spawnedCell, isNotNull);
    expect(controller.mergedCells, {0});
  });

  test('un coup qui ne change rien n\'est pas compté', () {
    final controller = withBoard(
      Board.fromRows([
        [2, 4, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]),
    );
    expect(controller.move(Direction.left), isFalse);
    expect(controller.moves, 0);
    expect(controller.canUndo, isFalse);
  });

  test('les commandes inversées envoient les tuiles à l\'opposé', () {
    final controller = withBoard(
      Board.fromRows([
        [2, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]),
      settings: const GameSettings(invertedControls: true, goal: 256),
    );
    controller.move(Direction.left);
    expect(controller.board.at(0, 3), 2);
  });

  test('annuler revient au coup précédent, plusieurs fois de suite', () {
    final start = Board.fromRows([
      [2, 2, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ]);
    final controller = withBoard(start);
    controller.move(Direction.left);
    final afterFirst = controller.board;
    controller.move(Direction.down);
    controller.undo();
    expect(controller.board, afterFirst);
    expect(controller.moves, 1);
    controller.undo();
    expect(controller.board, start);
    expect(controller.moves, 0);
    expect(controller.score, 0);
    expect(controller.canUndo, isFalse);
  });

  test('atteindre l\'objectif gagne la partie, puis on peut continuer', () {
    final controller = withBoard(
      Board.fromRows([
        [128, 128, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]),
    );
    controller.move(Direction.left);
    expect(controller.status, GameStatus.won);
    expect(controller.move(Direction.right), isFalse, reason: 'la grille attend la décision du joueur');
    controller.continueAfterWin();
    expect(controller.status, GameStatus.playing);
    expect(controller.move(Direction.right), isTrue);
    expect(controller.status, GameStatus.playing, reason: 'pas de seconde victoire pour le même objectif');
  });

  test('en mode express, dépasser l\'objectif compte comme une victoire', () {
    final controller = withBoard(
      Board.fromRows([
        [128, 128, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]),
      settings: const GameSettings(goal: 256, mode: MergeMode.express),
    );
    controller.move(Direction.left);
    expect(controller.board.at(0, 0), 512);
    expect(controller.status, GameStatus.won);
  });

  test('une grille bloquée après le coup est perdue', () {
    // Après le glissement à droite, la tuile qui apparaît (2 ou 4) remplit la dernière case
    // et ne touche aucune tuile égale.
    final controller = withBoard(
      Board.fromRows([
        [2, 4, 2, 4],
        [4, 2, 4, 2],
        [8, 64, 8, 16],
        [16, 32, 64, 0],
      ]),
    );
    expect(controller.move(Direction.right), isTrue);
    expect(controller.status, GameStatus.lost);
    expect(controller.move(Direction.left), isFalse);
    controller.undo();
    expect(controller.status, GameStatus.playing);
  });

  group('Records', () {
    test('garde le meilleur score et le plus petit nombre de coups pour l\'objectif', () async {
      final storage = await emptyStorage();
      final controller = withBoard(
        Board.fromRows([
          [128, 128, 2, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
        ]),
        storage: storage,
      );
      controller.move(Direction.left);
      expect(controller.record.bestScore, 256);
      expect(controller.record.fewestMoves, 1);
    });

    test('sont séparés par taille, objectif et mode', () {
      expect(const GameSettings().recordKey, isNot(const GameSettings(size: 8).recordKey));
      expect(const GameSettings().recordKey, isNot(const GameSettings(mode: MergeMode.cascade).recordKey));
      expect(const GameSettings().recordKey, const GameSettings(paletteId: 'ocean').recordKey);
    });
  });

  group('Sauvegarde', () {
    test('la partie en cours est reprise au lancement suivant', () async {
      final storage = await emptyStorage();
      final first = GameController(settings: const GameSettings(), storage: storage, random: Random(2));
      for (final d in [Direction.left, Direction.up, Direction.right, Direction.down]) {
        first.move(d);
      }
      final second = GameController(settings: const GameSettings(), storage: storage, random: Random(9));
      expect(second.board, first.board);
      expect(second.score, first.score);
      expect(second.moves, first.moves);
    });

    test('changer de taille ou d\'objectif lance une nouvelle partie', () async {
      final storage = await emptyStorage();
      final controller = GameController(settings: const GameSettings(), storage: storage, random: Random(2));
      controller.move(Direction.left);
      controller.applySettings(const GameSettings(size: 5));
      expect(controller.board.size, 5);
      expect(controller.moves, 0);
    });

    test('changer seulement de palette garde la partie', () async {
      final controller = GameController(settings: const GameSettings(), random: Random(2));
      controller.move(Direction.left);
      final moves = controller.moves;
      controller.applySettings(const GameSettings(paletteId: 'foret'));
      expect(controller.moves, moves);
    });

    test('des données corrompues sont ignorées', () async {
      final storage = await emptyStorage({'partie': '{pas du json', 'reglages': '[]', 'records': '{"x": 3}'});
      expect(storage.loadGame(), isNull);
      expect(storage.loadSettings(), const GameSettings());
      expect(storage.loadRecords(), isEmpty);
      expect(() => GameController(settings: const GameSettings(), storage: storage), returnsNormally);
    });
  });
}
