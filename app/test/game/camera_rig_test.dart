import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/models/vec2.dart';
import 'package:ruach/game/camera_rig.dart';

void main() {
  test('after a snap the car is at the anchor and its heading points up', () {
    final CameraRig rig = CameraRig();
    rig.snapTo(position: const Vec2(100, 50), heading: 0.7, viewportWidth: 360);
    final Vec2 car = rig.worldToScreen(const Vec2(100, 50), 360, 640);
    expect(car.x, closeTo(180, 1e-6));
    expect(car.y, closeTo(640 * rig.anchorY, 1e-6));
    final Vec2 ahead = rig.worldToScreen(const Vec2(100, 50) + Vec2.fromAngle(0.7) * 10, 360, 640);
    expect(ahead.x, closeTo(180, 1e-6));
    expect(ahead.y, lessThan(car.y));
  });

  test('a point to the right of the car appears on the right of the screen', () {
    final CameraRig rig = CameraRig();
    rig.snapTo(position: Vec2.zero, heading: 1.2, viewportWidth: 360);
    final Vec2 right = Vec2.fromAngle(1.2).perpendicular;
    expect(rig.worldToScreen(right * 5, 360, 640).x, greaterThan(180));
  });

  test('the view looks ahead and zooms out as speed rises', () {
    final CameraRig slow = CameraRig()..snapTo(position: Vec2.zero, heading: 0, viewportWidth: 360);
    final CameraRig fast = CameraRig()..snapTo(position: Vec2.zero, heading: 0, viewportWidth: 360);
    for (int i = 0; i < 300; i++) {
      slow.update(1 / 60, position: Vec2.zero, heading: 0, speed: 0, viewportWidth: 360);
      fast.update(1 / 60, position: Vec2.zero, heading: 0, speed: 60, viewportWidth: 360);
    }
    expect(slow.center.x, closeTo(0, 1e-6));
    expect(fast.center.x, closeTo(14, 0.05));
    expect(fast.zoom, lessThan(slow.zoom));
    expect(fast.zoom, closeTo(slow.zoom * 0.7, 0.05));
  });

  test('the heading follows by the short way round', () {
    final CameraRig rig = CameraRig()..snapTo(position: Vec2.zero, heading: math.pi - 0.1, viewportWidth: 360);
    rig.update(0.1, position: Vec2.zero, heading: -math.pi + 0.1, speed: 0, viewportWidth: 360);
    // It moved a little towards pi + 0.1, not the long way back through zero.
    final double r = rig.rotation;
    expect(r.abs(), greaterThan(1.5));
  });

  test('a zero or negative frame time changes nothing', () {
    final CameraRig rig = CameraRig()..snapTo(position: const Vec2(5, 5), heading: 0, viewportWidth: 360);
    rig.update(0, position: const Vec2(50, 50), heading: 1, speed: 30, viewportWidth: 360);
    rig.update(-1, position: const Vec2(50, 50), heading: 1, speed: 30, viewportWidth: 360);
    expect(rig.center, const Vec2(5, 5));
  });
}
