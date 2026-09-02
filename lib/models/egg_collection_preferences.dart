import 'dragon_egg.dart';

enum EggCollectionView { tiles, list }

enum EggCollectionSortMode { acquiredAt, hatchTime }

List<DragonEgg> sortedDragonEggs(
  Iterable<DragonEgg> source, {
  required EggCollectionSortMode sortMode,
  required bool descending,
}) {
  final eggs = source.toList(growable: false)
    ..sort((a, b) {
      final comparison = switch (sortMode) {
        EggCollectionSortMode.acquiredAt =>
          a.acquiredAt.compareTo(b.acquiredAt),
        EggCollectionSortMode.hatchTime =>
          a.incubationSeconds.compareTo(b.incubationSeconds),
      };
      final stable = comparison != 0 ? comparison : a.id.compareTo(b.id);
      return descending ? -stable : stable;
    });
  return eggs;
}
