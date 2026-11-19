import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/models/vec2.dart';

void main() {
  test('arithmetic', () {
    const Vec2 a = Vec2(1, 2);
    const Vec2 b = Vec2(3, -4);
    expect(a + b, const Vec2(4, -2));
    expect(a - b, const Vec2(-2, 6));
    expect(-a, const Vec2(-1, -2));
    expect(a * 2, const Vec2(2, 4));
    expect(b / 2, const Vec2(1.5, -2));
  });

  test('dot, cross and length', () {
    const Vec2 a = Vec2(3, 4);
    expect(a.length, 5);
    expect(a.lengthSquared, 25);
    expect(a.dot(const Vec2(1, 0)), 3);
    expect(const Vec2(1, 0).cross(const Vec2(0, 1)), 1);
  });

  test('normalized handles the zero vector', () {
    expect(Vec2.zero.normalized(), Vec2.zero);
    expect(const Vec2(0, 5).normalized(), const Vec2(0, 1));
  });

  test('rotation and angle', () {
    final Vec2 r = const Vec2(1, 0).rotated(math.pi / 2);
    expect(r.x, closeTo(0, 1e-12));
    expect(r.y, closeTo(1, 1e-12));
    expect(const Vec2(0, 1).angle, closeTo(math.pi / 2, 1e-12));
    final Vec2 f = Vec2.fromAngle(0, 3);
    expect(f, const Vec2(3, 0));
  });

  test('perpendicular is 90 degrees clockwise on screen', () {
    expect(const Vec2(1, 0).perpendicular, const Vec2(0, 1));
  });

  test('distance and lerp', () {
    expect(const Vec2(0, 0).distanceTo(const Vec2(3, 4)), 5);
    expect(const Vec2(0, 0).lerp(const Vec2(10, 20), 0.5), const Vec2(5, 10));
  });

  test('equality and hash', () {
    expect(const Vec2(1, 2) == const Vec2(1, 2), isTrue);
    expect(const Vec2(1, 2).hashCode, const Vec2(1, 2).hashCode);
    expect(const Vec2(1, 2) == const Vec2(2, 1), isFalse);
  });
}
