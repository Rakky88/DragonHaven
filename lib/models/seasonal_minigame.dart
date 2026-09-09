import 'dart:math';

/// Elapsed active play drives difficulty, independent of render frame rate.
abstract final class SeasonalArcadePacing {
  // Begin at the previous 40-seconds-remaining pace (75 - 40 = 35).
  static double parcelLifetime(double seconds, double might) =>
      max(.95, 4.4 - (35 + max(0, seconds)) * .05) + might.clamp(0, 1) * .35;

  static double parcelInterval(double seconds) =>
      max(.36, 2.4 - (35 + max(0, seconds)) * .031);

  static double chimeBeat(double seconds) =>
      max(.42, 1.10 - max(0, seconds) * .0105);

  static double chimeTravel(double seconds, double spirit) =>
      max(.9, 2.1 - max(0, seconds) * .018) + spirit.clamp(0, 1) * .4;

  // Original four-pitch melody: C, D, E and G. One phrase repeats with a
  // seed-selected starting phrase; pitch, timing and harmony stay coordinated.
  static const melody = [
    0,
    2,
    3,
    2,
    1,
    2,
    1,
    0,
    2,
    3,
    3,
    2,
    1,
    0,
    1,
    3,
    0,
    1,
    2,
    3,
    2,
    1,
    0,
    0,
    3,
    2,
    1,
    2,
    1,
    0,
    3,
    0,
  ];

  static List<int> chimeLanes(int beat, double seconds, int phrase) {
    final lead = melody[(beat + phrase * 8) % melody.length];
    final chord = seconds >= 45 ? beat.isEven : seconds >= 22 && beat % 4 == 0;
    return [
      lead,
      if (chord) const [2, 3, 0, 1][lead]
    ];
  }
}

/// Directions are clockwise, matching the prism connector bits.
enum HeartDirection { up, right, down, left }

int? gridNeighbor(int cell, int direction, int columns, int rows) {
  final x = cell % columns;
  final y = cell ~/ columns;
  final nx = x + const [0, 1, 0, -1][direction];
  final ny = y + const [-1, 0, 1, 0][direction];
  return nx < 0 || nx >= columns || ny < 0 || ny >= rows
      ? null
      : ny * columns + nx;
}

/// Both hearts respond to a move; horizontal movement is mirrored on the right.
/// A blocked heart waits while its partner moves. Boards are solved by BFS
/// before being offered, so every generated pair has a reachable shared goal.
class HeartMaze {
  HeartMaze._(this.leftWalls, this.rightWalls);
  static const columns = 3;
  static const rows = 5;
  static const leftStart = 12;
  static const rightStart = 14;
  static const leftGoal = 2;
  static const rightGoal = 0;
  final Set<int> leftWalls;
  final Set<int> rightWalls;
  int left = leftStart;
  int right = rightStart;
  final Set<int> visited = {leftStart * 15 + rightStart};

  factory HeartMaze.generate(Random random) {
    for (var attempt = 0; attempt < 160; attempt++) {
      Set<int> walls(Set<int> protected) {
        final cells = List.generate(15, (i) => i)
          ..removeWhere(protected.contains);
        cells.shuffle(random);
        return cells.take(4).toSet();
      }

      final maze = HeartMaze._(
          walls({leftStart, leftGoal}), walls({rightStart, rightGoal}));
      final solution = maze.solution();
      if (solution != null && solution.length >= 7 && solution.length <= 16) {
        return maze;
      }
    }
    // Deterministic, reachable fallback, with no unbounded generation loop.
    return HeartMaze._({1, 4, 7}, {1, 4, 7});
  }

  bool get solved => left == leftGoal && right == rightGoal;
  (int, int) next(int l, int r, HeartDirection direction) {
    final d = direction.index;
    final mirrored = d == 1
        ? 3
        : d == 3
            ? 1
            : d;
    final nl = gridNeighbor(l, d, columns, rows);
    final nr = gridNeighbor(r, mirrored, columns, rows);
    return (
      nl == null || leftWalls.contains(nl) ? l : nl,
      nr == null || rightWalls.contains(nr) ? r : nr
    );
  }

