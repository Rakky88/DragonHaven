import 'dart:math';

class OrchardPiece {
  const OrchardPiece(this.cells, this.fruit);
  final List<(int, int)> cells;
  final int fruit;
  int get width => cells.map((c) => c.$1).reduce(max) + 1;
  int get height => cells.map((c) => c.$2).reduce(max) + 1;
  OrchardPiece rotated() {
    final h = height;
    return OrchardPiece([for (final (x, y) in cells) (h - 1 - y, x)], fruit);
  }
}

class OrchardPlacement {
  const OrchardPlacement(this.rows, this.fruitCount, this.overflow);
  final int rows, fruitCount;
  final bool overflow;
}

/// A tray of three rotatable fruit shapes. Only complete rows are harvested.
class MoonlitOrchard {
  MoonlitOrchard(
      {required int seed,
      double might = 0,
      double arcana = 0,
      double spirit = 0})
      : _random = Random(seed),
        // Expertise gives a bounded extra small piece, never free score.
        smallPieceChance = .10 +
            (might.clamp(0, 1) + arcana.clamp(0, 1) + spirit.clamp(0, 1)) *
                .035 {
    refill();
  }
  static const columns = 6, rows = 7;
  static const shapes = <List<(int, int)>>[
    [(0, 0), (1, 0)],
    [(0, 0), (1, 0), (2, 0)],
    [(0, 0), (1, 0), (0, 1), (1, 1)],
    [(0, 0), (0, 1), (1, 1)],
    [(0, 0), (1, 0), (2, 0), (1, 1)],
    [(0, 0), (0, 1), (0, 2), (1, 2)],
    [(0, 0), (1, 0), (1, 1), (2, 1)],
  ];
  final Random _random;
  final double smallPieceChance;
  final board = List<int?>.filled(columns * rows, null);
  final tray = <OrchardPiece?>[];
  int mistakes = 0, harvestedRows = 0;
  bool get finished => mistakes >= 3;

  void refill() {
    tray.clear();
    for (var i = 0; i < 3; i++) {
      var piece = OrchardPiece(
          _random.nextDouble() < smallPieceChance
              ? const [(0, 0)]
              : shapes[_random.nextInt(shapes.length)],
          _random.nextInt(3));
      for (var turns = _random.nextInt(4); turns > 0; turns--) {
        piece = piece.rotated();
      }
      tray.add(piece);
    }
  }

  bool fits(OrchardPiece piece, int x, int y) =>
      !finished &&
      piece.cells.every((c) {
        final nx = x + c.$1, ny = y + c.$2;
        return nx >= 0 &&
            nx < columns &&
            ny >= 0 &&
            ny < rows &&
            board[ny * columns + nx] == null;
      });

  bool get canPlaceAny {
    for (final original in tray.whereType<OrchardPiece>()) {
      var piece = original;
      for (var turns = 0; turns < 4; turns++) {
        for (var y = 0; y < rows; y++) {
          for (var x = 0; x < columns; x++) {
            if (fits(piece, x, y)) return true;
          }
        }
        piece = piece.rotated();
      }
    }
    return false;
  }

  void rotate(int index) {
    if (!finished && index >= 0 && index < tray.length && tray[index] != null) {
      tray[index] = tray[index]!.rotated();
    }
  }

  OrchardPlacement? place(int index, int x, int y) {
    if (finished || index < 0 || index >= tray.length) return null;
    final piece = tray[index];
    if (piece == null || !fits(piece, x, y)) return null;
    for (final c in piece.cells) {
      board[(y + c.$2) * columns + x + c.$1] = piece.fruit;
    }
    tray[index] = null;
    final full = <int>[];
    for (var row = 0; row < rows; row++) {
      if (List.generate(columns, (x) => board[row * columns + x])
          .every((v) => v != null)) {
        full.add(row);
      }
    }
    if (full.isNotEmpty) {
      final remaining = [
        for (var y = 0; y < rows; y++)
          if (!full.contains(y))
            for (var x = 0; x < columns; x++) board[y * columns + x]
      ];
      board.setAll(
          0, [...List<int?>.filled(full.length * columns, null), ...remaining]);
      harvestedRows += full.length;
    }
    if (tray.every((v) => v == null)) refill();
    final overflow = !canPlaceAny;
    if (overflow) mistakes++;
    return OrchardPlacement(full.length, piece.cells.length, overflow);
  }

  /// After a full basket, the next try starts empty; score remains outside here.
  void freshBasket() {
    if (finished) return;
    board.fillRange(0, board.length, null);
    refill();
  }
}
