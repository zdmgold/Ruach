/// The six upgrades, named for the six gifts in Isaiah 11:2: the spirit of
/// wisdom, understanding, counsel, might, knowledge and the fear of the LORD.
/// They are earned by playing and are never sold (blueprint section 2).
///
/// What each one improves, and by how much per level, is defined by
/// `upgrade_rules.dart` (batch p2c). This file holds only identity and the
/// player's levels.
enum UpgradeKind {
  /// Ruach meter fill rate.
  wisdom('wisdom'),

  /// Grip in corners.
  understanding('understanding'),

  /// Length of the racing-line guide.
  counsel('counsel'),

  /// Top speed.
  might('might'),

  /// Speed recovery after leaving the track or after contact.
  knowledge('knowledge'),

  /// Steadiness on rough surfaces and in contact.
  fearOfTheLord('fear_of_the_lord');

  const UpgradeKind(this.id);

  /// Stable id used in saved progress. Never change an existing value.
  final String id;

  /// The upgrade with this saved id, or null if it is unknown (for example,
  /// progress written by a newer version of the app).
  static UpgradeKind? fromId(String id) {
    for (final UpgradeKind kind in UpgradeKind.values) {
      if (kind.id == id) return kind;
    }
    return null;
  }
}

/// The player's level, 0 to [maxLevel], in each upgrade. Immutable: changing
/// a level returns a new value.
final class UpgradeLevels {
  const UpgradeLevels._(this._levels);

  /// Builds levels from a map. Missing upgrades are level 0, and every level
  /// is forced into the range 0 to [maxLevel].
  factory UpgradeLevels.fromMap(Map<UpgradeKind, int> levels) {
    final List<int> list = <int>[
      for (final UpgradeKind kind in UpgradeKind.values)
        (levels[kind] ?? 0).clamp(0, maxLevel).toInt(),
    ];
    return UpgradeLevels._(List<int>.unmodifiable(list));
  }

  /// Every upgrade at level 0.
  static const UpgradeLevels none = UpgradeLevels._(<int>[0, 0, 0, 0, 0, 0]);

  /// The highest level of any upgrade.
  static const int maxLevel = 5;

  final List<int> _levels;

  int levelOf(UpgradeKind kind) => _levels[kind.index];

  /// These levels with one upgrade set to [level], forced into range.
  UpgradeLevels withLevel(UpgradeKind kind, int level) {
    final List<int> list = List<int>.of(_levels);
    list[kind.index] = level.clamp(0, maxLevel).toInt();
    return UpgradeLevels._(List<int>.unmodifiable(list));
  }

  /// The sum of all six levels, 0 to 30.
  int get totalLevels => _levels.fold<int>(0, (int sum, int level) => sum + level);

  /// True when every upgrade is at [maxLevel].
  bool get isMaxed => totalLevels == maxLevel * UpgradeKind.values.length;

  @override
  bool operator ==(Object other) {
    if (other is! UpgradeLevels) return false;
    for (int i = 0; i < _levels.length; i++) {
      if (_levels[i] != other._levels[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_levels);

  @override
  String toString() => 'UpgradeLevels($_levels)';
}
