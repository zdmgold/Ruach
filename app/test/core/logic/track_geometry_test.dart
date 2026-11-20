import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/logic/track_geometry.dart';
import 'package:ruach/core/models/track.dart';
import 'package:ruach/core/models/vec2.dart';

import 'test_support.dart';

void main() {
  final TrackGeometry geo = TrackGeometry.of(testTrack());

  test('lap length is close to the ellipse perimeter', () {
    // Ramanujan: pi * (3(a+b) - sqrt((3a+b)(a+3b))) for a=250, b=120.
    expect(geo.length, closeTo(1236, 40));
  });

  test('points on the centreline project to zero lateral offset', () {
    for (double d = 0; d < geo.length; d += 97) {
      final TrackProjection p = geo.project(geo.positionAt(d));
      expect(p.lateral.abs(), lessThan(0.05), reason: 'at $d');
      expect(p.distance, closeTo(d, 0.5), reason: 'at $d');
      expect(p.onTrack, isTrue);
    }
  });

  test('lateral offset is positive to the right of travel', () {
    const double d = 300;
    final Vec2 centre = geo.positionAt(d);
    final Vec2 right = geo.tangentAt(d).perpendicular;
    final TrackProjection onRight = geo.project(centre + right * 5);
    final TrackProjection onLeft = geo.project(centre - right * 5);
    expect(onRight.lateral, closeTo(5, 0.2));
    expect(onLeft.lateral, closeTo(-5, 0.2));
    expect(onRight.onTrack, isTrue);
  });

  test('a point far from the road is off the track', () {
    const double d = 300;
    final Vec2 far = geo.positionAt(d) + geo.tangentAt(d).perpendicular * 20;
    expect(geo.project(far).onTrack, isFalse);
  });

  test('a search hint gives the same answer as a full search', () {
    final Vec2 p = geo.positionAt(500) + geo.tangentAt(500).perpendicular * 3;
    final TrackProjection full = geo.project(p);
    final TrackProjection hinted = geo.project(p, hint: full.index + 3);
    expect(hinted.distance, closeTo(full.distance, 1e-9));
    expect(hinted.lateral, closeTo(full.lateral, 1e-9));
    // A wrong hint far away falls back to the full search.
    final TrackProjection wrong = geo.project(p, hint: (full.index + geo.sampleCount ~/ 2) % geo.sampleCount);
    expect(wrong.distance, closeTo(full.distance, 1e-9));
  });

  test('distances wrap around the lap', () {
    final Vec2 a = geo.positionAt(10);
    final Vec2 b = geo.positionAt(geo.length + 10);
    expect(a.distanceTo(b), lessThan(1e-6));
  });

  test('width is read from the control points', () {
    expect(geo.widthAt(100), closeTo(14, 1e-9));
  });

  test('the road turns right on this clockwise oval', () {
    // Over a quarter lap the heading changes by about +90 degrees (positive
    // is right).
    expect(geo.curvatureAhead(0, 300), greaterThan(0.5));
  });

  test('surface zones override the base surface', () {
    final TrackGeometry zoned = TrackGeometry.of(
      testTrack(
        zones: const <SurfaceZone>[
          SurfaceZone(startFraction: 0.2, endFraction: 0.4, surface: SurfaceType.sand),
        ],
      ),
    );
    expect(zoned.surfaceAt(0.1), SurfaceType.asphalt);
    expect(zoned.surfaceAt(0.2), SurfaceType.sand);
    expect(zoned.surfaceAt(0.39), SurfaceType.sand);
    expect(zoned.surfaceAt(0.4), SurfaceType.asphalt);
  });
}
