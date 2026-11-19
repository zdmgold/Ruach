import 'package:ruach/core/models/race_config.dart';

/// How one car finished a race.
final class RacerStanding {
  const RacerStanding({
    required this.racerId,
    required this.isPlayer,
    required this.position,
    required this.finished,
    required this.totalTime,
    required this.lapTimes,
  });

  /// The rival's id, or `player`.
  final String racerId;

  final bool isPlayer;

  /// Finishing position, 1 for the winner.
  final int position;

  /// False for a car that did not complete the race (for example one dropped
  /// in Elimination).
  final bool finished;

  /// Time of the whole race for a finisher.
  final Duration totalTime;

  /// One entry per completed lap.
  final List<Duration> lapTimes;

  /// The fastest completed lap, or null if no lap was completed.
  Duration? get bestLap {
    if (lapTimes.isEmpty) return null;
    Duration best = lapTimes.first;
    for (final Duration lap in lapTimes) {
      if (lap < best) best = lap;
    }
    return best;
  }
}

/// The outcome of one race. Stars are decided by the star rules (batch p2c)
/// and stored here so the result is complete on its own.
final class RaceResult {
  RaceResult({
    required this.trackId,
    required this.mode,
    required this.seed,
    required this.standings,
    required this.stars,
    required this.cleanDrivingScore,
  })  : assert(standings.isNotEmpty, 'a race has at least one car'),
        assert(
          standings.where((RacerStanding s) => s.isPlayer).length == 1,
          'exactly one car is the player',
        ),
        assert(stars >= 0 && stars <= 3, 'stars are 0 to 3'),
        assert(
          cleanDrivingScore >= 0 && cleanDrivingScore <= 1,
          'the clean-driving score is 0 to 1',
        );

  final String trackId;
  final RaceMode mode;
  final int seed;

  /// Every car, in any order. Use [RacerStanding.position] to rank them.
  final List<RacerStanding> standings;

  /// 0 to 3.
  final int stars;

  /// Share of the race the player drove cleanly, 0 to 1.
  final double cleanDrivingScore;

  /// The player's standing.
  RacerStanding get player =>
      standings.firstWhere((RacerStanding s) => s.isPlayer);

  int get playerPosition => player.position;

  bool get playerWon => player.finished && player.position == 1;
}
