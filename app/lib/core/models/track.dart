import 'package:ruach/core/models/vec2.dart';

/// The four sets of tracks (blueprint section 2).
enum Era {
  chariotAge,
  kingdomAndExile,
  gospelRoads,
  today,
}

/// A biblical track exists as an original (`then`) and, for tracks 1 to 12,
/// as a modern re-skin of the same geometry (`now`).
enum TrackVariant { then, now }

/// What the ground is made of. Each surface has its own grip and drag, which
/// `surface_model.dart` (batch p2b) defines.
enum SurfaceType { asphalt, dirt, sand, cobble, stone, ford, grass }

/// A stretch of the lap with a surface that differs from the track's base
/// surface. Positions are fractions of the lap from the start line, 0 to 1.
final class SurfaceZone {
  const SurfaceZone({
    required this.startFraction,
    required this.endFraction,
    required this.surface,
  });

  final double startFraction;
  final double endFraction;
  final SurfaceType surface;
}

/// A race track as data. A track is a closed loop: a centreline given by
/// control points that the physics samples as a smooth spline, a width at each
/// control point, surface zones, and checkpoints. Adding a track is adding one
/// catalog entry (batch p2g), never new code.
///
/// Two tracks are equal when their [id] is equal.
final class Track {
  const Track({
    required this.id,
    required this.number,
    required this.era,
    required this.variant,
    required this.centerline,
    required this.widths,
    required this.checkpointFractions,
    required this.parLapSeconds,
    this.baseSurface = SurfaceType.asphalt,
    this.surfaceZones = const <SurfaceZone>[],
    this.pursuit = false,
    this.sceneryTags = const <String>[],
  });

  /// Unique and stable, for example `nile_banks` or `nile_banks_now`. Saved
  /// progress refers to tracks by this id.
  final String id;

  /// 1 to 16, in Journey order.
  final int number;

  final Era era;
  final TrackVariant variant;

  /// Control points of the closed centreline, in metres, in driving order.
  /// The last point connects back to the first.
  final List<Vec2> centerline;

  /// Road width in metres at each control point.
  final List<double> widths;

  /// Where the checkpoints are, as increasing fractions of the lap strictly
  /// between 0 and 1. The start and finish line is at 0.
  final List<double> checkpointFractions;

  /// A good lap time in seconds, used to scale rivals and to set star targets.
  final double parLapSeconds;

  final SurfaceType baseSurface;
  final List<SurfaceZone> surfaceZones;

  /// True for the two Exodus-style tracks and the Escape Run, where an abstract
  /// wall of dust or tide follows the field. It is scenery only: there is no
  /// combat and no figure.
  final bool pursuit;

  /// Names of scenery sets the renderer draws, for example `reeds` or `palms`.
  final List<String> sceneryTags;

  /// The era a track number belongs to.
  static Era eraForNumber(int number) {
    if (number <= 4) return Era.chariotAge;
    if (number <= 8) return Era.kingdomAndExile;
    if (number <= 12) return Era.gospelRoads;
    return Era.today;
  }

  /// Problems found with this track's data. An empty list means it is valid.
  /// The catalog test (batch p2g) fails if any track returns a problem.
  List<String> validate() {
    final List<String> problems = <String>[];

    if (id.isEmpty) problems.add('id is empty');
    if (number < 1 || number > 16) {
      problems.add('number $number is outside 1 to 16');
    } else if (eraForNumber(number) != era) {
      problems.add('number $number does not belong to era ${era.name}');
    }
    if (variant == TrackVariant.now && era == Era.today) {
      problems.add('Today tracks have no modern variant');
    }

    if (centerline.length < 8) {
      problems.add('centerline has ${centerline.length} points, needs at least 8');
    }
    if (widths.length != centerline.length) {
      problems.add('widths has ${widths.length} entries for ${centerline.length} points');
    }
    for (int i = 0; i < widths.length; i++) {
      if (!(widths[i] > 0)) problems.add('width at point $i is not positive');
    }
    for (int i = 0; i < centerline.length; i++) {
      final Vec2 next = centerline[(i + 1) % centerline.length];
      if (centerline[i].distanceTo(next) == 0) {
        problems.add('points $i and ${(i + 1) % centerline.length} are identical');
      }
    }

    final List<SurfaceZone> zones = List<SurfaceZone>.of(surfaceZones)
      ..sort((SurfaceZone a, SurfaceZone b) => a.startFraction.compareTo(b.startFraction));
    for (int i = 0; i < zones.length; i++) {
      final SurfaceZone zone = zones[i];
      if (!(zone.startFraction >= 0 && zone.startFraction < zone.endFraction && zone.endFraction <= 1)) {
        problems.add('surface zone $i has an invalid range');
      }
      if (i > 0 && zones[i - 1].endFraction > zone.startFraction) {
        problems.add('surface zones ${i - 1} and $i overlap');
      }
    }

    if (checkpointFractions.length < 3) {
      problems.add('needs at least 3 checkpoints, has ${checkpointFractions.length}');
    }
    for (int i = 0; i < checkpointFractions.length; i++) {
      final double f = checkpointFractions[i];
      if (!(f > 0 && f < 1)) problems.add('checkpoint $i is outside 0 to 1');
      if (i > 0 && !(f > checkpointFractions[i - 1])) {
        problems.add('checkpoint $i is not after checkpoint ${i - 1}');
      }
    }

    if (!(parLapSeconds > 0)) problems.add('parLapSeconds is not positive');

    return problems;
  }

  @override
  bool operator ==(Object other) => other is Track && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Track($id)';
}
