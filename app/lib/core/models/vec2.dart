import 'dart:math' as math;

/// An immutable two-dimensional vector. World units are metres, with x to the
/// right and y downward on screen; angles are radians, zero along +x and
/// increasing clockwise on screen.
///
/// Core code is pure Dart (blueprint section 4), so this is not Flutter's
/// `Offset`. The same arithmetic produces the same numbers on the same
/// platform, which the seeded simulation relies on.
final class Vec2 {
  const Vec2(this.x, this.y);

  /// A vector of the given length pointing at [radians].
  factory Vec2.fromAngle(double radians, [double length = 1]) =>
      Vec2(math.cos(radians) * length, math.sin(radians) * length);

  static const Vec2 zero = Vec2(0, 0);

  final double x;
  final double y;

  Vec2 operator +(Vec2 other) => Vec2(x + other.x, y + other.y);
  Vec2 operator -(Vec2 other) => Vec2(x - other.x, y - other.y);
  Vec2 operator -() => Vec2(-x, -y);
  Vec2 operator *(double scale) => Vec2(x * scale, y * scale);
  Vec2 operator /(double divisor) => Vec2(x / divisor, y / divisor);

  double dot(Vec2 other) => x * other.x + y * other.y;

  /// The z component of the 3D cross product. Positive when [other] is
  /// clockwise of this vector on screen.
  double cross(Vec2 other) => x * other.y - y * other.x;

  double get lengthSquared => x * x + y * y;
  double get length => math.sqrt(lengthSquared);

  /// The angle of this vector in radians.
  double get angle => math.atan2(y, x);

  /// This vector turned 90 degrees clockwise on screen.
  Vec2 get perpendicular => Vec2(-y, x);

  /// A unit vector in the same direction, or [zero] for a zero vector.
  Vec2 normalized() {
    final double l = length;
    return l == 0 ? zero : this / l;
  }

  Vec2 rotated(double radians) {
    final double c = math.cos(radians);
    final double s = math.sin(radians);
    return Vec2(x * c - y * s, x * s + y * c);
  }

  double distanceTo(Vec2 other) => (this - other).length;

  /// Linear interpolation: this vector at 0, [other] at 1.
  Vec2 lerp(Vec2 other, double t) =>
      Vec2(x + (other.x - x) * t, y + (other.y - y) * t);

  @override
  bool operator ==(Object other) =>
      other is Vec2 && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'Vec2($x, $y)';
}
