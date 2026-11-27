import 'dart:math' as math;

import 'package:ruach/core/catalog/vehicles.dart';
import 'package:ruach/core/logic/catalog_ids.dart';
import 'package:ruach/core/logic/par_estimator.dart';
import 'package:ruach/core/models/track.dart';
import 'package:ruach/core/models/vec2.dart';
import 'package:ruach/core/models/vehicle.dart';

/// One sine wave added to a track's outline: [k] bumps around the loop of
/// relative size [amplitude], starting at [phase] radians.
final class Harmonic {
  const Harmonic(this.k, this.amplitude, this.phase);

  final int k;
  final double amplitude;
  final double phase;
}

/// The recipe for a track's outline and surfaces. The outline is a closed
/// loop `r(angle) = 1 + sum of harmonics`, stretched to [radiusX] by [radiusY]
/// metres; because it is star-shaped it can never cross itself. The recipe is
/// plain data, and the catalog turns it into a [Track].
final class TrackSpec {
  const TrackSpec({
    required this.id,
    required this.number,
    required this.radiusX,
    required this.radiusY,
    required this.harmonics,
    required this.width,
    this.widthWobble = 0.08,
    this.baseSurface = SurfaceType.asphalt,
    this.zones = const <SurfaceZone>[],
    this.pursuit = false,
    this.scenery = const <String>[],
  });

  final String id;
  final int number;
  final double radiusX;
  final double radiusY;
  final List<Harmonic> harmonics;

  /// Road width in metres.
  final double width;

  /// How much the width varies around the lap, as a share of [width].
  final double widthWobble;

  final SurfaceType baseSurface;
  final List<SurfaceZone> zones;
  final bool pursuit;
  final List<String> scenery;
}

/// The 16 tracks and 12 Now variants (blueprint section 2).
abstract final class TrackCatalog {
  static const int pointCount = 48;

