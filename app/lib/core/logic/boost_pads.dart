import 'dart:math' as math;

import 'package:ruach/core/logic/seeded_rng.dart';
import 'package:ruach/core/logic/track_geometry.dart';
import 'package:ruach/core/models/track.dart';

/// One boost pad on the road: a short strip that gives any car driving over
/// it a burst of speed. [distance] is metres from the start line along the
/// lap; [lateral] is metres from the centreline, positive to the right.
final class BoostPad {
  const BoostPad({required this.distance, required this.lateral});

  final double distance;
  final double lateral;
}

/// Where the boost pads are. They are worked out from the track alone, so
/// every race on a track has the same ones.
abstract final class BoostPads {
  /// Length of a pad along the road, in metres.
  static const double length = 7;

  /// How far to the side of a pad's middle still counts as on it, in metres.
  static const double reach = 2.2;

  /// Seconds of boost a pad gives.
  static const double boostSeconds = 1.6;

  /// A pad on straight road, spread round the lap and away from the start.
  static List<BoostPad> forTrack(Track track, TrackGeometry geometry) {
    final double lap = geometry.length;
    final int count = math.max(3, math.min(9, (lap / 220).round()));
    final SeededRng rng = SeededRng(track.number * 97 + (track.variant == TrackVariant.now ? 1 : 0))
        .fork('pads:${track.id}');
    final double segment = lap / count;
    final List<BoostPad> pads = <BoostPad>[];
    for (int i = 0; i < count; i++) {
      double d = segment * (i + 0.5) + rng.nextRange(-0.2, 0.2) * segment;
      for (int k = 0; k < 10; k++) {
        final bool nearStart = d % lap < 30 || d % lap > lap - 30;
        if (!nearStart && geometry.curvatureAhead(d % lap, 30).abs() < 0.08) break;
        d += 12;
      }
      d = d % lap;
      final double half = geometry.widthAt(d) / 2;
      final double lane = (rng.nextInt(3) - 1) * 0.5;
      pads.add(BoostPad(distance: d, lateral: lane * half));
    }
    return List<BoostPad>.unmodifiable(pads);
  }

  /// Whether a car at [distance] along the lap and [lateral] from the
  /// centreline is on [pad]. [lap] is the length of the lap.
  static bool hit(BoostPad pad, double distance, double lateral, double lap) {
    double along = (distance - pad.distance).abs();
    if (along > lap / 2) along = lap - along;
    return along <= length / 2 + 1 && (lateral - pad.lateral).abs() <= reach;
  }
}
