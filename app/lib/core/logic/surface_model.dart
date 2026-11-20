import 'package:ruach/core/models/track.dart';
import 'package:ruach/core/models/vehicle.dart';

/// How a surface changes a vehicle's driving, as multiples of its normal
/// values.
final class SurfaceEffect {
  const SurfaceEffect({required this.gripFactor, required this.speedFactor});

  /// Sideways grip, 1 is the normal value.
  final double gripFactor;

  /// How much of the vehicle's top speed can be used.
  final double speedFactor;
}

/// Grip and speed for each surface, and how each vehicle copes with rough
/// ground. The numbers are tuning starting points (blueprint section 2).
abstract final class SurfaceModel {
  /// The surface under a car that has left the road.
  static const SurfaceType offTrack = SurfaceType.grass;

  static const Map<SurfaceType, SurfaceEffect> _base = <SurfaceType, SurfaceEffect>{
    SurfaceType.asphalt: SurfaceEffect(gripFactor: 1, speedFactor: 1),
    SurfaceType.cobble: SurfaceEffect(gripFactor: 0.9, speedFactor: 0.95),
    SurfaceType.stone: SurfaceEffect(gripFactor: 0.85, speedFactor: 0.92),
    SurfaceType.dirt: SurfaceEffect(gripFactor: 0.8, speedFactor: 0.9),
    SurfaceType.sand: SurfaceEffect(gripFactor: 0.65, speedFactor: 0.75),
    SurfaceType.ford: SurfaceEffect(gripFactor: 0.7, speedFactor: 0.6),
    SurfaceType.grass: SurfaceEffect(gripFactor: 0.6, speedFactor: 0.7),
  };

  /// The unmodified effect of [surface].
  static SurfaceEffect base(SurfaceType surface) => _base[surface]!;

  /// How much of a rough surface's penalty a vehicle shrugs off, 0 to 1. The
  /// Utility 4x4 copes best, the Road Cart is forgiving, chariots are in
  /// between or not at all.
  static double roughnessResistance(VehicleKind kind) => switch (kind) {
        VehicleKind.utility4x4 => 0.5,
        VehicleKind.roadCart => 0.35,
        VehicleKind.heavyChariot => 0.2,
        VehicleKind.lightChariot => 0,
        VehicleKind.hatch => 0,
        VehicleKind.roadster => 0,
      };

  /// The effect of [surface] on a vehicle of [kind]. [steadiness] (0 to 1) is
  /// the Fear of the LORD upgrade and adds to the vehicle's own resistance.
  static SurfaceEffect effect(
    SurfaceType surface,
    VehicleKind kind, {
    double steadiness = 0,
  }) {
    final SurfaceEffect b = base(surface);
    final double own = roughnessResistance(kind);
    final double resist = 1 - (1 - own) * (1 - steadiness.clamp(0.0, 1.0).toDouble());
    return SurfaceEffect(
      gripFactor: 1 - (1 - b.gripFactor) * (1 - resist),
      speedFactor: 1 - (1 - b.speedFactor) * (1 - resist),
    );
  }
}
