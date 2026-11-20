/// Small number helpers shared by the race logic. Core is pure Dart, so
/// Flutter's `clampDouble` is not available.
library;

/// [value] forced into [lower] to [upper].
double clampDouble(double value, double lower, double upper) {
  if (value < lower) return lower;
  if (value > upper) return upper;
  return value;
}

/// [angle] wrapped into -pi to pi.
double wrapAngle(double angle) {
  const double twoPi = 6.283185307179586;
  double a = angle % twoPi;
  if (a > 3.141592653589793) a -= twoPi;
  if (a < -3.141592653589793) a += twoPi;
  return a;
}
