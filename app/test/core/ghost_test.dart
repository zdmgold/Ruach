import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/logic/ghost.dart';
import 'package:ruach/core/models/vec2.dart';

GhostLap _circle({int n = 600, double seconds = 60}) {
  final List<Vec2> p = <Vec2>[];
  final List<double> h = <double>[];
  for (int k = 0; k < n; k++) {
    final double a = 2 * math.pi * k / n;
    p.add(Vec2(300 * math.cos(a), 300 * math.sin(a)));
    h.add(a + math.pi / 2);
  }
  return GhostLap(lapSeconds: seconds, positions: p, headings: h);
}

void main() {
  test('a lap survives encoding to within a decimetre and a hundredth of a radian', () {
    final GhostLap lap = _circle();
    final GhostLap? back = GhostCodec.decode(GhostCodec.encode(lap));
    expect(back, isNotNull);
    expect(back!.length, lap.length);
    expect(back.lapSeconds, closeTo(60, 0.001));
    for (int k = 0; k < lap.length; k += 37) {
      expect(back.positions[k].distanceTo(lap.positions[k]), lessThan(0.08));
      final double d = (back.headings[k] - lap.headings[k]) % (2 * math.pi);
      expect(math.min(d, 2 * math.pi - d), lessThan(0.02));
    }
  });

  test('a one-minute lap is a few kilobytes and a long one stays under 20 KB', () {
    expect(GhostCodec.encode(_circle()).length, lessThan(5000));
    expect(GhostCodec.encode(_circle(n: 2400, seconds: 240)).length, lessThan(20000));
  });

  test('garbage and truncated text decode to null', () {
    expect(GhostCodec.decode(''), isNull);
    expect(GhostCodec.decode('not base64 !!'), isNull);
    final String good = GhostCodec.encode(_circle());
    expect(GhostCodec.decode(good.substring(0, good.length - 8)), isNull);
  });

  test('playback interpolates and keeps lapping', () {
    final GhostLap lap = _circle(n: 600, seconds: 60);
    final Vec2 a = lap.positionAt(10);
    expect(a.distanceTo(lap.positions[100]), lessThan(1e-6));
    expect(lap.positionAt(70).distanceTo(a), lessThan(1e-6));
    final Vec2 mid = lap.positionAt(10.05);
    expect(mid.distanceTo(a.lerp(lap.positions[101], 0.5)), lessThan(1e-6));
    expect(lap.positionAt(-50).distanceTo(lap.positionAt(10)), lessThan(1e-6));
  });

  test('the heading turns the short way across the wrap', () {
    final GhostLap lap = GhostLap(
      lapSeconds: 0.2,
      positions: <Vec2>[Vec2.zero, const Vec2(1, 0)],
      headings: <double>[math.pi - 0.1, -math.pi + 0.1],
    );
    expect(lap.headingAt(0.05).abs(), greaterThan(3.0));
  });

  test('the recorder keeps every sixth tick and refuses a lap with too few samples', () {
    final GhostRecorder r = GhostRecorder();
    for (int t = 0; t < 61; t++) {
      r.sample(t, Vec2(t.toDouble(), 0), 0);
    }
    expect(r.sampleCount, 11);
    final GhostLap? lap = r.finish(10);
    expect(lap!.length, 11);
    r.startLap();
    r.sample(0, Vec2.zero, 0);
    expect(r.finish(1), isNull);
    expect(r.finish(0), isNull);
  });
}
