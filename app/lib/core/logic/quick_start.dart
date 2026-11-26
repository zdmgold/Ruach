import 'package:ruach/core/logic/catalog_ids.dart';
import 'package:ruach/core/models/progress.dart';

/// Which race to open with: the app starts racing at once, so the choice has
/// to be made without asking.
abstract final class QuickStart {
  /// The first Journey track without a star, so each launch carries on where
  /// the player left off; once all are cleared, the tracks come round in turn.
  static String nextTrack(Progress progress) {
    for (final String id in TrackIds.journey) {
      if (!progress.isCleared(id)) return id;
    }
    return TrackIds.journey[progress.racesFinished % TrackIds.journey.length];
  }
}
