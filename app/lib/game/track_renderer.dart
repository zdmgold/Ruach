import 'dart:math' as math;
import 'dart:ui';

import 'package:ruach/core/logic/seeded_rng.dart';
import 'package:ruach/core/logic/track_geometry.dart';
import 'package:ruach/core/models/track.dart';
import 'package:ruach/core/models/vec2.dart';
import 'package:ruach/theme/tokens.dart';

/// Draws a track from its data: ground, road, surface zones, edge lines, lane
/// dashes, the start line, rails, lamps and scenery. The whole track is
/// recorded once into a [Picture] and replayed every frame, so a frame costs
/// one draw call however long the track is. Art is drawn in code; there are no
/// image files.
final class TrackRenderer {
  TrackRenderer(this.track) : geometry = TrackGeometry.of(track) {
    _sample();
  }

  /// Metres between road samples.
  static const double spacing = 3;

  final Track track;
  final TrackGeometry geometry;

  late final List<Vec2> _center;
  late final List<Vec2> _a;
  late final List<Vec2> _b;
  late final List<Vec2> _normal;
  late final Rect _bounds;
  Picture? _picture;
  int _sceneryCount = 0;

  /// Road samples around the lap.
  int get sampleCount => _center.length;

  /// How many scenery objects were placed.
  int get sceneryCount {
    _picture ??= _record();
    return _sceneryCount;
  }

  /// The area the picture covers, in world metres.
  Rect get bounds => _bounds;

  /// Both road edges, for tests and the minimap.
  List<Vec2> get edgeA => List<Vec2>.unmodifiable(_a);
  List<Vec2> get edgeB => List<Vec2>.unmodifiable(_b);

  void _sample() {
    final int n = math.max(24, (geometry.length / spacing).ceil());
    _center = <Vec2>[];
    _a = <Vec2>[];
    _b = <Vec2>[];
    _normal = <Vec2>[];
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;
    for (int i = 0; i < n; i++) {
      final double d = geometry.length * i / n;
      final Vec2 p = geometry.positionAt(d);
      final Vec2 normal = geometry.tangentAt(d).perpendicular;
      final double half = geometry.widthAt(d) / 2;
      _center.add(p);
      _normal.add(normal);
      _a.add(p + normal * half);
      _b.add(p - normal * half);
      for (final Vec2 v in <Vec2>[_a.last, _b.last]) {
        minX = math.min(minX, v.x);
        minY = math.min(minY, v.y);
        maxX = math.max(maxX, v.x);
        maxY = math.max(maxY, v.y);
      }
    }
    const double margin = 80;
    _bounds = Rect.fromLTRB(minX - margin, minY - margin, maxX + margin, maxY + margin);
  }

  /// Draws the track. Call inside the camera transform.
  void paint(Canvas canvas) {
    _picture ??= _record();
    canvas.drawPicture(_picture!);
  }

  void dispose() {
    _picture?.dispose();
    _picture = null;
  }

  static Color colorFor(SurfaceType surface) => switch (surface) {
        SurfaceType.asphalt => WorldColors.trackAsphalt,
        SurfaceType.dirt => WorldColors.trackDirt,
        SurfaceType.sand => WorldColors.trackSand,
        SurfaceType.cobble => WorldColors.trackCobble,
        SurfaceType.stone => WorldColors.trackStone,
        SurfaceType.ford => WorldColors.trackFord,
        SurfaceType.grass => WorldColors.trackGrass,
      };

  Color get groundColor =>
      track.baseSurface == SurfaceType.sand ? WorldColors.groundSand : WorldColors.groundGrass;

  Offset _o(Vec2 v) => Offset(v.x, v.y);

  Path _ring(List<Vec2> points) => Path()..addPolygon(<Offset>[for (final Vec2 v in points) _o(v)], true);

  Picture _record() {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas c = Canvas(recorder, _bounds);
    final int n = _center.length;

    c.drawRect(_bounds, Paint()..color = groundColor);
    _drawScenery(c);

    // Road: the area between the two edge loops.
    final Path road = Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(_ring(_a), Offset.zero)
      ..addPath(_ring(_b), Offset.zero);
    c.drawPath(road, Paint()..color = colorFor(track.baseSurface));

    // Surface zones that differ from the base surface.
    final Map<SurfaceType, Path> zones = <SurfaceType, Path>{};
    for (int i = 0; i < n; i++) {
      final double fraction = i / n;
      final SurfaceType surface = geometry.surfaceAt(fraction);
      if (surface == track.baseSurface) continue;
      final int j = (i + 1) % n;
      (zones[surface] ??= Path()).addPolygon(
        <Offset>[_o(_a[i]), _o(_a[j]), _o(_b[j]), _o(_b[i])],
        true,
      );
    }
    zones.forEach((SurfaceType s, Path p) => c.drawPath(p, Paint()..color = colorFor(s)));

    // Red and white kerbs along both edges: the road reads at a glance.
    final Path red = Path();
    final Path white = Path();
    for (int i = 0; i < n; i++) {
      final int j = (i + 1) % n;
      final Path target = (i ~/ 2).isEven ? red : white;
      for (final List<Vec2> side in <List<Vec2>>[_a, _b]) {
        target
          ..moveTo(side[i].x, side[i].y)
          ..lineTo(side[j].x, side[j].y);
      }
    }
    final Paint kerb = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    c.drawPath(red, kerb..color = WorldColors.kerbRed);
    c.drawPath(white, kerb..color = WorldColors.kerbWhite);

    // Lane dashes on asphalt only.
    if (track.baseSurface == SurfaceType.asphalt) {
      final Path dashes = Path();
      for (int i = 0; i < n; i += 4) {
        final int j = (i + 2) % n;
        dashes
          ..moveTo(_center[i].x, _center[i].y)
          ..lineTo(_center[j].x, _center[j].y);
      }
      c.drawPath(
        dashes,
        Paint()
          ..color = WorldColors.line.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.4,
      );
    }

    _drawRailsAndLamps(c);
    _drawStartLine(c);
    return recorder.endRecording();
  }

