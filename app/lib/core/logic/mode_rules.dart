import 'dart:math' as math;

import 'package:ruach/core/logic/catalog_ids.dart';
import 'package:ruach/core/logic/numeric.dart';
import 'package:ruach/core/logic/race_rules.dart';
import 'package:ruach/core/logic/seeded_rng.dart';
import 'package:ruach/core/models/progress.dart';
import 'package:ruach/core/models/race_config.dart';
import 'package:ruach/core/models/rival.dart';
import 'package:ruach/core/models/track.dart';
import 'package:ruach/core/models/upgrade.dart';
import 'package:ruach/core/models/vehicle.dart';

/// What is open to the player, decided only from their [Progress].
abstract final class Unlocks {
  /// Track and Now-variant access. Journey is sequential: track n opens when
  /// track n - 1 has a star (tracks 13 to 16 open after Appian Way, the same
  /// rule). A Now variant opens once its Then track is cleared.
  static bool track(String trackId, Progress progress) {
    final int n = TrackIds.numberOf(trackId);
    if (n == 0) return false;
    if (TrackIds.isNowVariant(trackId)) {
      return n <= 12 && progress.isCleared(TrackIds.baseOf(trackId));
    }
    if (n == 1) return true;
    return progress.isCleared(TrackIds.journey[n - 2]);
  }

  /// Chariots are open from the start. The Road Cart and the modern vehicles
  /// open when Galilee Shore (track 9) opens.
  static bool vehicle(String vehicleId, Progress progress) {
    if (vehicleId == VehicleIds.lightChariot || vehicleId == VehicleIds.heavyChariot) {
      return VehicleIds.all.contains(vehicleId);
    }
    if (!VehicleIds.all.contains(vehicleId)) return false;
    return track(TrackIds.journey[8], progress);
  }

  /// Mode access (blueprint section 2).
  static bool mode(RaceMode mode, Progress progress) => switch (mode) {
        RaceMode.journey => true,
        RaceMode.dailyRun => true,
        RaceMode.quickRace => progress.isCleared(TrackIds.journey[0]),
        RaceMode.timeTrial => progress.isCleared(TrackIds.journey[0]),
        RaceMode.weeklyCircuit =>
          progress.dailyRuns.values.any((DailyRunRecord r) => r.completed),
        RaceMode.escapeRun => progress.isCleared(TrackIds.journey[1]),
        RaceMode.elimination => progress.isCleared(TrackIds.journey[4]),
      };
}

/// Builds the [RaceConfig] for each mode.
abstract final class ModeRules {
  static const int defaultLaps = 3;

  /// Elimination: six cars, one dropped per lap, so five laps leave one.
  static const int eliminationLaps = RaceConfig.maxRivals;

  /// Escape Run has no lap limit; this is simply larger than anyone can reach.
  static const int escapeLaps = 1000;

  /// Journey difficulty by track number: forgiving at first, hardest at the
  /// end.
  static Difficulty journeyDifficulty(int trackNumber) {
    if (trackNumber <= 3) return Difficulty.easy;
    if (trackNumber <= 12) return Difficulty.normal;
    return Difficulty.hard;
  }

  /// Rival strength rises with the track number: about 0.25 on the first
  /// track to 0.85 on the last, with each rival's own skill shifting it a
  /// little.
  static double skillFor(Rival rival, int trackNumber) {
    final double ramp = 0.25 + 0.6 * (math.max(1, trackNumber) - 1) / 15;
    return clampDouble(ramp + (rival.skill - 0.5) * 0.4, 0.05, 0.98);
  }

  /// Chooses [count] rivals from [roster] (a seeded shuffle) and scales their
  /// skill for the track.
  static List<Rival> pickRivals(
    List<Rival> roster,
    int trackNumber,
    int seed, {
    int count = RaceConfig.maxRivals,
  }) {
    final List<Rival> pool = List<Rival>.of(roster);
    final SeededRng rng = SeededRng(seed).fork('roster');
    for (int i = pool.length - 1; i > 0; i--) {
      final int j = rng.nextInt(i + 1);
      final Rival tmp = pool[i];
      pool[i] = pool[j];
      pool[j] = tmp;
    }
    return <Rival>[
      for (final Rival r in pool.take(math.min(count, pool.length)))
        Rival(
          id: r.id,
          name: r.name,
          team: r.team,
          skill: skillFor(r, trackNumber),
          aggression: r.aggression,
          consistency: r.consistency,
        ),
    ];
  }

