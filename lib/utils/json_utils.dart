T? enumByName<T extends Enum>(Iterable<T> values, Object? name) {
  if (name is! String) return null;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}

int intFromJson(Object? value, {required int fallback}) =>
    value is num ? value.toInt() : fallback;

int nonNegativeIntFromJson(Object? value, {required int fallback}) =>
    intFromJson(value, fallback: fallback).clamp(0, 0x7fffffff).toInt();

int percentageFromJson(Object? value, {required int fallback}) =>
    intFromJson(value, fallback: fallback).clamp(0, 100).toInt();

String? stringFromJson(Object? value) => value is String ? value : null;

String? nonEmptyStringFromJson(Object? value) {
  final text = stringFromJson(value)?.trim();
  return text == null || text.isEmpty ? null : text;
}

Map<String, dynamic> mapFromJson(Object? value) => value is Map
    ? <String, dynamic>{
        for (final entry in value.entries)
          if (entry.key is String) entry.key as String: entry.value,
      }
    : <String, dynamic>{};

Iterable<Map<String, dynamic>> mapsFromJson(Object? value) sync* {
  if (value is! List) return;
  for (final entry in value) {
    if (entry is Map) yield mapFromJson(entry);
  }
}

Set<String> stringSetFromJson(Object? value) =>
    value is List ? value.whereType<String>().toSet() : <String>{};
