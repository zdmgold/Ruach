import 'dart:math' as math;

import 'package:ruach/core/logic/surface_model.dart';
import 'package:ruach/core/logic/track_geometry.dart';
import 'package:ruach/core/models/track.dart';
import 'package:ruach/core/models/vehicle.dart';

/// Estimates a good lap time for a track and vehicle without running a race:
/// a speed profile around the lap that is limited by corner grip, braking and
/// acceleration, with some slack added so a good human lap can reach it. The
/// catalog uses it to set each track's par, which scales Time Trial stars.
abstract final class ParEstimator {
  /// Share of the lateral grip a good lap uses in corners.
  static const double cornerUse = 0.8;

  /// Share of acceleration and braking a good lap uses.
  static const double driveUse = 0.8;

  /// Multiplier for imperfect lines, contact and the start.
  static const double slack = 1.2;

  /// Lateral acceleration per unit of grip, matching `car_physics.dart`.
  static const double lateralPerGrip = 13;

  static double lapSeconds(Track track, Vehicle vehicle, {double step = 4}) {
    final TrackGeometry geometry = TrackGeometry.of(track);
    final int n = math.max(8, (geometry.length / step).ceil());
    final double ds = geometry.length / n;

    final List<double> limit = List<double>.filled(n, 0);
    for (int i = 0; i < n; i++) {
      final double s = i * ds;
      final SurfaceEffect effect = SurfaceModel.effect(
        geometry.surfaceAt(s / geometry.length),
        vehicle.kind,
      );
      final double top = vehicle.maxSpeed * effect.speedFactor;
      final double kappa = geometry.curvatureAhead(s, ds).abs() / ds;
      if (kappa < 1e-6) {
        limit[i] = top;
      } else {
        final double lateral = lateralPerGrip * vehicle.grip * effect.gripFactor * cornerUse;
        limit[i] = math.min(top, math.sqrt(lateral / kappa));
      }
    }

    final List<double> v = List<double>.of(limit);
    final double brake = vehicle.brakeDeceleration * driveUse;
    final double accel = vehicle.acceleration * driveUse;
    for (int round = 0; round < 2; round++) {
      for (int k = 2 * n - 1; k >= 0; k--) {
        final int i = k % n;
        final int next = (i + 1) % n;
        v[i] = math.min(v[i], math.sqrt(v[next] * v[next] + 2 * brake * ds));
      }
      for (int k = 0; k < 2 * n; k++) {
        final int i = k % n;
        final int next = (i + 1) % n;
        v[next] = math.min(v[next], math.sqrt(v[i] * v[i] + 2 * accel * ds));
      }
    }

    double seconds = 0;
    for (int i = 0; i < n; i++) {
      final double average = (v[i] + v[(i + 1) % n]) / 2;
      seconds += ds / math.max(average, 1);
    }
    return seconds * slack;
  }
}
