import 'merge_mode.dart';

/// Réglages d'une partie, choisis dans l'écran des réglages.
class GameSettings {
  const GameSettings({
    this.goal = 2048,
    this.size = 4,
    this.mode = MergeMode.classic,
    this.paletteId = 'classique',
    this.randomStart = false,
    this.invertedControls = false,
  });

  static const goals = [256, 512, 1024, 2048, 4096, 8192];
  static const sizes = [4, 5, 6, 8];

  /// Valeur de la tuile à atteindre pour gagner.
  final int goal;

  /// Nombre de cases par côté.
  final int size;
  final MergeMode mode;
  final String paletteId;

  /// Démarrer avec une grille déjà remplie au hasard.
  final bool randomStart;

  /// Les tuiles partent dans le sens opposé au geste.
  final bool invertedControls;

  /// Identifie les parties comparables entre elles, pour les records.
  /// La palette et les commandes n'influent pas sur la difficulté.
  String get recordKey => '$size-$goal-${mode.name}${randomStart ? '-aleatoire' : ''}';

  GameSettings copyWith({
    int? goal,
    int? size,
    MergeMode? mode,
    String? paletteId,
    bool? randomStart,
    bool? invertedControls,
  }) => GameSettings(
    goal: goal ?? this.goal,
    size: size ?? this.size,
    mode: mode ?? this.mode,
    paletteId: paletteId ?? this.paletteId,
    randomStart: randomStart ?? this.randomStart,
    invertedControls: invertedControls ?? this.invertedControls,
  );

  Map<String, Object> toJson() => {
    'goal': goal,
    'size': size,
    'mode': mode.name,
    'palette': paletteId,
    'randomStart': randomStart,
    'invertedControls': invertedControls,
  };

  /// Lit des réglages enregistrés ; toute valeur absente ou invalide reprend sa valeur par défaut.
  factory GameSettings.fromJson(Map<String, Object?> json) {
    const defaults = GameSettings();
    final goal = json['goal'];
    final size = json['size'];
    final mode = MergeMode.values.where((m) => m.name == json['mode']).firstOrNull;
    return GameSettings(
      goal: goals.contains(goal) ? goal! as int : defaults.goal,
      size: sizes.contains(size) ? size! as int : defaults.size,
      mode: mode ?? defaults.mode,
      paletteId: json['palette'] is String ? json['palette']! as String : defaults.paletteId,
      randomStart: json['randomStart'] == true,
      invertedControls: json['invertedControls'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GameSettings &&
      other.goal == goal &&
      other.size == size &&
      other.mode == mode &&
      other.paletteId == paletteId &&
      other.randomStart == randomStart &&
      other.invertedControls == invertedControls;

  @override
  int get hashCode => Object.hash(goal, size, mode, paletteId, randomStart, invertedControls);
}
