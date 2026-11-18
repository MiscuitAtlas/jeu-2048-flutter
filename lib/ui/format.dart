import '../game/game_settings.dart';
import '../game/merge_mode.dart';

/// 12345 donne « 12 345 », avec une espace insécable (U+00A0) comme séparateur des milliers.
String formatNumber(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('\u00A0');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

String formatMoves(int moves) => '${formatNumber(moves)} coup${moves > 1 ? 's' : ''}';

/// Description lisible d'un type de partie, à partir de sa clé de records.
String describeRecordKey(String key) {
  final parts = key.split('-');
  if (parts.length < 3) return key;
  final size = int.tryParse(parts[0]);
  final goal = int.tryParse(parts[1]);
  final mode = MergeMode.values.where((m) => m.name == parts[2]).firstOrNull;
  if (size == null || goal == null || mode == null) return key;
  final random = parts.length > 3 ? ', grille aléatoire' : '';
  return '$size × $size, objectif ${formatNumber(goal)}, mode ${mode.label.toLowerCase()}$random';
}

String describeSettings(GameSettings settings) => describeRecordKey(settings.recordKey);
