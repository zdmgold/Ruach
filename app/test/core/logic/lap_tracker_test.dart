import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/logic/lap_tracker.dart';

const double _length = 1000;

LapTracker _tracker({int laps = 2, double behind = 8}) => LapTracker(
      trackLength: _length,
      checkpointFractions: const <double>[0.25, 0.5, 0.75],
      laps: laps,
      startBehindLine: behind,
    );

/// Drives [metres] forward in 2 m steps from [from], returning the distance
/// reached and the step count.
double _drive(LapTracker t, double from, double metres, {double clock = 0}) {
  double d = from;
  double time = clock;
  final int steps = (metres / 2).round();
  for (int i = 0; i < steps; i++) {
    d = (d + 2) % _length;
    time += 1 / 30;
    t.update(d, time);
  }
  return d;
}

void main() {
  test('on the grid the distance is negative and no lap is counted', () {
    final LapTracker t = _tracker();
    expect(t.totalDistance, -8);
    expect(t.lap, 0);
    expect(t.finished, isFalse);
  });

  test('checkpoints are passed in order', () {
    final LapTracker t = _tracker();
    double d = 992;
    d = _drive(t, d, 8 + 260);
    expect(t.nextCheckpoint, 1);
    d = _drive(t, d, 250);
    expect(t.nextCheckpoint, 2);
    _drive(t, d, 250);
    expect(t.nextCheckpoint, 3);
    expect(t.lap, 0);
  });

  test('crossing the line after every checkpoint completes a lap', () {
    final LapTracker t = _tracker();
    final double d = _drive(t, 992, 8 + 1000 + 10);
    expect(t.lap, 1);
    expect(t.nextCheckpoint, 0);
    expect(t.lapTimes.length, 1);
    expect(t.lapTimes.first, greaterThan(0));
    expect(d, closeTo(10, 1e-9));
    expect(t.finished, isFalse);
  });

  test('finishing all laps ends the race and records every lap time', () {
    final LapTracker t = _tracker();
    _drive(t, 992, 8 + 2000 + 10);
    expect(t.finished, isTrue);
    expect(t.lap, 2);
    expect(t.lapTimes.length, 2);
    expect(t.finishSeconds, isNotNull);
    expect(t.raceProgress, 1);
    final double distance = t.totalDistance;
    t.update(500, 999);
    expect(t.totalDistance, distance);
  });

  test('driving backwards loses distance', () {
    final LapTracker t = _tracker(behind: 0);
    _drive(t, 0, 100);
    final double before = t.totalDistance;
    t.update(90, 10);
    expect(t.totalDistance, lessThan(before));
  });

  test('a jump across the infield earns no credit', () {
    final LapTracker t = _tracker(behind: 0);
    t.update(100, 1);
    expect(t.totalDistance, closeTo(100, 1e-9));
    t.update(600, 2);
    expect(t.totalDistance, closeTo(100, 1e-9));
  });

  test('after a long stay away the tracker re-anchors without credit', () {
    final LapTracker t = _tracker(behind: 0);
    t.update(100, 1);
    for (int i = 0; i < LapTracker.reanchorAfter; i++) {
      t.update(600, 2);
    }
    expect(t.totalDistance, closeTo(100, 1e-9));
    t.update(602, 3);
    expect(t.totalDistance, closeTo(102, 1e-9));
  });

  test('a shortcut means the lap needs extra distance afterwards', () {
    final LapTracker t = _tracker(laps: 1, behind: 0);
    double d = _drive(t, 0, 200);
    // Cut 300 m across the infield.
    for (int i = 0; i < LapTracker.reanchorAfter; i++) {
      t.update(500, 10);
    }
    d = 500;
    d = _drive(t, d, 520);
    // The car is physically past the line but is 300 m of credit short.
    expect(t.finished, isFalse);
    _drive(t, d, 320);
    expect(t.finished, isTrue);
  });
}
