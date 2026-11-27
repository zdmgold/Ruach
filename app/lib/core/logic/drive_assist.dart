import 'dart:math' as math;

import 'package:ruach/core/logic/car_physics.dart';
import 'package:ruach/core/logic/numeric.dart';
import 'package:ruach/core/logic/race_rules.dart';
import 'package:ruach/core/models/drive_input.dart';
import 'package:ruach/core/models/vec2.dart';

/// Makes the player's car easy to drive: it keeps to the road, slows for
/// sharp corners by itself and holds the road well. The player's steering
/// does not turn the wheel directly; it moves the lane the car aims for, so a
/// touch on the left half drifts the car to the left of the road and a touch
/// on the right half to the right, and letting go returns it to the middle.
/// Boost and any brake the player asks for pass straight through.
///
/// Only the player's car uses it, and only in the app: the rules tests drive
/// the car directly.
final class PlayerAssist {
  const PlayerAssist({
    this.laneShare = 0.65,
    this.cornerUse = 0.9,
    this.gripBonus = 1.25,
  });

  /// How far to the side a full touch aims, as a share of half the road.
  final double laneShare;

  /// How much of the sideways grip the automatic braking plans to use.
  final double cornerUse;

  /// Extra grip given to the player's car so a slide is rare and short.
  final double gripBonus;

  /// [tuning] with the extra grip, steadiness and recovery the assist adds.
  CarTuning stabilise(CarTuning tuning) => CarTuning(
        topSpeedMultiplier: tuning.topSpeedMultiplier,
        gripMultiplier: tuning.gripMultiplier * gripBonus,
        steadiness: math.max(tuning.steadiness, 0.5),
        recovery: math.max(tuning.recovery, 0.5),
        meterFillMultiplier: tuning.meterFillMultiplier,
      );

  /// The input the car really gets for what the player asked for.
  DriveInput apply(RaceSimulation race, RaceCar car, DriveInput input) {
    final double speed = car.state.forwardSpeed;
    final double distance = car.projection.distance;
    final double halfWidth = car.projection.halfWidth;

    // Steering: aim at a point ahead, shifted sideways by the player's touch.
    final double limit = math.max(0.5, halfWidth - 1.6);
    double offset = clampDouble(input.steer * laneShare * halfWidth, -limit, limit);
    if (!car.projection.onTrack) offset = 0;
    final double look = 10 + speed * 0.5;
    final Vec2 tangent = race.geometry.tangentAt(distance + look);
    final Vec2 target = race.geometry.positionAt(distance + look) + tangent.perpendicular * offset;
    final double error = wrapAngle((target - car.state.position).angle - car.state.heading);
    final double steer = clampDouble(error * 2.2, -1, 1);

    // Speed: lift and brake for the corner ahead.
    final double grip = car.vehicle.grip * car.tuning.gripMultiplier;
    final double lateralLimit = CarPhysics.lateralAcceleration * grip * cornerUse;
    final double span = 20 + speed * 1.2;
    final double turn = race.geometry.curvatureAhead(distance, span).abs();
    final double radius = turn < 0.02 ? 2000 : span / turn;
    final double wanted = math.sqrt(lateralLimit * radius);
    double throttle = input.throttle;
    double brake = input.brake;
    if (speed > wanted * 1.03) {
      throttle = 0;
      final double need = clampDouble((speed - wanted) / 6, 0.2, 1);
      // A drift-capable car slides when it brakes hard in a turn; it only
      // lifts and brakes lightly so the assist never throws it sideways.
      brake = math.max(brake, car.vehicle.canDrift ? math.min(need, 0.1) : need);
    }
    return DriveInput(steer: steer, throttle: throttle, brake: brake, boost: input.boost);
  }
}