  void _drawStartLine(Canvas c) {
    final Vec2 a = _a[0];
    final Vec2 b = _b[0];
    final Vec2 along = (_center[1] - _center[0]).normalized();
    final double width = a.distanceTo(b);
    final int columns = (width / 1).round().clamp(6, 24).toInt();
    final Path light = Path();
    final Path dark = Path();
    for (int row = 0; row < 2; row++) {
      for (int col = 0; col < columns; col++) {
        final Vec2 p0 = a.lerp(b, col / columns) + along * row.toDouble();
        final Vec2 p1 = a.lerp(b, (col + 1) / columns) + along * row.toDouble();
        final Path target = (row + col).isEven ? light : dark;
        target.addPolygon(
          <Offset>[_o(p0), _o(p1), _o(p1 + along), _o(p0 + along)],
          true,
        );
      }
    }
    c.drawPath(light, Paint()..color = WorldColors.line);
    c.drawPath(dark, Paint()..color = WorldColors.lineDark);
  }

  void _drawRailsAndLamps(Canvas c) {
    final int n = _center.length;
    if (track.sceneryTags.contains('guardrails')) {
      final Paint rail = Paint()
        ..color = WorldColors.guardrail
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      c.drawPath(_ring(<Vec2>[for (int i = 0; i < n; i++) _a[i] + _normal[i] * 1.2]), rail);
      c.drawPath(_ring(<Vec2>[for (int i = 0; i < n; i++) _b[i] - _normal[i] * 1.2]), rail);
    }
    if (track.sceneryTags.contains('lamps')) {
      final Paint halo = Paint()..color = WorldColors.lampHalo.withValues(alpha: 0.18);
      final Paint post = Paint()..color = WorldColors.lineDark;
      for (int i = 0; i < n; i += 14) {
        final Vec2 p = _a[i] + _normal[i] * 3;
        c.drawCircle(_o(p), 3, halo);
        c.drawCircle(_o(p), 0.6, post);
      }
    }
  }

  void _drawScenery(Canvas c) {
    final List<String> tags = <String>[
      for (final String t in track.sceneryTags)
        if (_kindOf(t) != null) t,
    ];
    _sceneryCount = 0;
    if (tags.isEmpty) return;
    final SeededRng rng = SeededRng(track.number * 7919 + (track.variant == TrackVariant.now ? 1 : 0))
        .fork('scenery:${track.id}');
    final int n = _center.length;
    for (int i = 0; i < n; i += 2) {
      for (final double side in <double>[1, -1]) {
        if (rng.nextDouble() > 0.55) continue;
        final String tag = tags[rng.nextInt(tags.length)];
        final _Kind kind = _kindOf(tag)!;
        final double half = geometry.widthAt(geometry.length * i / n) / 2;
        final bool water = kind == _Kind.water;
        final double offset = half + rng.nextRange(water ? 14 : 6, water ? 34 : 22);
        final Vec2 p = _center[i] + _normal[i] * (side * offset);
        final double radius = rng.nextRange(1.5, water ? 8 : 3.5);
        final TrackProjection near = geometry.project(p);
        if (near.lateral.abs() < near.halfWidth + radius + 3) continue;
        _paintObject(c, kind, p, radius);
        _sceneryCount++;
      }
    }
  }

  void _paintObject(Canvas c, _Kind kind, Vec2 p, double r) {
    final Offset o = _o(p);
    switch (kind) {
      case _Kind.tree:
        c.drawCircle(o, r, Paint()..color = WorldColors.sceneryTree);
        c.drawCircle(
          o,
          r,
          Paint()
            ..color = WorldColors.sceneryTreeEdge
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.3,
        );
      case _Kind.rock:
        c.drawOval(
          Rect.fromCenter(center: o, width: r * 2, height: r * 1.4),
          Paint()..color = WorldColors.sceneryRock,
        );
      case _Kind.dune:
        c.drawOval(
          Rect.fromCenter(center: o, width: r * 5, height: r * 2.4),
          Paint()..color = WorldColors.trackSand.withValues(alpha: 0.6),
        );
      case _Kind.water:
        c.drawOval(
          Rect.fromCenter(center: o, width: r * 3, height: r * 2),
          Paint()..color = WorldColors.sceneryWater.withValues(alpha: 0.75),
        );
    }
  }

  static _Kind? _kindOf(String tag) => switch (tag) {
        'palms' || 'reeds' || 'pines' || 'oaks' || 'olives' || 'scrub' || 'hills' || 'valley' => _Kind.tree,
        'mountain' || 'ridge' || 'stone_steps' || 'walls' || 'gates' => _Kind.rock,
        'dunes' => _Kind.dune,
        'river' || 'stream' || 'canal' || 'sea_view' || 'tide' => _Kind.water,
        _ => null,
      };
}

enum _Kind { tree, rock, dune, water }
