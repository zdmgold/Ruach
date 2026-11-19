import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/models/drive_input.dart';

void main() {
  test('idle is all zero', () {
    expect(DriveInput.idle.steer, 0);
    expect(DriveInput.idle.throttle, 0);
    expect(DriveInput.idle.brake, 0);
    expect(DriveInput.idle.boost, isFalse);
  });

  test('clamped forces values into range', () {
    final DriveInput i =
        DriveInput.clamped(steer: -3, throttle: 2, brake: -1, boost: true);
    expect(i, const DriveInput(steer: -1, throttle: 1, boost: true));
  });

  test('out of range values are rejected', () {
    expect(() => DriveInput(steer: 1.5), throwsAssertionError);
    expect(() => DriveInput(throttle: -0.1), throwsAssertionError);
    expect(() => DriveInput(brake: 2), throwsAssertionError);
  });

  test('equality and hash', () {
    const DriveInput a = DriveInput(steer: 0.5, throttle: 1);
    const DriveInput b = DriveInput(steer: 0.5, throttle: 1);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a == const DriveInput(steer: 0.5), isFalse);
  });
}
