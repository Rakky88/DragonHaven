/// A permanent egg property. The independent seed bit gives equal chances and
/// does not consume (or change) the existing chest/egg reward rolls.
enum DragonSex {
  male,
  female;

  static DragonSex fromSeed(int seed) =>
      ((seed ^ (seed >> 16)) & 1) == 0 ? male : female;

  static DragonSex fromJson(Map<String, dynamic> json) {
    if (json['sex'] == 'male') return male;
    if (json['sex'] == 'female') return female;
    final seed = json['hatchSeed'];
    if (seed is num) return fromSeed(seed.toInt().abs());
    // Very old saves can lack a seed. Never use the wall clock or Dart's
    // platform-dependent hashCode when assigning their permanent property.
    var hash = 17;
    final identity =
        '${json['id'] ?? ''}|${json['acquiredAt'] ?? ''}|${json['lineageId'] ?? ''}';
    for (final unit in identity.codeUnits) {
      // Keep intermediates below 2^53, including in the compiled web worker.
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return fromSeed(hash);
  }
}
