import 'package:ruach/core/models/track.dart';

/// The six vehicles. All are original designs: no real brand, model or logo.
enum VehicleKind {
  lightChariot,
  heavyChariot,
  roadCart,
  hatch,
  roadster,
  utility4x4,
}

/// What one spent segment of the Ruach meter does. The Light Chariot gets a
/// short, strong surge and the Heavy Chariot a longer, weaker one; modern cars
/// get a short burst. Stamina is not modelled separately: the segment cost is
/// the limit.
final class BoostProfile {
  const BoostProfile({
    required this.durationSeconds,
    required this.topSpeedMultiplier,
    required this.accelerationMultiplier,
  })  : assert(durationSeconds > 0, 'a boost must last some time'),
        assert(topSpeedMultiplier >= 1, 'a boost cannot slow the vehicle'),
        assert(accelerationMultiplier >= 1, 'a boost cannot slow the vehicle');

  final double durationSeconds;

  /// Top speed while boosting, as a multiple of the normal top speed.
  final double topSpeedMultiplier;

  /// Acceleration while boosting, as a multiple of normal acceleration.
  final double accelerationMultiplier;
}

/// A vehicle's handling as data. Units are metres, seconds and kilograms.
/// Numbers are tuning starting points; the balance simulation (batch p2c)
/// adjusts them.
///
/// Two vehicles are equal when their [id] is equal.
final class Vehicle {
  const Vehicle({
    required this.id,
    required this.kind,
    required this.era,
    required this.massKg,
    required this.acceleration,
    required this.maxSpeed,
    required this.brakeDeceleration,
    required this.grip,
    required this.drag,
    required this.steerRate,
    required this.canDrift,
    required this.boost,
  })  : assert(massKg > 0, 'mass must be positive'),
        assert(acceleration > 0, 'acceleration must be positive'),
        assert(maxSpeed > 0, 'top speed must be positive'),
        assert(brakeDeceleration > 0, 'braking must be positive'),
        assert(grip > 0, 'grip must be positive'),
        assert(drag >= 0, 'drag cannot be negative'),
        assert(steerRate > 0, 'steering rate must be positive');

  /// Stable id used in saved progress, for example `light_chariot`.
  final String id;

  final VehicleKind kind;

  /// The era the vehicle belongs to, which decides where it is unlocked.
  final Era era;

  final double massKg;

  /// Forward acceleration with the throttle fully down, in m/s squared.
  final double acceleration;

  /// Top speed on a surface with no extra drag, in m/s.
  final double maxSpeed;

  /// Braking deceleration with the brake fully down, in m/s squared.
  final double brakeDeceleration;

  /// Sideways grip as a multiple of the base grip of the surface. Above 1 is
  /// grippier than average.
  final double grip;

  /// Air and rolling drag, per second.
  final double drag;

  /// The fastest the heading can turn at low speed, in radians per second.
  final double steerRate;

  /// True for vehicles whose rear steps out in a corner and that charge the
  /// Ruach meter while drifting.
  final bool canDrift;

  final BoostProfile boost;

  @override
  bool operator ==(Object other) => other is Vehicle && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Vehicle($id)';
}
