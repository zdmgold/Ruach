import 'dart:async';
import 'dart:math' as math;

import 'package:ruach/core/ports/device_ports.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Tilt steering from the accelerometer. The phone is held upright and turned
/// like a steering wheel: the angle is how far the screen's up direction has
/// rotated, positive when the right edge goes down.
final class TiltService implements TiltPort {
  TiltService({this.samplingPeriod = const Duration(milliseconds: 20)});

  final Duration samplingPeriod;

  /// Roll in radians from accelerometer axes in the device frame (Android
  /// convention, which sensors_plus applies on iOS too: gravity shows as
  /// +9.8 on y when upright, and x is negative when the right edge is down).
  static double rollFrom(double x, double y) {
    if (x == 0 && y == 0) return 0;
    return math.atan2(-x, y);
  }

  @override
  Future<bool> isAvailable() async {
    try {
      final AccelerometerEvent event = await accelerometerEventStream(
        samplingPeriod: samplingPeriod,
      ).first.timeout(const Duration(seconds: 1));
      return event.x.isFinite && event.y.isFinite;
    } on Object {
      return false;
    }
  }

  @override
  Stream<double> get roll => accelerometerEventStream(samplingPeriod: samplingPeriod)
      .map((AccelerometerEvent e) => rollFrom(e.x, e.y))
      .handleError((Object _) {});
}
