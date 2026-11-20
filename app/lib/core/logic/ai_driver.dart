import 'dart:math' as math;

import 'package:ruach/core/logic/numeric.dart';
import 'package:ruach/core/logic/race_rules.dart';
import 'package:ruach/core/logic/seeded_rng.dart';
import 'package:ruach/core/models/drive_input.dart';
import 'package:ruach/core/models/race_config.dart';
import 'package:ruach/core/models/rival.dart';
import 'package:ruach/core/models/vec2.dart';

/// The numbers that shape rival driving, all in one place. Rubber-banding is
/// capped here and never hidden elsewhere (blueprint section 2). These are
/// tuning starting points that the balance simulation (batch p2c) adjusts.
abstract final class AiTuning {
  /// Largest pace change from rubber-banding, as a share (0.04 is plus or
  /// minus 4 percent).
  static const double rubberBandCap = 0.04;

  /// Distance in metres at which the rubber band reaches its cap.
  static const double rubberBandRange = 150;

  /// How much of the lateral grip a rival uses in corners, from the least to
  /// the most skilled.
  static const double minCornerUse = 0.55;
  static const double maxCornerUse = 0.92;

  /// Pace multiplier by difficulty.
  static double difficultyPace(Difficulty d) => switch (d) {
        Difficulty.easy => 0.9,
        Difficulty.normal => 0.96,
        Difficulty.hard => 1.0,
      };

  /// Pace multiplier from rubber-banding. [gapMetres] is how far this car is
  /// ahead of the player (negative when behind). Ahead means a slight easing,
  /// behind a slight push, never more than [rubberBandCap].
  static double rubberBand(double gapMetres) {
    final double t = clampDouble(gapMetres / rubberBandRange, -1, 1);
    return 1 - t * rubberBandCap;
  }
}

/// A computer-driven rival. It follows a racing line (inside of upcoming
/// corners), brakes for corners using the lateral grip its skill allows,
/// overtakes and defends according to its aggression, wanders slightly
/// according to its consistency, and spends the Ruach meter on straights.
/// Every random choice comes from a [SeededRng] forked from the race seed, so
/// a race replays identically.
final class AiDriver implements CarController {
  AiDriver({
    required this.rival,
    required SeededRng rng,
    this.difficulty = Difficulty.normal,
  })  : _rng = rng,
        _reactionSeconds = (1 - rival.skill) * 0.35 + rng.nextRange(0, 0.15),
        _passSide = rng.nextBool() ? 1.0 : -1.0;

  /// One driver per rival of [config], each with its own stream from the race
  /// seed, in the order of [RaceConfig.rivals].
  static List<AiDriver> forRace(RaceConfig config) {
    final SeededRng root = SeededRng(config.seed).fork('ai');
    return <AiDriver>[
      for (final Rival r in config.rivals)
        AiDriver(
          rival: r,
          rng: root.fork(r.id),
          difficulty: config.difficulty,
        ),
    ];
  }

  final Rival rival;
  final Difficulty difficulty;
  final SeededRng _rng;
  final double _reactionSeconds;
  double _passSide;

  double _wander = 0;
  int _wanderTick = 0;

