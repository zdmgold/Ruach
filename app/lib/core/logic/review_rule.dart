import 'package:ruach/core/models/progress.dart';
import 'package:ruach/core/models/race_result.dart';

/// When the store's rating prompt may be requested: once ever, after a podium
/// finish, and never before the player has finished a few races. A poor
/// result never prompts (blueprint section 3).
abstract final class ReviewRule {
  /// Races a player must have finished before the first prompt.
  static const int minRaces = 3;

  /// [progress] is the state after the race has been saved.
  static bool shouldAsk(Progress progress, RaceResult result) {
    if (progress.reviewAsked) return false;
    if (progress.racesFinished < minRaces) return false;
    return result.player.finished && result.playerPosition <= 3;
  }
}
