/// One step that brings saved progress JSON from version `n` to `n + 1`.
typedef MigrationStep = Map<String, Object?> Function(Map<String, Object?> json);

/// The result of running migrations.
final class MigrationResult {
  const MigrationResult.ok(this.json) : ok = true;

  const MigrationResult.failed() : ok = false, json = const <String, Object?>{};

  final bool ok;
  final Map<String, Object?> json;
}

/// Brings saved progress up to the current schema, one version at a time.
///
/// Add a step for version `n` under key `n` when the schema moves from `n` to
/// `n + 1`. Steps never throw for odd data; they fix what they can.
abstract final class Migrations {
  /// The steps the app ships with. Schema 1 is the first version, so there
  /// are none yet.
  static const Map<int, MigrationStep> steps = <int, MigrationStep>{};

  /// Runs every step from [from] up to [to]. Fails if a step is missing or
  /// throws, so the caller can fall back to the backup.
  static MigrationResult migrate(
    Map<String, Object?> json, {
    required int from,
    required int to,
    Map<int, MigrationStep> steps = Migrations.steps,
  }) {
    if (from < 1 || from > to) return const MigrationResult.failed();
    Map<String, Object?> current = json;
    for (int version = from; version < to; version++) {
      final MigrationStep? step = steps[version];
      if (step == null) return const MigrationResult.failed();
      try {
        current = Map<String, Object?>.of(step(current));
      } on Object {
        return const MigrationResult.failed();
      }
      current['schemaVersion'] = version + 1;
    }
    return MigrationResult.ok(current);
  }
}
