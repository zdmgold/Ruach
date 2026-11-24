import 'package:ruach/core/logic/numeric.dart';
import 'package:ruach/core/models/drive_input.dart';
import 'package:ruach/core/models/settings.dart';

/// What the screen reports about the player's fingers and phone at one
/// instant. The three control schemes read different parts of it.
final class ControlSnapshot {
  const ControlSnapshot({
    this.left = false,
    this.right = false,
    this.brake = false,
    this.boost = false,
    this.dragSteer = 0,
    this.tiltRadians = 0,
  });

  /// Steer buttons (Buttons scheme).
  final bool left;
  final bool right;

  /// The brake and boost buttons (all schemes).
  final bool brake;
  final bool boost;

  /// Drag-steer: the finger's sideways position relative to the centre of the
  /// drag area, -1 (far left) to 1 (far right).
  final double dragSteer;

  /// Tilt: the phone's roll in radians, positive when tilted to the right.
  final double tiltRadians;
}

/// Turns a [ControlSnapshot] into a [DriveInput]. Every scheme produces the
/// same value, so the race never knows which one is in use. Throttle is
/// automatic; lifting happens only when the brake is held.
abstract interface class DriveInputStrategy {
  /// The input for this step. [dt] is the time since the last call.
  DriveInput read(ControlSnapshot snapshot, double dt);

  /// Forgets any smoothing, for a new race.
  void reset();
}

/// Moves [current] towards [target] by at most [rate] x [dt].
double _approach(double current, double target, double rate, double dt) {
  final double step = rate * dt;
  if (target > current + step) return current + step;
  if (target < current - step) return current - step;
  return target;
}

/// Left and right buttons. Steering ramps up and back so a tap is gentle and
/// a hold is full lock.
final class ButtonsStrategy implements DriveInputStrategy {
  /// Steering per second when a button is held.
  static const double rampUp = 5;

  /// Steering per second returning to centre.
  static const double rampDown = 8;

  double _steer = 0;

  @override
  DriveInput read(ControlSnapshot s, double dt) {
    final double target = (s.right ? 1.0 : 0.0) - (s.left ? 1.0 : 0.0);
    final bool releasing = target == 0 || (target.sign != _steer.sign && _steer != 0);
    _steer = _approach(_steer, target, releasing ? rampDown : rampUp, dt);
    return DriveInput.clamped(
      steer: _steer,
      throttle: s.brake ? 0 : 1,
      brake: s.brake ? 1 : 0,
      boost: s.boost,
    );
  }

  @override
  void reset() => _steer = 0;
}

/// The finger's position sets the steering angle, with a dead zone in the
/// middle and smoothing.
final class DragSteerStrategy implements DriveInputStrategy {
  static const double deadZone = 0.08;

  /// How fast the steering follows the finger, in full-lock units per second.
  static const double follow = 10;

  double _steer = 0;

  @override
  DriveInput read(ControlSnapshot s, double dt) {
    final double raw = clampDouble(s.dragSteer, -1, 1);
    double target = 0;
    if (raw.abs() > deadZone) {
      target = raw.sign * (raw.abs() - deadZone) / (1 - deadZone);
    }
    _steer = _approach(_steer, target, follow, dt);
    return DriveInput.clamped(
      steer: _steer,
      throttle: s.brake ? 0 : 1,
      brake: s.brake ? 1 : 0,
      boost: s.boost,
    );
  }

  @override
  void reset() => _steer = 0;
}

/// Phone tilt steers. [calibration] is the rest angle from the calibration
/// screen; [sensitivity] scales the response (0.25 to 2).
final class TiltStrategy implements DriveInputStrategy {
  TiltStrategy({this.calibration = 0, this.sensitivity = 1});

  /// Tilt (radians) from the rest angle that gives full lock at sensitivity 1.
  static const double fullLockTilt = 0.45;
  static const double deadZone = 0.03;
  static const double follow = 12;

  /// The steering a tilt of [tiltRadians] asks for, before smoothing: -1 to 1.
  /// The calibration screen draws this so the player sees what the race will do.
  static double steerFor(double tiltRadians, double calibration, double sensitivity) {
    final double tilt = tiltRadians - calibration;
    if (tilt.abs() <= deadZone) return 0;
    return clampDouble(tilt.sign * (tilt.abs() - deadZone) / fullLockTilt * sensitivity, -1, 1);
  }

  final double calibration;
  final double sensitivity;
  double _steer = 0;

  @override
  DriveInput read(ControlSnapshot s, double dt) {
    final double target = steerFor(s.tiltRadians, calibration, sensitivity);
    _steer = _approach(_steer, target, follow, dt);
    return DriveInput.clamped(
      steer: _steer,
      throttle: s.brake ? 0 : 1,
      brake: s.brake ? 1 : 0,
      boost: s.boost,
    );
  }

  @override
  void reset() => _steer = 0;
}

abstract final class InputStrategies {
  /// The strategy for the player's saved settings.
  static DriveInputStrategy create(Settings settings) => switch (settings.controlScheme) {
        ControlScheme.buttons => ButtonsStrategy(),
        ControlScheme.dragSteer => DragSteerStrategy(),
        ControlScheme.tilt => TiltStrategy(
            calibration: settings.tiltCalibration,
            sensitivity: settings.tiltSensitivity,
          ),
      };
}
