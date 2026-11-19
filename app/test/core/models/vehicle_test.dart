import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/models/track.dart';
import 'package:ruach/core/models/vehicle.dart';

Vehicle _vehicle({String id = 'v', double grip = 1}) => Vehicle(
      id: id,
      kind: VehicleKind.hatch,
      era: Era.today,
      massKg: 1000,
      acceleration: 8,
      maxSpeed: 40,
      brakeDeceleration: 15,
      grip: grip,
      drag: 0.1,
      steerRate: 2,
      canDrift: false,
      boost: const BoostProfile(
        durationSeconds: 2,
        topSpeedMultiplier: 1.2,
        accelerationMultiplier: 1.5,
      ),
    );

void main() {
  test('equality is by id', () {
    expect(_vehicle(), _vehicle(grip: 2));
    expect(_vehicle() == _vehicle(id: 'w'), isFalse);
  });

  test('invalid values are rejected in debug builds', () {
    expect(() => _vehicle(grip: 0), throwsAssertionError);
    expect(
      () => BoostProfile(
        durationSeconds: 0,
        topSpeedMultiplier: 1,
        accelerationMultiplier: 1,
      ),
      throwsAssertionError,
    );
    expect(
      () => BoostProfile(
        durationSeconds: 1,
        topSpeedMultiplier: 0.9,
        accelerationMultiplier: 1,
      ),
      throwsAssertionError,
    );
  });
}
