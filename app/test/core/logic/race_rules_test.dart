import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/logic/race_rules.dart';
import 'package:ruach/core/models/drive_input.dart';
import 'package:ruach/core/models/race_result.dart';

import 'test_support.dart';

void _skipCountdown(RaceSimulation sim) {
  for (int i = 0; i < RaceSimulation.countdownTicks; i++) {
    sim.step(DriveInput.idle);
  }
}

/// Runs until the race ends, with the player driven by the line follower.
void _runToEnd(RaceSimulation sim) {
  int guard = 0;
  while (sim.phase != RacePhase.finished && guard < 200000) {
    sim.step(follow(sim, sim.player));
    guard++;
  }
}

RaceSimulation _race({int laps = 2, int rivals = 0, int seed = 1}) {
  return RaceSimulation(
    config: testConfig(laps: laps, rivals: rivals, seed: seed),
    controllers: List<LineFollower>.filled(rivals, const LineFollower(cornerAcceleration: 9)),
  );
}

void main() {
  test('the race counts down for three seconds and then runs', () {
    final RaceSimulation sim = _race();
    expect(sim.phase, RacePhase.countdown);
    for (int i = 0; i < RaceSimulation.countdownTicks - 1; i++) {
      sim.step(const DriveInput(throttle: 1));
    }
    expect(sim.phase, RacePhase.countdown);
    sim.step(const DriveInput(throttle: 1));
    expect(sim.phase, RacePhase.racing);
    expect(sim.player.state.speed, 0);
  });

  test('the player starts at the back of a full grid', () {
    final RaceSimulation sim = _race(rivals: 5);
    expect(sim.cars.length, 6);
    expect(sim.player.position, 6);
    expect(sim.cars.map((c) => c.position).toSet(), <int>{1, 2, 3, 4, 5, 6});
  });

  test('a lone driver finishes the race and the result is complete', () {
    final RaceSimulation sim = _race();
    _runToEnd(sim);
    expect(sim.phase, RacePhase.finished);
    expect(sim.player.finished, isTrue);
    final RaceResult r = sim.toResult(stars: 3);
    expect(r.playerWon, isTrue);
    expect(r.player.lapTimes.length, 2);
    expect(r.player.totalTime, greaterThan(const Duration(seconds: 60)));
    expect(r.player.totalTime, lessThan(const Duration(seconds: 200)));
    expect(r.cleanDrivingScore, greaterThan(0.5));
    expect(r.stars, 3);
  });

  test('a full grid finishes with sensible positions', () {
    final RaceSimulation sim = _race(laps: 1, rivals: 5);
    _runToEnd(sim);
    expect(sim.phase, RacePhase.finished);
    final List<RacerStanding> standings = sim.standings();
    expect(standings.length, 6);
    expect(standings.map((s) => s.position).toList(), <int>[1, 2, 3, 4, 5, 6]);
    expect(standings.first.finished, isTrue);
    expect(sim.player.position, inInclusiveRange(1, 6));
  });

  test('the same race twice gives the same result', () {
    final RaceSimulation a = _race(laps: 1, rivals: 5);
    final RaceSimulation b = _race(laps: 1, rivals: 5);
    for (int i = 0; i < 1500; i++) {
      a.step(follow(a, a.player));
      b.step(follow(b, b.player));
    }
    expect(a.stateHash(), b.stateHash());
    expect(a.player.position, b.player.position);
  });

  test('a different input changes the race', () {
    final RaceSimulation a = _race();
    final RaceSimulation b = _race();
    for (int i = 0; i < 600; i++) {
      a.step(follow(a, a.player));
      b.step(const DriveInput(throttle: 1, steer: 0.2));
    }
    expect(a.stateHash(), isNot(b.stateHash()));
  });

  test('a player who does nothing does not finish and the race times out', () {
    final RaceSimulation sim = _race(laps: 1);
    int guard = 0;
    while (sim.phase != RacePhase.finished && guard < 100000) {
      sim.step(DriveInput.idle);
      guard++;
    }
    expect(sim.phase, RacePhase.finished);
    expect(sim.raceTick, sim.maxTicks);
    expect(sim.player.finished, isFalse);
    expect(sim.toResult().playerWon, isFalse);
  });

  test('boost is spent from the meter when asked for', () {
    final RaceSimulation sim = RaceSimulation(
      config: testConfig(),
      startingBoost: 1,
    );
    _skipCountdown(sim);
    sim.step(const DriveInput(throttle: 1, boost: true));
    expect(sim.player.boosting, isTrue);
    expect(sim.player.meter.fill, lessThan(1));
  });

  test('boost does nothing with an empty meter', () {
    final RaceSimulation sim = _race();
    _skipCountdown(sim);
    sim.step(const DriveInput(throttle: 1, boost: true));
    expect(sim.player.boosting, isFalse);
  });

  test('driving off the road is not clean driving', () {
    final RaceSimulation sim = _race();
    _skipCountdown(sim);
    for (int i = 0; i < 300; i++) {
      sim.step(const DriveInput(throttle: 1, steer: -1));
    }
    expect(sim.cleanDrivingScore, lessThan(0.9));
  });

  test('a car that runs wide is held within the run-off', () {
    final RaceSimulation sim = _race();
    _skipCountdown(sim);
    for (int i = 0; i < 1200; i++) {
      sim.step(const DriveInput(throttle: 1, steer: -0.4));
    }
    final double limit = sim.player.projection.halfWidth + RaceSimulation.runoff;
    expect(sim.player.projection.lateral.abs(), lessThanOrEqualTo(limit + 0.5));
  });

  test('an eliminated car is ranked last', () {
    final RaceSimulation sim = _race(rivals: 2);
    _skipCountdown(sim);
    sim.eliminate(sim.cars[1]);
    expect(sim.cars[1].position, 3);
  });
}