  @override
  DriveInput drive(RaceSimulation race, RaceCar car) {
    if (race.elapsedSeconds < _reactionSeconds) return DriveInput.idle;

    final double speed = car.state.forwardSpeed;
    final double distance = car.projection.distance;
    final double halfWidth = car.projection.halfWidth;

    // Slow drift around the line, smaller for consistent drivers.
    if (race.raceTick >= _wanderTick) {
      _wander = _rng.nextRange(-1, 1) * (1 - rival.consistency) * halfWidth * 0.35;
      _wanderTick = race.raceTick + 30;
    }

    // Where to aim.
    final double look = 12 + speed * 0.55;
    final double lineOffset = _lineOffset(race, distance + look * 0.5, halfWidth, rival.skill);
    double desired = lineOffset + _wander + _trafficOffset(race, car);
    final double limit = math.max(0.5, halfWidth - 1.4);
    desired = clampDouble(desired, -limit, limit);
    if (!car.projection.onTrack) desired = 0;

    final Vec2 tangent = race.geometry.tangentAt(distance + look);
    final Vec2 target = race.geometry.positionAt(distance + look) + tangent.perpendicular * desired;
    final double error = wrapAngle((target - car.state.position).angle - car.state.heading);
    final double steer = clampDouble(error * 2, -1, 1);

    // How fast to go.
    final double cornerUse = AiTuning.minCornerUse +
        (AiTuning.maxCornerUse - AiTuning.minCornerUse) * rival.skill;
    final double pace = AiTuning.difficultyPace(difficulty) *
        AiTuning.rubberBand(car.progress - race.player.progress);
    final double lateralLimit = 13 * car.vehicle.grip * cornerUse * pace;
    final double span = 20 + speed * 1.2;
    final double turn = race.geometry.curvatureAhead(distance, span).abs();
    final double radius = turn < 0.02 ? 2000 : span / turn;
    final double cornerSpeed = math.sqrt(lateralLimit * radius);
    final double topSpeed = car.vehicle.maxSpeed * pace;
    final double wanted = math.min(cornerSpeed, topSpeed);

    double throttle = 1;
    double brake = 0;
    if (speed > wanted * 1.03) {
      throttle = 0;
      brake = clampDouble((speed - wanted) / 6, 0.2, 1);
    } else if (speed > wanted) {
      throttle = 0.3;
    }
    if (!car.projection.onTrack) throttle = math.min(throttle, 0.7);

    // Ease off behind a car that cannot be passed yet.
    if (_blockedAhead(race, car) && rival.aggression < 0.3) {
      throttle = math.min(throttle, 0.6);
    }

    // Spend the Ruach meter on a clear straight.
    final bool boost = car.meter.canSpend &&
        !car.boosting &&
        turn < 0.2 &&
        _rng.nextDouble() < 0.02 * (0.5 + rival.skill);

    return DriveInput(steer: steer, throttle: throttle, brake: brake, boost: boost);
  }

  /// Offset towards the inside of the corner ahead, in metres.
  static double _lineOffset(RaceSimulation race, double distance, double halfWidth, double skill) {
    final double turn = race.geometry.curvatureAhead(distance, 40);
    final double share = clampDouble(turn.abs() / 0.6, 0, 1);
    return turn.sign * share * 0.55 * halfWidth * (0.4 + 0.6 * skill);
  }

  bool _blockedAhead(RaceSimulation race, RaceCar car) {
    for (final RaceCar other in race.cars) {
      if (identical(other, car) || other.eliminated) continue;
      final Vec2 offset = other.state.position - car.state.position;
      final double ahead = offset.dot(car.state.forward);
      final double side = offset.dot(car.state.forward.perpendicular);
      if (ahead > 2 && ahead < 10 && side.abs() < 2.6) return true;
    }
    return false;
  }

  /// Sideways shift to pass a car ahead or to hold position against one behind.
  double _trafficOffset(RaceSimulation race, RaceCar car) {
    final Vec2 forward = car.state.forward;
    final Vec2 right = forward.perpendicular;
    double shift = 0;
    for (final RaceCar other in race.cars) {
      if (identical(other, car) || other.eliminated) continue;
      final Vec2 offset = other.state.position - car.state.position;
      final double ahead = offset.dot(forward);
      final double side = offset.dot(right);
      if (ahead > 2 && ahead < 28 && side.abs() < 3.2) {
        // Pass on the side with more room; keep the same side while passing.
        final double dir = side.abs() < 0.3 ? _passSide : (side > 0 ? -1.0 : 1.0);
        _passSide = dir;
        shift += dir * (2.5 + rival.aggression * 3);
      } else if (ahead < -3 && ahead > -14 && side.abs() < 4 && rival.aggression > 0.55) {
        // Defend: lean towards the car behind.
        if (other.state.forwardSpeed > car.state.forwardSpeed) {
          shift += clampDouble(side * 0.4, -2, 2);
        }
      } else if (ahead.abs() <= 2.5 && side.abs() < 3.2) {
        // Alongside: give room.
        shift += (side > 0 ? -1.0 : 1.0) * 1.2;
      }
    }
    return shift;
  }
}
