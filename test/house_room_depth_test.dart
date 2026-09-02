import 'package:dragon_haven/screens/house_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('room dragons paint from the back wall toward the foreground', () {
    expect(
      roomDragonDepthOrder(
        const [Offset(.4, .81), Offset(.5, .62), Offset(.3, .71)],
        stableIds: const ['front', 'back', 'middle'],
      ),
      [1, 2, 0],
    );
  });

  test('equal-depth room dragons keep a deterministic order', () {
    expect(
      roomDragonDepthOrder(
        const [Offset(.5, .7), Offset(.5, .7), Offset(.3, .7)],
        stableIds: const ['zephyr', 'aurora', 'left'],
      ),
      [2, 1, 0],
    );
  });
}
