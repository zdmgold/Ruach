import 'package:ruach/core/models/rival.dart';
import 'package:ruach/core/models/track.dart';
import 'package:ruach/core/models/upgrade.dart';
import 'package:ruach/core/models/vehicle.dart';

/// The seven ways to race (blueprint section 2).
enum RaceMode {
  journey,
  quickRace,
  timeTrial,
  dailyRun,
  weeklyCircuit,
  escapeRun,
  elimination,
}

/// How hard the rivals drive. Journey raises it as the player progresses;
/// other modes let the player choose.
enum Difficulty { easy, normal, hard }

/// Everything needed to run one race. Together with the player's inputs, a
/// config fully decides the result: the same config and the same inputs give
/// the same race (blueprint section 4, determinism).
final class RaceConfig {
  RaceConfig({
    required this.track,
    required this.vehicle,
    required this.mode,
    required this.laps,
    required this.difficulty,
    required this.seed,
    this.rivals = const <Rival>[],
    this.upgrades = UpgradeLevels.none,
  })  : assert(laps >= 1, 'a race has at least one lap'),
        assert(rivals.length <= maxRivals, 'at most $maxRivals rivals');

  /// The player and five rivals share the grid.
  static const int maxRivals = 5;

  final Track track;
  final Vehicle vehicle;
  final RaceMode mode;
  final int laps;
  final Difficulty difficulty;

  /// Seeds every random choice in the race (rival behaviour, wind). The Daily
  /// Run derives it from the date so every player gets the same race.
  final int seed;

  /// The rivals on the grid. Empty for Time Trial.
  final List<Rival> rivals;

  /// The player's upgrade levels, applied to the player's vehicle.
  final UpgradeLevels upgrades;

  /// Cars on the grid, including the player.
  int get fieldSize => rivals.length + 1;
}
