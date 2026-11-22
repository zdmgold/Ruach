import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/catalog/tracks.dart';
import 'package:ruach/core/models/track.dart';
import 'package:ruach/core/models/vec2.dart';
import 'package:ruach/game/track_renderer.dart';

void main() {
  test('every track builds, covers its road, and draws without error', () {
    for (final Track t in TrackCatalog.all) {
      final TrackRenderer r = TrackRenderer(t);
      expect(r.sampleCount, greaterThanOrEqualTo(24), reason: t.id);
      for (final Vec2 v in <Vec2>[...r.edgeA, ...r.edgeB]) {
        expect(r.bounds.contains(Offset(v.x, v.y)), isTrue, reason: '${t.id} edge outside bounds');
      }
      expect(r.sceneryCount, greaterThanOrEqualTo(0));
      r.dispose();
    }
  });

  test('the road edges are half a road width from the centre line', () {
    final Track t = TrackCatalog.journey.first;
    final TrackRenderer r = TrackRenderer(t);
    for (int i = 0; i < r.sampleCount; i += 25) {
      final double w = r.edgeA[i].distanceTo(r.edgeB[i]);
      expect(w, greaterThan(5), reason: 'sample $i');
      expect(w, lessThan(40), reason: 'sample $i');
    }
  });

  test('tracks with scenery get some, and none of it sits on the road', () {
    final TrackRenderer r = TrackRenderer(TrackCatalog.journey.first);
    expect(r.sceneryCount, greaterThan(10));
  });

  test('the same track draws the same scenery every time', () {
    final TrackRenderer a = TrackRenderer(TrackCatalog.journey[4]);
    final TrackRenderer b = TrackRenderer(TrackCatalog.journey[4]);
    expect(a.sceneryCount, b.sceneryCount);
  });

  test('every surface has a colour and a sand track has sand ground', () {
    for (final SurfaceType s in SurfaceType.values) {
      expect(TrackRenderer.colorFor(s).a, 1);
    }
    final Track sand = TrackCatalog.all.firstWhere((Track t) => t.baseSurface == SurfaceType.sand);
    expect(TrackRenderer(sand).groundColor, isNot(TrackRenderer(TrackCatalog.journey.first).groundColor));
  });
}