  static const List<TrackSpec> specs = <TrackSpec>[
    TrackSpec(
      id: 'nile_banks', number: 1, radiusX: 215, radiusY: 125, width: 19, widthWobble: 0.05,
      harmonics: <Harmonic>[Harmonic(2, 0.04, 0.3), Harmonic(3, 0.02, 1.1)],
      baseSurface: SurfaceType.dirt, scenery: <String>['reeds', 'palms', 'river'],
    ),
    TrackSpec(
      id: 'red_sea_crossing', number: 2, radiusX: 300, radiusY: 115, width: 18, widthWobble: 0.05,
      harmonics: <Harmonic>[Harmonic(2, 0.02, 1.0), Harmonic(3, 0.015, 0.4)],
      baseSurface: SurfaceType.sand, pursuit: true,
      zones: <SurfaceZone>[SurfaceZone(startFraction: 0.42, endFraction: 0.52, surface: SurfaceType.ford)],
      scenery: <String>['tide', 'dust_wall', 'dunes'],
    ),
    TrackSpec(
      id: 'sinai_wilderness', number: 3, radiusX: 250, radiusY: 170, width: 18, widthWobble: 0.1,
      harmonics: <Harmonic>[Harmonic(3, 0.14, 0.6), Harmonic(6, 0.02, 2.0)],
      baseSurface: SurfaceType.sand,
      zones: <SurfaceZone>[SurfaceZone(startFraction: 0.1, endFraction: 0.3, surface: SurfaceType.dirt)],
      scenery: <String>['mountain', 'dunes', 'scrub'],
    ),
    TrackSpec(
      id: 'jordan_crossing', number: 4, radiusX: 240, radiusY: 150, width: 16, widthWobble: 0.1,
      harmonics: <Harmonic>[Harmonic(2, 0.13, 2.2), Harmonic(1, 0.07, 0.9)],
      baseSurface: SurfaceType.dirt,
      zones: <SurfaceZone>[
        SurfaceZone(startFraction: 0.22, endFraction: 0.3, surface: SurfaceType.ford),
        SurfaceZone(startFraction: 0.66, endFraction: 0.73, surface: SurfaceType.ford),
      ],
      scenery: <String>['river', 'reeds', 'hills'],
    ),
    TrackSpec(
      id: 'valley_of_elah', number: 5, radiusX: 235, radiusY: 150, width: 12, widthWobble: 0.12,
      harmonics: <Harmonic>[Harmonic(4, 0.075, 0.4), Harmonic(2, 0.06, 1.8)],
      baseSurface: SurfaceType.dirt, scenery: <String>['valley', 'oaks', 'stream'],
    ),
    TrackSpec(
      id: 'carmel_ridge', number: 6, radiusX: 250, radiusY: 160, width: 14, widthWobble: 0.15,
      harmonics: <Harmonic>[Harmonic(5, 0.07, 1.4), Harmonic(2, 0.04, 0.3)],
      baseSurface: SurfaceType.dirt,
      zones: <SurfaceZone>[SurfaceZone(startFraction: 0.55, endFraction: 0.7, surface: SurfaceType.stone)],
      scenery: <String>['ridge', 'pines', 'sea_view'],
    ),
    TrackSpec(
      id: 'jerusalem_ascent', number: 7, radiusX: 240, radiusY: 165, width: 13, widthWobble: 0.2,
      harmonics: <Harmonic>[Harmonic(6, 0.05, 0.9), Harmonic(3, 0.05, 2.6), Harmonic(2, 0.04, 1.2)],
      baseSurface: SurfaceType.stone,
      zones: <SurfaceZone>[SurfaceZone(startFraction: 0.3, endFraction: 0.5, surface: SurfaceType.cobble)],
      scenery: <String>['stone_steps', 'walls', 'olives'],
    ),
    TrackSpec(
      id: 'babylon_gates', number: 8, radiusX: 250, radiusY: 170, width: 14, widthWobble: 0.25,
      harmonics: <Harmonic>[Harmonic(4, 0.11, 2.0), Harmonic(8, 0.018, 0.6)],
      baseSurface: SurfaceType.stone, pursuit: true,
      zones: <SurfaceZone>[SurfaceZone(startFraction: 0.75, endFraction: 0.9, surface: SurfaceType.dirt)],
      scenery: <String>['gates', 'canal', 'dust_wall'],
    ),
    TrackSpec(
      id: 'galilee_shore', number: 9, radiusX: 260, radiusY: 150, width: 16, widthWobble: 0.08,
      harmonics: <Harmonic>[Harmonic(2, 0.10, 0.1), Harmonic(1, 0.09, 2.3)],
      baseSurface: SurfaceType.dirt,
      zones: <SurfaceZone>[SurfaceZone(startFraction: 0.5, endFraction: 0.65, surface: SurfaceType.sand)],
      scenery: <String>['lake', 'boats', 'reeds'],
    ),
    TrackSpec(
      id: 'damascus_road', number: 10, radiusX: 260, radiusY: 170, width: 15, widthWobble: 0.15,
      harmonics: <Harmonic>[Harmonic(3, 0.12, 1.2), Harmonic(2, 0.05, 0.4)],
      baseSurface: SurfaceType.cobble,
      zones: <SurfaceZone>[SurfaceZone(startFraction: 0.6, endFraction: 0.78, surface: SurfaceType.dirt)],
      scenery: <String>['orchard', 'walls', 'caravan_road'],
    ),
    TrackSpec(
      id: 'antioch_way', number: 11, radiusX: 265, radiusY: 165, width: 14, widthWobble: 0.2,
      harmonics: <Harmonic>[Harmonic(5, 0.06, 2.5), Harmonic(3, 0.05, 1.0)],
      baseSurface: SurfaceType.cobble,
      zones: <SurfaceZone>[
        SurfaceZone(startFraction: 0.2, endFraction: 0.32, surface: SurfaceType.dirt),
        SurfaceZone(startFraction: 0.62, endFraction: 0.72, surface: SurfaceType.sand),
      ],
      scenery: <String>['market', 'columns', 'harbour'],
    ),
    TrackSpec(
      id: 'appian_way', number: 12, radiusX: 310, radiusY: 135, width: 17, widthWobble: 0.05,
      harmonics: <Harmonic>[Harmonic(2, 0.04, 0.7), Harmonic(4, 0.015, 0.9)],
      baseSurface: SurfaceType.cobble, scenery: <String>['cypress', 'milestones', 'tombs'],
    ),
    TrackSpec(
      id: 'desert_pass', number: 13, radiusX: 320, radiusY: 190, width: 15, widthWobble: 0.15,
      harmonics: <Harmonic>[Harmonic(4, 0.10, 0.5), Harmonic(2, 0.06, 2.1)],
      baseSurface: SurfaceType.asphalt,
      zones: <SurfaceZone>[SurfaceZone(startFraction: 0.35, endFraction: 0.48, surface: SurfaceType.sand)],
      scenery: <String>['mesas', 'cacti', 'guardrails'],
    ),
    TrackSpec(
      id: 'lakeside_drive', number: 14, radiusX: 330, radiusY: 190, width: 16, widthWobble: 0.08,
      harmonics: <Harmonic>[Harmonic(2, 0.11, 1.6), Harmonic(1, 0.06, 0.2)],
      baseSurface: SurfaceType.asphalt, scenery: <String>['lake', 'pines', 'lamps'],
    ),
    TrackSpec(
      id: 'coast_highway', number: 15, radiusX: 340, radiusY: 200, width: 15, widthWobble: 0.18,
      harmonics: <Harmonic>[Harmonic(3, 0.10, 0.3), Harmonic(2, 0.10, 1.5)],
      baseSurface: SurfaceType.asphalt,
      zones: <SurfaceZone>[SurfaceZone(startFraction: 0.8, endFraction: 0.9, surface: SurfaceType.sand)],
      scenery: <String>['sea', 'palms', 'guardrails'],
    ),
    TrackSpec(
      id: 'highland_switchbacks', number: 16, radiusX: 345, radiusY: 215, width: 13, widthWobble: 0.2,
      harmonics: <Harmonic>[Harmonic(5, 0.075, 1.9), Harmonic(3, 0.07, 0.8), Harmonic(2, 0.05, 2.4)],
      baseSurface: SurfaceType.asphalt,
      zones: <SurfaceZone>[SurfaceZone(startFraction: 0.5, endFraction: 0.6, surface: SurfaceType.dirt)],
      scenery: <String>['peaks', 'pines', 'guardrails'],
    ),
  ];

