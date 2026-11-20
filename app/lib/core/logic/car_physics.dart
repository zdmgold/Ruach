import 'dart:math' as math;

import 'package:ruach/core/logic/numeric.dart';
import 'package:ruach/core/logic/surface_model.dart';
import 'package:ruach/core/models/drive_input.dart';
import 'package:ruach/core/models/vec2.dart';
import 'package:ruach/core/models/vehicle.dart';

/// The motion state of one car. Mutable on purpose: the race steps thousands
/// of times a second in simulations and allocation matters.
final class CarState {
  CarState({
    required this.position,
    required this.heading,
    this.velocity = Vec2.zero,
  });

  Vec2 position;

  /// Direction the car points, radians, zero along +x.
  double heading;

  /// World velocity in metres per second.
  Vec2 velocity;

  /// True while the rear is stepping out in a corner (drift-capable vehicles).
  bool drifting = false;

  Vec2 get forward => Vec2.fromAngle(heading);

  /// Speed along the heading, negative never (reversing is not modelled).
  double get forwardSpeed => velocity.dot(forward);

  double get speed => velocity.length;

  CarState copy() => CarState(position: position, heading: heading, velocity: velocity)
    ..drifting = drifting;
}

/// Upgrade-derived changes to a vehicle, as multipliers. `upgrade_rules.dart`
/// (batch p2c) turns the player's upgrade levels into one of these.
final class CarTuning {
  const CarTuning({
    this.topSpeedMultiplier = 1,
    this.gripMultiplier = 1,
    this.steadiness = 0,
    this.recovery = 0,
    this.meterFillMultiplier = 1,
  });

  /// Might: multiplies top speed.
  final double topSpeedMultiplier;

  /// Understanding: multiplies grip.
  final double gripMultiplier;

  /// Fear of the LORD, 0 to 1: shrugs off rough surfaces.
  final double steadiness;

  /// Knowledge, 0 to 1: faster acceleration back up to speed after leaving
  /// the road or after contact.
  final double recovery;

  /// Wisdom: multiplies how fast the Ruach meter fills.
  final double meterFillMultiplier;
}

/// Car motion on a flat plane at a fixed time step. A deliberately simple
/// arcade model: forward speed is driven by throttle and brake and capped by
/// the surface; steering turns the heading, limited by grip; sideways
/// velocity decays at a rate set by grip, which is what makes loose vehicles
/// slide wide and drift-capable ones step out.
abstract final class CarPhysics {
  /// How quickly sideways velocity decays per unit of grip.
  static const double lateralDamping = 7;

  /// Sideways acceleration one unit of grip can hold, in m/s squared.
  static const double lateralAcceleration = 13;

  /// Speed below which steering fades out, so a stopped car does not spin.
  static const double steerFadeSpeed = 4;

  /// Radius of a car for contact, in metres.
  static const double carRadius = 1.2;

  /// Advances [state] by [dt] seconds.
  static void step(
    CarState state,
    Vehicle vehicle,
    CarTuning tuning,
    DriveInput input,
    SurfaceEffect surface, {
    required double dt,
    bool boosting = false,
    Vec2 wind = Vec2.zero,
  }) {
    final double boostTop = boosting ? vehicle.boost.topSpeedMultiplier : 1;
    final double boostAcceleration = boosting ? vehicle.boost.accelerationMultiplier : 1;
    final double maxSpeed =
        vehicle.maxSpeed * tuning.topSpeedMultiplier * surface.speedFactor * boostTop;

    // Frame before steering.
    double forwardSpeed = math.max(0.0, state.velocity.dot(state.forward));

    // Steering: limited by what the grip can hold at this speed.
    double grip = vehicle.grip * surface.gripFactor * tuning.gripMultiplier;
    final bool sliding = vehicle.canDrift &&
        input.brake > 0.1 &&
        input.steer.abs() > 0.3 &&
        forwardSpeed > 12;
    if (sliding) grip *= 0.45;
    final double speedRatio = maxSpeed > 0 ? math.min(1.0, forwardSpeed / maxSpeed) : 0.0;
    final double fade = math.min(1.0, forwardSpeed / steerFadeSpeed);
    double yawRate = input.steer * vehicle.steerRate * fade * (1 - 0.5 * speedRatio);
    final double yawLimit =
        lateralAcceleration * vehicle.grip * surface.gripFactor * tuning.gripMultiplier /
            math.max(forwardSpeed, 1.0);
    yawRate = clampDouble(yawRate, -yawLimit, yawLimit);
    state.heading = wrapAngle(state.heading + yawRate * dt);

    // Frame after steering: part of the old velocity is now sideways.
    final Vec2 forward = state.forward;
    final Vec2 right = forward.perpendicular;
    forwardSpeed = state.velocity.dot(forward);
    double lateral = state.velocity.dot(right);

    // Forward speed.
    double acceleration = vehicle.acceleration * boostAcceleration;
    if (forwardSpeed < 0.7 * maxSpeed) {
      acceleration *= 1 + tuning.recovery * 0.5;
    }
    if (input.throttle > 0 && forwardSpeed < maxSpeed) {
      final double ratio = math.max(0.0, forwardSpeed / maxSpeed);
      forwardSpeed += acceleration * input.throttle * (1 - ratio * ratio * ratio) * dt;
    }
    if (input.brake > 0) {
      forwardSpeed -= vehicle.brakeDeceleration * input.brake * dt;
    }
    // Coasting drag, only without throttle.
    forwardSpeed -= vehicle.drag * (1 - input.throttle) * forwardSpeed * dt;
    // Above the cap (left a boost, entered sand) speed bleeds off quickly.
    if (forwardSpeed > maxSpeed) {
      forwardSpeed -= (forwardSpeed - maxSpeed) * math.min(1.0, 2.5 * dt);
    }
    if (forwardSpeed < 0) forwardSpeed = 0;

    // Sideways speed decays with grip.
    lateral *= math.exp(-grip * lateralDamping * dt);
    state.drifting = vehicle.canDrift && lateral.abs() > 3 && forwardSpeed > 12;

    state.velocity = forward * forwardSpeed + right * lateral + wind * dt;
    state.position = state.position + state.velocity * dt;
  }

  /// Pushes two overlapping cars apart and exchanges momentum along the
  /// contact line. Returns true if they were touching. Heavier vehicles move
  /// less.
  static bool resolveContact(
    CarState a,
    Vehicle vehicleA,
    CarState b,
    Vehicle vehicleB,
  ) {
    final Vec2 offset = b.position - a.position;
    final double distance = offset.length;
    const double minimum = 2 * carRadius;
    if (distance >= minimum) return false;
    final Vec2 normal = distance == 0 ? const Vec2(1, 0) : offset / distance;
    final double overlap = minimum - distance;
    final double massA = vehicleA.massKg;
    final double massB = vehicleB.massKg;
    final double total = massA + massB;
    a.position = a.position - normal * (overlap * massB / total);
    b.position = b.position + normal * (overlap * massA / total);
    final double closing = (a.velocity - b.velocity).dot(normal);
    if (closing > 0) {
      const double restitution = 0.25;
      final double impulse = (1 + restitution) * closing / (1 / massA + 1 / massB);
      a.velocity = a.velocity - normal * (impulse / massA);
      b.velocity = b.velocity + normal * (impulse / massB);
    }
    return true;
  }
}
