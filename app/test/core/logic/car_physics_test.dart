import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/logic/car_physics.dart';
import 'package:ruach/core/logic/surface_model.dart';
import 'package:ruach/core/models/drive_input.dart';
import 'package:ruach/core/models/track.dart';
import 'package:ruach/core/models/vec2.dart';
import 'package:ruach/core/models/vehicle.dart';

import 'test_support.dart';

const double _dt = 1 / 60;
const SurfaceEffect _asphalt = SurfaceEffect(gripFactor: 1, speedFactor: 1);

CarState _car({double speed = 0, double heading = 0}) => CarState(
      position: Vec2.zero,
      heading: heading,
      velocity: Vec2.fromAngle(heading, speed),
    );

void _run(
  CarState s,
  DriveInput input,
  double seconds, {
  Vehicle vehicle = testVehicle,
  CarTuning tuning = const CarTuning(),
  SurfaceEffect surface = _asphalt,
  bool boosting = false,
}) {
  final int steps = (seconds / _dt).round();
  for (int i = 0; i < steps; i++) {
    CarPhysics.step(s, vehicle, tuning, input, surface, dt: _dt, boosting: boosting);
  }
}

Vehicle _with({double grip = 1, double steerRate = 2.2, double mass = 1100}) => Vehicle(
      id: 'v',
      kind: VehicleKind.hatch,
      era: testVehicle.era,
      massKg: mass,
      acceleration: testVehicle.acceleration,
      maxSpeed: testVehicle.maxSpeed,
      brakeDeceleration: testVehicle.brakeDeceleration,
      grip: grip,
      drag: testVehicle.drag,
      steerRate: steerRate,
      canDrift: false,
      boost: testVehicle.boost,
    );

void main() {
  const DriveInput gas = DriveInput(throttle: 1);

  test('a car accelerates up towards its top speed and never past it', () {
    final CarState s = _car();
    _run(s, gas, 15);
    expect(s.forwardSpeed, greaterThan(30));
    _run(s, gas, 30);
    expect(s.forwardSpeed, lessThanOrEqualTo(testVehicle.maxSpeed + 0.01));
    expect(s.forwardSpeed, greaterThan(testVehicle.maxSpeed * 0.9));
  });

  test('a car at rest with no input stays at rest', () {
    final CarState s = _car();
    _run(s, DriveInput.idle, 2);
    expect(s.speed, 0);
    expect(s.position, Vec2.zero);
  });

  test('braking stops the car and does not reverse it', () {
    final CarState s = _car(speed: 30);
    _run(s, const DriveInput(brake: 1), 4);
    expect(s.speed, lessThan(0.5));
    expect(s.forwardSpeed, greaterThanOrEqualTo(0));
  });

  test('coasting slows the car', () {
    final CarState s = _car(speed: 30);
    _run(s, DriveInput.idle, 2);
    expect(s.forwardSpeed, lessThan(30));
    expect(s.forwardSpeed, greaterThan(10));
  });

  test('steering right turns the heading clockwise on screen', () {
    final CarState s = _car(speed: 20);
    _run(s, const DriveInput(steer: 1, throttle: 1), 1);
    expect(s.heading, greaterThan(0.1));
    final CarState l = _car(speed: 20);
    _run(l, const DriveInput(steer: -1, throttle: 1), 1);
    expect(l.heading, lessThan(-0.1));
  });

  test('a stopped car does not spin on the spot', () {
    final CarState s = _car();
    _run(s, const DriveInput(steer: 1), 2);
    expect(s.heading.abs(), lessThan(1e-9));
  });

  test('low grip turns less at speed', () {
    final CarState grippy = _car(speed: 35);
    final CarState loose = _car(speed: 35);
    _run(grippy, const DriveInput(steer: 1, throttle: 1), 1, vehicle: _with());
    _run(loose, const DriveInput(steer: 1, throttle: 1), 1, vehicle: _with(grip: 0.3));
    expect(loose.heading, lessThan(grippy.heading));
  });

  test('sideways speed dies away when going straight', () {
    final CarState s = CarState(
      position: Vec2.zero,
      heading: 0,
      velocity: const Vec2(20, 5),
    );
    _run(s, gas, 2);
    expect(s.velocity.y.abs(), lessThan(0.1));
  });

  test('sand lowers the top speed', () {
    final CarState s = _car();
    _run(s, gas, 40, surface: SurfaceModel.base(SurfaceType.sand));
    expect(s.forwardSpeed, lessThanOrEqualTo(testVehicle.maxSpeed * 0.75 + 0.01));
  });

  test('boost reaches a higher speed', () {
    final CarState plain = _car();
    final CarState boosted = _car();
    _run(plain, gas, 6);
    _run(boosted, gas, 6, boosting: true);
    expect(boosted.forwardSpeed, greaterThan(plain.forwardSpeed));
  });

  test('upgrades change top speed', () {
    final CarState plain = _car();
    final CarState fast = _car();
    _run(plain, gas, 40);
    _run(fast, gas, 40, tuning: const CarTuning(topSpeedMultiplier: 1.1));
    expect(fast.forwardSpeed, greaterThan(plain.forwardSpeed + 2));
  });

  test('recovery speeds up acceleration from low speed', () {
    final CarState plain = _car();
    final CarState quick = _car();
    _run(plain, gas, 3);
    _run(quick, gas, 3, tuning: const CarTuning(recovery: 1));
    expect(quick.forwardSpeed, greaterThan(plain.forwardSpeed));
  });

  test('wind pushes the car sideways', () {
    final CarState s = _car(speed: 20);
    for (int i = 0; i < 120; i++) {
      CarPhysics.step(s, testVehicle, const CarTuning(), gas, _asphalt, dt: _dt, wind: const Vec2(0, 2));
    }
    expect(s.position.y, greaterThan(0.5));
  });

  group('contact', () {
    test('cars that are apart do not touch', () {
      final CarState a = _car();
      final CarState b = CarState(position: const Vec2(10, 0), heading: 0);
      expect(CarPhysics.resolveContact(a, testVehicle, b, testVehicle), isFalse);
    });

    test('overlapping cars are pushed apart', () {
      final CarState a = _car();
      final CarState b = CarState(position: const Vec2(1, 0), heading: 0);
      expect(CarPhysics.resolveContact(a, testVehicle, b, testVehicle), isTrue);
      expect(a.position.distanceTo(b.position), closeTo(2 * CarPhysics.carRadius, 1e-9));
    });

    test('the heavier car moves less and keeps more speed', () {
      final CarState light = CarState(position: Vec2.zero, heading: 0, velocity: const Vec2(20, 0));
      final CarState heavy = CarState(position: const Vec2(2, 0), heading: 0);
      CarPhysics.resolveContact(light, _with(mass: 500), heavy, _with(mass: 3000));
      expect(light.velocity.x, lessThan(20));
      expect(heavy.velocity.x, greaterThan(0));
      expect(heavy.velocity.x, lessThan(5));
    });
  });
}