  /// The race for [mode]. [difficulty] is used by Quick Race and Daily/Weekly
  /// races; Journey sets its own, Time Trial and Escape Run have no rivals.
  static RaceConfig build({
    required RaceMode mode,
    required Track track,
    required Vehicle vehicle,
    required List<Rival> roster,
    required int seed,
    Difficulty difficulty = Difficulty.normal,
    UpgradeLevels upgrades = UpgradeLevels.none,
    int? laps,
  }) {
    switch (mode) {
      case RaceMode.journey:
        return RaceConfig(
          track: track,
          vehicle: vehicle,
          mode: mode,
          laps: laps ?? defaultLaps,
          difficulty: journeyDifficulty(track.number),
          seed: seed,
          rivals: pickRivals(roster, track.number, seed),
          upgrades: upgrades,
        );
      case RaceMode.quickRace:
      case RaceMode.dailyRun:
      case RaceMode.weeklyCircuit:
        return RaceConfig(
          track: track,
          vehicle: vehicle,
          mode: mode,
          laps: laps ?? defaultLaps,
          difficulty: difficulty,
          seed: seed,
          rivals: pickRivals(roster, track.number, seed),
          upgrades: upgrades,
        );
      case RaceMode.timeTrial:
        return RaceConfig(
          track: track,
          vehicle: vehicle,
          mode: mode,
          laps: laps ?? defaultLaps,
          difficulty: Difficulty.normal,
          seed: seed,
          upgrades: upgrades,
        );
      case RaceMode.escapeRun:
        return RaceConfig(
          track: track,
          vehicle: vehicle,
          mode: mode,
          laps: escapeLaps,
          difficulty: Difficulty.normal,
          seed: seed,
          upgrades: upgrades,
        );
      case RaceMode.elimination:
        return RaceConfig(
          track: track,
          vehicle: vehicle,
          mode: mode,
          laps: eliminationLaps,
          difficulty: difficulty,
          seed: seed,
          rivals: pickRivals(roster, track.number, seed),
          upgrades: upgrades,
        );
    }
  }
}

/// Elimination: each time the leader completes a lap the car in last place is
/// dropped. Call [update] after every race step. The last car standing wins;
/// if the player is dropped the race ends.
final class EliminationRule {
  int _dropped = 0;

  /// Cars dropped so far.
  int get dropped => _dropped;

  void update(RaceSimulation race) {
    final List<RaceCar> active = race.cars
        .where((RaceCar c) => !c.eliminated && !c.finished)
        .toList();
    if (active.isEmpty) return;
    int leaderLaps = 0;
    for (final RaceCar c in race.cars) {
      if (!c.eliminated && c.tracker.lap > leaderLaps) leaderLaps = c.tracker.lap;
    }
    while (_dropped < leaderLaps && active.length > 1) {
      RaceCar last = active.first;
      for (final RaceCar c in active) {
        if (c.progress < last.progress) last = c;
      }
      active.remove(last);
      race.eliminate(last);
      _dropped++;
    }
    if (active.length == 1 && race.cars.length > 1 && _dropped > 0) {
      final RaceCar survivor = active.first;
      survivor.tracker.forceFinish(race.elapsedSeconds);
      if (survivor.isPlayer) race.endRace();
    }
  }
}

/// Escape Run: an abstract wall of dust rises behind the player and speeds
/// up. The run ends when it catches the player; the score is the distance
/// covered. No combat, no figures (blueprint section 2).
final class EscapeRun {
  EscapeRun({this.startGap = 60}) : _gap = startGap;

  /// Wall speed at the start, in m/s, and how much it gains each second, up to
  /// a cap. A player at full speed pulls away at first and is caught later
  /// unless they drive well.
  static const double startWallSpeed = 24;
  static const double wallAcceleration = 0.12;
  static const double maxWallSpeed = 52;

  final double startGap;
  double _gap;
  int _ticks = 0;

  /// Metres between the wall and the player.
  double get gap => _gap;

  bool get caught => _gap <= 0;

  /// 0 when the wall is far, 1 when it is at the player's bumper. Drives the
  /// warning effects.
  double get danger => clampDouble(1 - _gap / 60, 0, 1);

  double get wallSpeed => math.min(
        maxWallSpeed,
        startWallSpeed + wallAcceleration * _ticks * RaceSimulation.dt,
      );

  /// Advances one race step given the player's forward speed.
  void step(double playerSpeed) {
    if (caught) return;
    _gap += (playerSpeed - wallSpeed) * RaceSimulation.dt;
    _ticks++;
  }

  /// Ends the race if the wall has caught the player.
  void apply(RaceSimulation race) {
    step(race.player.state.forwardSpeed);
    if (caught) race.endRace();
  }
}
