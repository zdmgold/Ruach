import 'package:ruach/core/models/progress.dart';
import 'package:ruach/core/models/race_config.dart';

/// Turns a finished race into stars and Gifts (blueprint section 2).
///
/// Position races (Journey, Quick Race, Daily Run, Weekly Circuit,
/// Elimination): 1 star for a top-four finish, 2 for a top-two finish, 3 for a
/// win. Time Trial: stars for lap time against the track's par. Escape Run:
/// stars for distance. A car that did not finish earns nothing.
abstract final class StarRules {
  /// Escape Run distances for 1, 2 and 3 stars, in metres.
  static const List<double> escapeMetres = <double>[1000, 3000, 6000];

  /// Time Trial: the best lap must be within this share of the par lap time
  /// for 1, 2 and 3 stars.
  static const List<double> timeTrialPar = <double>[1.15, 1.05, 1.0];

  /// Stars for a position finish.
  static int forPosition(int position, {required bool finished}) {
    if (!finished) return 0;
    if (position == 1) return 3;
    if (position <= 2) return 2;
    if (position <= 4) return 1;
    return 0;
  }

  /// Stars for a Time Trial from the best lap and the track's par lap.
  static int forTimeTrial(double bestLapSeconds, double parLapSeconds) {
    if (bestLapSeconds <= 0 || parLapSeconds <= 0) return 0;
    int stars = 0;
    for (int i = 0; i < timeTrialPar.length; i++) {
      if (bestLapSeconds <= parLapSeconds * timeTrialPar[i]) stars = i + 1;
    }
    return stars;
  }

  /// Stars for an Escape Run from the distance covered.
  static int forEscape(double metres) {
    int stars = 0;
    for (int i = 0; i < escapeMetres.length; i++) {
      if (metres >= escapeMetres[i]) stars = i + 1;
    }
    return stars;
  }

  /// The key stars are stored under in [Progress.stars]. Time Trial and
  /// Escape Run keep their own stars so each track can be mastered in every
  /// way.
  static String starKey(RaceMode mode, String trackId) => switch (mode) {
        RaceMode.timeTrial => 'tt:$trackId',
        RaceMode.escapeRun => 'escape:$trackId',
        _ => trackId,
      };

  /// Gifts earned by raising a best from [previousBest] to [newStars].
  static int giftsFor(int previousBest, int newStars) =>
      newStars > previousBest ? newStars - previousBest : 0;

  /// The progress after earning [stars] under [key]: the best is kept and
  /// only an improvement earns Gifts.
  static Progress award(Progress progress, String key, int stars) {
    final int previous = progress.starsOn(key);
    final int clamped = stars < 0 ? 0 : (stars > 3 ? 3 : stars);
    if (clamped <= previous) return progress;
    return progress.copyWith(
      stars: <String, int>{...progress.stars, key: clamped},
      giftsEarned: progress.giftsEarned + giftsFor(previous, clamped),
    );
  }
}
