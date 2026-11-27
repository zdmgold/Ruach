import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/logic/boost_meter.dart';

const double _dt = 1 / 60;

void _clean(BoostMeter m, double seconds, {double multiplier = 1}) {
  for (int i = 0; i < (seconds / _dt).round(); i++) {
    m.addCleanDriving(_dt, multiplier: multiplier);
  }
}

void main() {
  test('it starts empty and cannot be spent', () {
    final BoostMeter m = BoostMeter();
    expect(m.fill, 0);
    expect(m.canSpend, isFalse);
    expect(m.spend(), isFalse);
    expect(m.fill, 0);
  });

  test('clean driving fills three segments in about 20 seconds', () {
    final BoostMeter m = BoostMeter();
    _clean(m, 7);
    expect(m.fullSegments, 1);
    _clean(m, 14);
    expect(m.fill, closeTo(BoostMeter.segments.toDouble(), 1e-9));
  });

  test('the meter never holds more than three segments', () {
    final BoostMeter m = BoostMeter();
    _clean(m, 200);
    expect(m.fill, BoostMeter.segments.toDouble());
  });

  test('spending takes one segment at a time', () {
    final BoostMeter m = BoostMeter(initial: 2.5);
    expect(m.spend(), isTrue);
    expect(m.fill, closeTo(1.5, 1e-9));
    expect(m.spend(), isTrue);
    expect(m.fill, closeTo(0.5, 1e-9));
    expect(m.spend(), isFalse);
  });

  test('wisdom makes it fill faster', () {
    final BoostMeter plain = BoostMeter();
    final BoostMeter wise = BoostMeter();
    _clean(plain, 10);
    _clean(wise, 10, multiplier: 1.5);
    expect(wise.fill, greaterThan(plain.fill));
  });

  test('slipstream charges only after the delay and resets when it ends', () {
    final BoostMeter m = BoostMeter();
    for (int i = 0; i < 24; i++) {
      m.updateSlipstream(true, _dt);
    }
    expect(m.fill, 0);
    for (int i = 0; i < 60; i++) {
      m.updateSlipstream(true, _dt);
    }
    expect(m.fill, greaterThan(0.1));
    final double after = m.fill;
    m.updateSlipstream(false, _dt);
    for (int i = 0; i < 24; i++) {
      m.updateSlipstream(true, _dt);
    }
    expect(m.fill, after);
  });

  test('drifting charges the meter', () {
    final BoostMeter m = BoostMeter();
    for (int i = 0; i < 60; i++) {
      m.addDrift(_dt);
    }
    expect(m.fill, closeTo(BoostMeter.driftRate, 1e-6));
  });

  test('a granted charge is capped', () {
    final BoostMeter m = BoostMeter(initial: 2.5);
    m.grant(5);
    expect(m.fill, BoostMeter.segments.toDouble());
  });
}
