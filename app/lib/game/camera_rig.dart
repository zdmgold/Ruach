import 'dart:math' as math;

import 'package:ruach/core/logic/numeric.dart';
import 'package:ruach/core/models/vec2.dart';

/// The follow camera: heading-up, looking a little ahead of the car and
/// zooming out as speed rises. Pure maths, no drawing, so it is tested
/// without a screen.
///
/// World coordinates are the same as screen coordinates (y points down), so a
/// car whose heading is `h` points at screen angle `h`; the rig rotates the
/// world so the car points up.
final class CameraRig {
  CameraRig({
    this.metresAcross = 45,
    this.lookAheadMetres = 14,
    this.anchorY = 0.68,
    this.fullSpeed = 60,
    this.zoomOutAtSpeed = 0.3,
  });

  /// Width of the view in metres at rest.
  final double metresAcross;

  /// How far ahead of the car the view centres at full speed.
  final double lookAheadMetres;

  /// Where the car sits from the top of the screen: 0 top, 1 bottom.
  final double anchorY;

  /// Speed (m/s) that counts as full for look-ahead and zoom.
  final double fullSpeed;

  /// Share of the zoom given up at full speed.
  final double zoomOutAtSpeed;

  static const double _followRate = 8;
  static const double _turnRate = 4;
  static const double _zoomRate = 2;

  Vec2 _center = Vec2.zero;
  double _heading = 0;
  double _zoom = 8;

  /// The world point at the anchor.
  Vec2 get center => _center;

  /// Pixels per metre.
  double get zoom => _zoom;

  /// The rotation to apply to the canvas so the heading points up.
  double get rotation => -math.pi / 2 - _heading;

  /// Jumps to the car without smoothing, for a new race.
  void snapTo({required Vec2 position, required double heading, required double viewportWidth}) {
    _center = position;
    _heading = heading;
    _zoom = viewportWidth / metresAcross;
  }

  void update(
    double dt, {
    required Vec2 position,
    required double heading,
    required double speed,
    required double viewportWidth,
  }) {
    final double frac = clampDouble(speed / fullSpeed, 0, 1);
    final Vec2 target = position + Vec2.fromAngle(heading) * (lookAheadMetres * frac);
    final double move = _alpha(_followRate, dt);
    _center = _center.lerp(target, move);
    _heading = wrapAngle(_heading + wrapAngle(heading - _heading) * _alpha(_turnRate, dt));
    final double zoomTarget = viewportWidth / metresAcross * (1 - zoomOutAtSpeed * frac);
    _zoom += (zoomTarget - _zoom) * _alpha(_zoomRate, dt);
  }

  static double _alpha(double rate, double dt) => 1 - math.exp(-rate * math.max(0, dt));

  /// Where a world point lands on a screen of [width] x [height].
  Vec2 worldToScreen(Vec2 point, double width, double height) {
    final Vec2 local = (point - _center).rotated(rotation) * _zoom;
    return Vec2(width / 2 + local.x, height * anchorY + local.y);
  }
}
