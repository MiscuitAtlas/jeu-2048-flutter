/// Façon dont les tuiles identiques se combinent lors d'un mouvement.
enum MergeMode {
  /// Règles du 2048 original : deux tuiles identiques fusionnent,
  /// et une tuile ne fusionne qu'une seule fois par coup.
  classic(
    label: 'Classique',
    description:
        'Les règles du 2048 original : deux tuiles identiques fusionnent, '
        'et une tuile ne fusionne qu\'une fois par coup.',
  ),

  /// Variante décrite dans l'énoncé du TP : une tuile tout juste fusionnée
  /// peut fusionner à nouveau avec sa voisine si elles sont égales.
  /// Exemple vers la gauche : 8 4 2 2 donne 16.
  cascade(
    label: 'Cascade',
    description:
        'La variante de l\'énoncé du TP : une tuile tout juste fusionnée peut '
        'fusionner à nouveau. Vers la gauche, 8 4 2 2 donne 16.',
  ),

  /// Deux tuiles identiques donnent une tuile quatre fois plus grande :
  /// les parties sont plus courtes.
  express(
    label: 'Express',
    description:
        'Chaque fusion vaut double : deux tuiles de 2 donnent un 8. '
        'L\'objectif est atteint en beaucoup moins de coups.',
  );

  const MergeMode({required this.label, required this.description});

  final String label;
  final String description;
}
