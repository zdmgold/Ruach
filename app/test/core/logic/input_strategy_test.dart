import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/logic/input_strategy.dart';
import 'package:ruach/core/models/drive_input.dart';
import 'package:ruach/core/models/settings.dart';

const double _dt = 1 / 60;

DriveInput _hold(DriveInputStrategy s, ControlSnapshot snap, double seconds) {
  DriveInput last = DriveInput.idle;
  for (int i = 0; i < (seconds / _dt).round(); i++) {
    last = s.read(snap, _dt);
  }
  return last;
}

void main() {
  group('buttons', () {
    test('throttle is automatic and brake lifts it', () {
      final ButtonsStrategy s = ButtonsStrategy();
      expect(s.read(const ControlSnapshot(), _dt).throttle, 1);
      final DriveInput b = s.read(const ControlSnapshot(brake: true), _dt);
      expect(b.throttle, 0);
      expect(b.brake, 1);
    });

    test('holding right ramps to full lock and releasing returns to centre', () {
      final ButtonsStrategy s = ButtonsStrategy();
      final DriveInput early = _hold(s, const ControlSnapshot(right: true), 0.05);
      expect(early.steer, greaterThan(0));
      expect(early.steer, lessThan(1));
      expect(_hold(s, const ControlSnapshot(right: true), 0.5).steer, 1);
      expect(_hold(s, const ControlSnapshot(), 0.4).steer, 0);
    });

    test('left is always negative and both buttons cancel out', () {
      final ButtonsStrategy s = ButtonsStrategy();
      expect(_hold(s, const ControlSnapshot(left: true), 0.5).steer, -1);
      s.reset();
      expect(_hold(s, const ControlSnapshot(left: true, right: true), 0.5).steer, 0);
    });

    test('boost passes straight through', () {
      expect(ButtonsStrategy().read(const ControlSnapshot(boost: true), _dt).boost, isTrue);
    });
  });

  group('drag steer', () {
    test('the middle is a dead zone', () {
      final DragSteerStrategy s = DragSteerStrategy();
      expect(_hold(s, const ControlSnapshot(dragSteer: 0.05), 0.5).steer, 0);
    });

    test('the finger position sets the angle and sign', () {
      final DragSteerStrategy s = DragSteerStrategy();
      final double half = _hold(s, const ControlSnapshot(dragSteer: 0.5), 1).steer;
      expect(half, inInclusiveRange(0.3, 0.6));
      expect(_hold(s, const ControlSnapshot(dragSteer: 1), 1).steer, closeTo(1, 1e-9));
      expect(_hold(s, const ControlSnapshot(dragSteer: -1), 1).steer, closeTo(-1, 1e-9));
    });

    test('out of range values are clamped', () {
      final DragSteerStrategy s = DragSteerStrategy();
      expect(_hold(s, const ControlSnapshot(dragSteer: 5), 1).steer, closeTo(1, 1e-9));
    });
  });

  group('tilt', () {
    test('tilting right steers right and left steers left', () {
      final TiltStrategy s = TiltStrategy();
      expect(_hold(s, const ControlSnapshot(tiltRadians: 0.3), 1).steer, greaterThan(0.4));
      expect(_hold(s, const ControlSnapshot(tiltRadians: -0.3), 1).steer, lessThan(-0.4));
    });

    test('the calibration angle is the new centre', () {
      final TiltStrategy s = TiltStrategy(calibration: 0.4);
      expect(_hold(s, const ControlSnapshot(tiltRadians: 0.4), 1).steer, 0);
      expect(_hold(s, const ControlSnapshot(tiltRadians: 0.1), 1).steer, lessThan(0));
    });

    test('sensitivity scales the response', () {
      final double low = _hold(TiltStrategy(sensitivity: 0.5), const ControlSnapshot(tiltRadians: 0.2), 1).steer;
      final double high = _hold(TiltStrategy(sensitivity: 1.5), const ControlSnapshot(tiltRadians: 0.2), 1).steer;
      expect(high, greaterThan(low));
    });

    test('a small wobble inside the dead zone does nothing', () {
      expect(_hold(TiltStrategy(), const ControlSnapshot(tiltRadians: 0.02), 1).steer, 0);
    });
  });

  test('the settings choose the strategy', () {
    expect(InputStrategies.create(const Settings()), isA<ButtonsStrategy>());
    expect(InputStrategies.create(const Settings(controlScheme: ControlScheme.dragSteer)), isA<DragSteerStrategy>());
    expect(InputStrategies.create(const Settings(controlScheme: ControlScheme.tilt)), isA<TiltStrategy>());
  });

  test('reset clears smoothing', () {
    final ButtonsStrategy s = ButtonsStrategy();
    _hold(s, const ControlSnapshot(right: true), 0.5);
    s.reset();
    expect(s.read(const ControlSnapshot(), _dt).steer, 0);
  });
}
