export 'package:meta/meta.dart' show visibleForTesting;

bool setEquals<T>(Set<T>? left, Set<T>? right) =>
    identical(left, right) ||
    (left != null &&
        right != null &&
        left.length == right.length &&
        left.containsAll(right));

bool mapEquals<K, V>(Map<K, V>? left, Map<K, V>? right) =>
    identical(left, right) ||
    (left != null &&
        right != null &&
        left.length == right.length &&
        left.entries.every((entry) =>
            right.containsKey(entry.key) && right[entry.key] == entry.value));

/// The server evaluates one isolated game instance per command. It has no UI
/// subscribers; Flutter continues to use its real ChangeNotifier via the
/// conditional import in HouseholdProvider.
class ChangeNotifier {
  void notifyListeners() {}
  void dispose() {}
}