  /// null is blocked; false is a revisited state and awards no extra points.
  bool? move(HeartDirection direction) {
    final n = next(left, right, direction);
    if (n == (left, right)) return null;
    left = n.$1;
    right = n.$2;
    return visited.add(left * 15 + right);
  }

  List<HeartDirection>? solution() {
    final initial = left * 15 + right;
    final paths = <int, List<HeartDirection>>{initial: []};
    final queue = <int>[initial];
    for (var head = 0; head < queue.length; head++) {
      final state = queue[head];
      if (state == leftGoal * 15 + rightGoal) return paths[state];
      for (final direction in HeartDirection.values) {
        final n = next(state ~/ 15, state % 15, direction);
        final encoded = n.$1 * 15 + n.$2;
        if (paths.containsKey(encoded)) continue;
        paths[encoded] = [...paths[state]!, direction];
        queue.add(encoded);
      }
    }
    return null;
  }
}

class PrismCircuit {
  PrismCircuit._(this.source, this.sink, this.connectors, this.solutionMasks);
  static const size = 4;
  final int source;
  final int sink;
  final List<int> connectors;
  final Map<int, int> solutionMasks;
  final Set<int> credited = {};

  static int rotateMask(int mask) => ((mask << 1) & 15) | (mask >> 3);

  factory PrismCircuit.generate(Random random) {
    List<int>? route;
    for (var attempt = 0; attempt < 100 && route == null; attempt++) {
      final start = random.nextInt(size) * size;
      List<int>? walk(List<int> path) {
        final cell = path.last;
        if (cell % size == size - 1 && path.length >= 6) return path;
        if (path.length >= 11) return null;
        final directions = [0, 1, 2, 3]..shuffle(random);
        for (final d in directions) {
          final next = gridNeighbor(cell, d, size, size);
          if (next == null || path.contains(next)) continue;
          final result = walk([...path, next]);
          if (result != null) return result;
        }
        return null;
      }

      route = walk([start]);
    }
    route ??= [0, 4, 8, 9, 10, 6, 7];
    int direction(int from, int to) => to == from - size
        ? 0
        : to == from + 1
            ? 1
            : to == from + size
                ? 2
                : 3;
    final solutions = <int, int>{};
    for (var i = 0; i < route.length; i++) {
      final entering = i == 0 ? 3 : direction(route[i], route[i - 1]);
      final leaving =
          i == route.length - 1 ? 1 : direction(route[i], route[i + 1]);
      solutions[route[i]] = (1 << entering) | (1 << leaving);
    }
    final masks = List.generate(16, (i) {
      var mask = solutions[i] ?? (random.nextBool() ? 3 : 5);
      for (var turns = random.nextInt(4); turns > 0; turns--) {
        mask = rotateMask(mask);
      }
      return mask;
    });
    final circuit = PrismCircuit._(route.first, route.last, masks, solutions);
    // Never hand over an already completed board.
    if (circuit.solved) circuit.rotate(circuit.source);
    circuit.credited.addAll(circuit.litCells);
    return circuit;
  }

  void rotate(int cell) => connectors[cell] = rotateMask(connectors[cell]);

  List<int> get litCells {
    final result = <int>[];
    var cell = source;
    var incoming = 3;
    while (!result.contains(cell)) {
      final mask = connectors[cell];
      if (mask & (1 << incoming) == 0) break;
      result.add(cell);
      final outgoing =
          [0, 1, 2, 3].firstWhere((d) => d != incoming && mask & (1 << d) != 0);
      final next = gridNeighbor(cell, outgoing, size, size);
      if (next == null) break;
      cell = next;
      incoming = (outgoing + 2) % 4;
    }
    return result;
  }

  bool get solved {
    final lit = litCells;
    return lit.isNotEmpty && lit.last == sink && connectors[sink] & 2 != 0;
  }
}
