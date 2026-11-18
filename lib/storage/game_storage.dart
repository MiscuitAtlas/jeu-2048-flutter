import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../game/game_settings.dart';

/// Meilleures performances pour un type de partie (taille, objectif, mode).
class GameRecord {
  const GameRecord({this.bestScore = 0, this.fewestMoves});

  final int bestScore;

  /// Plus petit nombre de coups pour atteindre l'objectif ; null tant qu'il n'a jamais été atteint.
  final int? fewestMoves;

  Map<String, Object?> toJson() => {'bestScore': bestScore, 'fewestMoves': fewestMoves};

  factory GameRecord.fromJson(Map<String, Object?> json) => GameRecord(
    bestScore: json['bestScore'] is int ? json['bestScore']! as int : 0,
    fewestMoves: json['fewestMoves'] is int ? json['fewestMoves'] as int : null,
  );
}

/// Partie en cours, enregistrée pour être reprise au prochain lancement.
class SavedGame {
  const SavedGame({
    required this.recordKey,
    required this.size,
    required this.cells,
    required this.score,
    required this.moves,
    required this.won,
  });

  final String recordKey;
  final int size;
  final List<int> cells;
  final int score;
  final int moves;

  /// L'objectif a déjà été atteint et le joueur a choisi de continuer.
  final bool won;

  Map<String, Object> toJson() => {
    'recordKey': recordKey,
    'size': size,
    'cells': cells,
    'score': score,
    'moves': moves,
    'won': won,
  };

  static SavedGame? fromJson(Map<String, Object?> json) {
    final cells = json['cells'];
    final size = json['size'];
    if (cells is! List || size is! int || cells.length != size * size || cells.any((c) => c is! int || c < 0)) {
      return null;
    }
    return SavedGame(
      recordKey: json['recordKey'] is String ? json['recordKey']! as String : '',
      size: size,
      cells: cells.cast<int>(),
      score: json['score'] is int ? json['score']! as int : 0,
      moves: json['moves'] is int ? json['moves']! as int : 0,
      won: json['won'] == true,
    );
  }
}

/// Réglages, records et partie en cours, conservés sur l'appareil
/// (SharedPreferences : stockage local sur mobile, localStorage sur le web).
class GameStorage {
  GameStorage(this._prefs);

  static Future<GameStorage> open() async => GameStorage(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  static const _settingsKey = 'reglages';
  static const _recordsKey = 'records';
  static const _savedGameKey = 'partie';

  GameSettings loadSettings() => GameSettings.fromJson(_readMap(_settingsKey) ?? const {});

  Future<void> saveSettings(GameSettings settings) => _prefs.setString(_settingsKey, jsonEncode(settings.toJson()));

  Map<String, GameRecord> loadRecords() {
    final map = _readMap(_recordsKey) ?? const {};
    return {
      for (final entry in map.entries)
        if (entry.value is Map) entry.key: GameRecord.fromJson((entry.value! as Map).cast<String, Object?>()),
    };
  }

  GameRecord recordFor(String key) => loadRecords()[key] ?? const GameRecord();

  Future<void> saveRecord(String key, GameRecord record) {
    final records = loadRecords()..[key] = record;
    return _prefs.setString(_recordsKey, jsonEncode({for (final e in records.entries) e.key: e.value.toJson()}));
  }

  SavedGame? loadGame() {
    final map = _readMap(_savedGameKey);
    return map == null ? null : SavedGame.fromJson(map);
  }

  Future<void> saveGame(SavedGame? game) =>
      game == null ? _prefs.remove(_savedGameKey) : _prefs.setString(_savedGameKey, jsonEncode(game.toJson()));

  /// Lit un objet JSON ; une valeur corrompue est ignorée plutôt que de bloquer l'application.
  Map<String, Object?>? _readMap(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? decoded.cast<String, Object?>() : null;
    } on FormatException {
      return null;
    }
  }
}
