import 'dart:math';

import 'package:flutter/foundation.dart';

import '../storage/game_storage.dart';
import 'board.dart';
import 'direction.dart';
import 'game_settings.dart';

enum GameStatus {
  playing,

  /// L'objectif vient d'être atteint : le joueur choisit de continuer ou de recommencer.
  won,

  /// Plus aucun mouvement possible.
  lost,
}

class _Snapshot {
  const _Snapshot(this.board, this.score, this.moves, this.status, this.keepPlaying);

  final Board board;
  final int score;
  final int moves;
  final GameStatus status;
  final bool keepPlaying;
}

/// État d'une partie et règles qui la font avancer, indépendamment de l'affichage.
class GameController extends ChangeNotifier {
  GameController({required this._settings, this.storage, Random? random}) : _random = random ?? Random() {
    if (!_restoreSavedGame()) _startNewGame();
  }

  /// Nombre de coups que l'on peut annuler à la suite.
  static const maxUndo = 20;

  final GameStorage? storage;
  final Random _random;

  GameSettings _settings;
  late Board _board;
  int _score = 0;
  int _moves = 0;
  GameStatus _status = GameStatus.playing;
  bool _keepPlaying = false;
  int? _spawnedCell;
  Set<int> _mergedCells = const {};
  int _turn = 0;
  final List<_Snapshot> _history = [];

  GameSettings get settings => _settings;
  Board get board => _board;
  int get score => _score;
  int get moves => _moves;
  GameStatus get status => _status;

  /// Vrai si le joueur a choisi de continuer après avoir atteint l'objectif.
  bool get keepPlaying => _keepPlaying;
  bool get canUndo => _history.isNotEmpty;

  /// Case de la tuile apparue au dernier coup, pour l'animer.
  int? get spawnedCell => _spawnedCell;

  /// Cases issues d'une fusion au dernier coup, pour les animer.
  Set<int> get mergedCells => _mergedCells;

  /// Change à chaque coup ou nouvelle partie : déclenche les animations.
  int get turn => _turn;

  GameRecord get record => storage?.recordFor(_settings.recordKey) ?? const GameRecord();

  void newGame() {
    _startNewGame();
    _save();
    notifyListeners();
  }

  void applySettings(GameSettings settings) {
    final restart = settings.recordKey != _settings.recordKey;
    _settings = settings;
    storage?.saveSettings(settings);
    if (restart) {
      _startNewGame();
      _save();
    }
    notifyListeners();
  }

  /// Joue un coup. Renvoie faux si le coup ne change rien (il ne compte pas).
  bool move(Direction gesture) {
    if (_status != GameStatus.playing) return false;
    final direction = _settings.invertedControls ? gesture.opposite : gesture;
    final result = _board.move(direction, _settings.mode);
    if (!result.moved) return false;

    _history.add(_Snapshot(_board, _score, _moves, _status, _keepPlaying));
    if (_history.length > maxUndo) _history.removeAt(0);

    final spawn = result.board.spawnTile(_random);
    _board = spawn?.board ?? result.board;
    _spawnedCell = spawn?.index;
    _mergedCells = result.mergedCells;
    _score += result.scoreGained;
    _moves++;
    _turn++;

    if (!_keepPlaying && _board.maxTile >= _settings.goal) {
      _status = GameStatus.won;
    } else if (!_board.canMove) {
      _status = GameStatus.lost;
    }
    _updateRecord();
    _save();
    notifyListeners();
    return true;
  }

  void undo() {
    if (_history.isEmpty) return;
    final previous = _history.removeLast();
    _board = previous.board;
    _score = previous.score;
    _moves = previous.moves;
    _status = previous.status;
    _keepPlaying = previous.keepPlaying;
    _spawnedCell = null;
    _mergedCells = const {};
    _turn++;
    _save();
    notifyListeners();
  }

  /// Après une victoire, poursuivre la partie pour faire grandir les tuiles.
  void continueAfterWin() {
    if (_status != GameStatus.won) return;
    _keepPlaying = true;
    _status = _board.canMove ? GameStatus.playing : GameStatus.lost;
    _save();
    notifyListeners();
  }

  /// Impose une grille, pour les tests uniquement.
  @visibleForTesting
  void debugSetBoard(Board board) {
    _board = board;
    _history.clear();
    _score = 0;
    _moves = 0;
    _status = GameStatus.playing;
    _keepPlaying = false;
    notifyListeners();
  }

  void _startNewGame() {
    _history.clear();
    _score = 0;
    _moves = 0;
    _status = GameStatus.playing;
    _keepPlaying = false;
    _mergedCells = const {};
    _turn++;
    if (_settings.randomStart) {
      _board = Board.random(_settings.size, _settings.goal, _random);
      _spawnedCell = null;
    } else {
      final first = Board.empty(_settings.size).spawnTile(_random)!;
      final second = first.board.spawnTile(_random)!;
      _board = second.board;
      _spawnedCell = null;
    }
  }

  void _updateRecord() {
    final store = storage;
    if (store == null) return;
    final current = store.recordFor(_settings.recordKey);
    final reachedGoal = _status == GameStatus.won;
    final bestScore = max(current.bestScore, _score);
    final fewest = reachedGoal && (current.fewestMoves == null || _moves < current.fewestMoves!)
        ? _moves
        : current.fewestMoves;
    if (bestScore != current.bestScore || fewest != current.fewestMoves) {
      store.saveRecord(_settings.recordKey, GameRecord(bestScore: bestScore, fewestMoves: fewest));
    }
  }

  void _save() {
    storage?.saveGame(
      _status == GameStatus.lost
          ? null
          : SavedGame(
              recordKey: _settings.recordKey,
              size: _board.size,
              cells: _board.cells,
              score: _score,
              moves: _moves,
              won: _keepPlaying,
            ),
    );
  }

  bool _restoreSavedGame() {
    final saved = storage?.loadGame();
    if (saved == null || saved.recordKey != _settings.recordKey || saved.size != _settings.size) return false;
    final board = Board(saved.size, saved.cells);
    if (!board.canMove) return false;
    _board = board;
    _score = saved.score;
    _moves = saved.moves;
    _keepPlaying = saved.won;
    _status = !_keepPlaying && board.maxTile >= _settings.goal ? GameStatus.won : GameStatus.playing;
    return true;
  }
}
