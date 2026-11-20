import 'dart:math' as math;

import 'package:ruach/core/logic/numeric.dart';
import 'package:ruach/core/logic/race_rules.dart';
import 'package:ruach/core/models/drive_input.dart';
import 'package:ruach/core/models/race_config.dart';
import 'package:ruach/core/models/rival.dart';
import 'package:ruach/core/models/track.dart';
import 'package:ruach/core/models/vec2.dart';
import 'package:ruach/core/models/vehicle.dart';

/// An oval about 1.2 km round, 14 m wide, used by the logic tests.
Track testTrack({
  List<SurfaceZone> zones = const <SurfaceZone>[],
  SurfaceType base = SurfaceType.asphalt,
}) {
  const int n = 12;
  final List<Vec2> points = <Vec2>[
    for (int i = 0; i < n; i++)
      Vec2(
        250 * math.cos(2 * math.pi * i / n),
        120 * math.sin(2 * math.pi * i / n),
      ),
  ];
  return Track(
    id: 'test_oval',
    number: 1,
    era: Era.chariotAge,
    variant: TrackVariant.then,
    centerline: points,
    widths: List<double>.filled(n, 14),
    checkpointFractions: const <double>[0.25, 0.5, 0.75],
    parLapSeconds: 55,
    baseSurface: base,
    surfaceZones: zones,
  );
}

const Vehicle testVehicle = Vehicle(
  id: 'test_hatch',
  kind: VehicleKind.hatch,
  era: Era.today,
  massKg: 1100,
  acceleration: 9,
  maxSpeed: 42,
  brakeDeceleration: 18,
  grip: 1,
  drag: 0.3,
  steerRate: 2.2,
  canDrift: false,
  boost: BoostProfile(
    durationSeconds: 2.5,
    topSpeedMultiplier: 1.15,
    accelerationMultiplier: 1.4,
  ),
);

const List<Rival> testRivals = <Rival>[
  Rival(id: 'r1', name: 'One', team: 'T', skill: 0.5, aggression: 0.5, consistency: 0.5),
  Rival(id: 'r2', name: 'Two', team: 'T', skill: 0.5, aggression: 0.5, consistency: 0.5),
  Rival(id: 'r3', name: 'Three', team: 'T', skill: 0.5, aggression: 0.5, consistency: 0.5),
  Rival(id: 'r4', name: 'Four', team: 'T', skill: 0.5, aggression: 0.5, consistency: 0.5),
  Rival(id: 'r5', name: 'Five', team: 'T', skill: 0.5, aggression: 0.5, consistency: 0.5),
];

RaceConfig testConfig({
  int laps = 2,
  int rivals = 0,
  int seed = 1,
  Track? track,
}) =>
    RaceConfig(
      track: track ?? testTrack(),
      vehicle: testVehicle,
      mode: RaceMode.quickRace,
      laps: laps,
      difficulty: Difficulty.normal,
      seed: seed,
      rivals: testRivals.sublist(0, rivals),
    );

/// A plain line follower: steers at a point ahead on the centreline and
/// brakes for corners. It exists to prove the rules can run a whole race; the
/// real rival AI is `ai_driver.dart`.
final class LineFollower implements CarController {
  const LineFollower({this.cornerAcceleration = 10});

  final double cornerAcceleration;

  @override
  DriveInput drive(RaceSimulation race, RaceCar car) {
    return follow(race, car, cornerAcceleration: cornerAcceleration);
  }
}

DriveInput follow(RaceSimulation race, RaceCar car, {double cornerAcceleration = 10}) {
  final double speed = car.state.forwardSpeed;
  final double lookahead = 12 + speed * 0.6;
  final Vec2 target = race.geometry.positionAt(car.projection.distance + lookahead);
  final double error = wrapAngle((target - car.state.position).angle - car.state.heading);
  final double steer = clampDouble(error * 2, -1, 1);
  final double turn = race.geometry.curvatureAhead(car.projection.distance, 40).abs();
  final double radius = turn < 0.02 ? 1000 : 40 / turn;
  final double cornerSpeed = math.sqrt(cornerAcceleration * radius);
  final bool tooFast = speed > cornerSpeed;
  return DriveInput(
    steer: steer,
    throttle: tooFast ? 0 : 1,
    brake: tooFast ? 1 : 0,
  );
}