  static List<Track>? _cache;

  /// All 28 tracks: 16 Then (or Today) tracks, then the 12 Now variants.
  static List<Track> get all => _cache ??= <Track>[
        for (final TrackSpec s in specs) _build(s, TrackVariant.then),
        for (final TrackSpec s in specs.take(12)) _build(s, TrackVariant.now),
      ];

  /// The track with [id], or null.
  static Track? byId(String id) {
    for (final Track t in all) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// The Journey set (tracks 1 to 16, Then versions).
  static List<Track> get journey => all.take(16).toList();

  static Track _build(TrackSpec s, TrackVariant variant) {
    final bool now = variant == TrackVariant.now;
    final List<Vec2> points = <Vec2>[];
    final List<double> widths = <double>[];
    for (int i = 0; i < pointCount; i++) {
      final double a = 2 * math.pi * i / pointCount;
      double r = 1;
      for (final Harmonic h in s.harmonics) {
        r += h.amplitude * math.cos(h.k * a + h.phase);
      }
      points.add(Vec2(s.radiusX * r * math.cos(a), s.radiusY * r * math.sin(a)));
      final double wobble = 1 + s.widthWobble * math.cos(2 * a + s.number);
      widths.add(s.width * (now ? 1.1 : 1) * wobble);
    }
    final SurfaceType base = now ? SurfaceType.asphalt : s.baseSurface;
    final List<SurfaceZone> zones = now ? const <SurfaceZone>[] : s.zones;
    final String id = now ? TrackIds.nowVariantOf(s.id) : s.id;
    final List<String> scenery = now
        ? <String>[...s.scenery.where((String t) => t != 'dust_wall'), 'guardrails', 'lamps']
        : s.scenery;

    Track build(double par) => Track(
          id: id,
          number: s.number,
          era: Track.eraForNumber(s.number),
          variant: variant,
          centerline: points,
          widths: widths,
          checkpointFractions: const <double>[0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875],
          parLapSeconds: par,
          baseSurface: base,
          surfaceZones: zones,
          pursuit: s.pursuit && !now,
          sceneryTags: scenery,
        );

    final Track draft = build(60);
    final Vehicle reference = VehicleCatalog.journeyDefault(draft);
    final double par = ParEstimator.lapSeconds(draft, reference);
    return build(double.parse(par.toStringAsFixed(1)));
  }
}
