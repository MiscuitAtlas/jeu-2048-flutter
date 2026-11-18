/// Les quatre sens dans lesquels le joueur peut faire glisser les tuiles.
enum Direction {
  up,
  down,
  left,
  right;

  Direction get opposite => switch (this) {
    Direction.up => Direction.down,
    Direction.down => Direction.up,
    Direction.left => Direction.right,
    Direction.right => Direction.left,
  };
}
