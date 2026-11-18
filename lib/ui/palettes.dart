import 'dart:math';

import 'package:material_ui/material_ui.dart';

/// Couleurs de la grille et des tuiles.
class TilePalette {
  const TilePalette({
    required this.id,
    required this.name,
    required this.board,
    required this.emptyCell,
    required this.tiles,
    required this.darkText,
    required this.lightText,
  });

  final String id;
  final String name;
  final Color board;
  final Color emptyCell;

  /// Couleur de chaque valeur : 2, 4, 8… La dernière sert aussi pour les valeurs au-delà.
  final List<Color> tiles;
  final Color darkText;
  final Color lightText;

  Color tileColor(int value) {
    final exponent = (log(value) / ln2).round();
    return tiles[(exponent - 1).clamp(0, tiles.length - 1)];
  }

  /// Texte sombre ou clair, selon celui qui contraste le mieux avec la tuile.
  Color textColor(int value) {
    final background = tileColor(value);
    return _contrast(background, darkText) >= _contrast(background, lightText) ? darkText : lightText;
  }

  static double _contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
  }
}

const palettes = [
  TilePalette(
    id: 'classique',
    name: 'Classique',
    board: Color(0xFFBBADA0),
    emptyCell: Color(0xFFCDC1B4),
    tiles: [
      Color(0xFFEEE4DA),
      Color(0xFFEDE0C8),
      Color(0xFFF2B179),
      Color(0xFFF59563),
      Color(0xFFF67C5F),
      Color(0xFFF65E3B),
      Color(0xFFEDCF72),
      Color(0xFFEDCC61),
      Color(0xFFEDC850),
      Color(0xFFEDC53F),
      Color(0xFFEDC22E),
      Color(0xFF3C3A32),
      Color(0xFF23211C),
    ],
    darkText: Color(0xFF5C544B),
    lightText: Color(0xFFFFFDF8),
  ),
  TilePalette(
    id: 'ocean',
    name: 'Océan',
    board: Color(0xFF2C4A5A),
    emptyCell: Color(0xFF3B5F72),
    tiles: [
      Color(0xFFE3F4F4),
      Color(0xFFC3E9EC),
      Color(0xFF8FD6DE),
      Color(0xFF5BC0CF),
      Color(0xFF2FA6BD),
      Color(0xFF158AA5),
      Color(0xFF0F6E8C),
      Color(0xFF1F5FAD),
      Color(0xFF2E4FC4),
      Color(0xFF4B3FD0),
      Color(0xFFF2B33D),
      Color(0xFFE5793A),
      Color(0xFFC94A3A),
    ],
    darkText: Color(0xFF13343D),
    lightText: Color(0xFFFFFFFF),
  ),
  TilePalette(
    id: 'foret',
    name: 'Forêt',
    board: Color(0xFF4A563A),
    emptyCell: Color(0xFF5E6B4C),
    tiles: [
      Color(0xFFF1F5E4),
      Color(0xFFDDE8C4),
      Color(0xFFC3D99C),
      Color(0xFFA5C873),
      Color(0xFF86B24E),
      Color(0xFF6B9A36),
      Color(0xFF557F2A),
      Color(0xFF41671F),
      Color(0xFF8A6A2B),
      Color(0xFFB3812A),
      Color(0xFFE0A21F),
      Color(0xFFD9652B),
      Color(0xFFA63A28),
    ],
    darkText: Color(0xFF2C3620),
    lightText: Color(0xFFFFFFFF),
  ),
];

TilePalette paletteById(String id) => palettes.firstWhere((p) => p.id == id, orElse: () => palettes.first);
