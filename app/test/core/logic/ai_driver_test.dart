import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/logic/ai_driver.dart';
import 'package:ruach/core/logic/race_rules.dart';
import 'package:ruach/core/models/drive_input.dart';
import 'package:ruach/core/models/race_config.dart';
import 'package:ruach/core/models/rival.dart';

import 'test_support.dart';

RaceConfig _config({
  int laps = 2,
  int seed = 1,
  Difficulty difficulty = Difficulty.normal,
  List<Rival>? rivals,
}) =>
    RaceConfig(
      track: testTrack(),
      vehicle: testVehicle,
      mode: RaceMode.quickRace,
      laps: laps,
      difficulty: difficulty,
      seed: seed,
      rivals: rivals ?? testRivals,
    );

RaceSimulation _sim(RaceConfig config) => RaceSimulation(
      config: config,
      controllers: AiDriver.forRace(config),
    );

void _runToEnd(RaceSimulation sim) {
  int guard = 0;
  while (sim.phase != RacePhase.finished && guard < 200000) {
    sim.step(follow(sim, sim.player));
    guard++;
  }
}

Rival _rival(String id, double skill) => Rival(
      id: id,
      name: id,
      team: 'T',
      skill: skill,
      aggression: 0.5,
      consistency: 0.5,
    );

/// Steps the race (player on the line follower) until [ticks] racing steps.
void _runFor(RaceSimulation sim, int ticks) {
  while (sim.phase != RacePhase.finished && sim.raceTick < ticks) {
    sim.step(follow(sim, sim.player));
  }
}

double _progress(RaceSimulation sim, String id) =>
    sim.cars.firstWhere((RaceCar c) => c.id == id).progress;

void main() {
  test('a full field of rivals finishes the race', () {
    final RaceSimulation sim = _sim(_config());
    _runToEnd(sim);
    expect(sim.phase, RacePhase.finished);
    for (final RaceCar car in sim.cars.where((RaceCar c) => !c.isPlayer)) {
      expect(car.tracker.lap, greaterThanOrEqualTo(1), reason: car.id);
    }
  });

  test('rivals stay mostly on the road', () {
    final RaceSimulation sim = _sim(_config(laps: 1));
    final Map<String, int> off = <String, int>{};
    int steps = 0;
    while (sim.phase != RacePhase.finished && steps < 100000) {
      sim.step(follow(sim, sim.player));
      steps++;
      if (sim.phase != RacePhase.racing) continue;
      for (final RaceCar car in sim.cars.where((RaceCar c) => !c.isPlayer)) {
        if (!car.projection.onTrack) off[car.id] = (off[car.id] ?? 0) + 1;
      }
    }
    for (final Rival r in testRivals) {
      expect((off[r.id] ?? 0) / sim.raceTick, lessThan(0.1), reason: r.id);
    }
  });

  test('the same seed gives the same race and another seed a different one', () {
    int hashAfter(int seed) {
      final RaceSimulation sim = _sim(_config(seed: seed));
      for (int i = 0; i < 1800; i++) {
        sim.step(follow(sim, sim.player));
      }
      return sim.stateHash();
    }

    expect(hashAfter(7), hashAfter(7));
    expect(hashAfter(7), isNot(hashAfter(8)));
  });

  test('a more skilled rival covers more ground than a weaker one', () {
    int skilledAhead = 0;
    for (int seed = 1; seed <= 5; seed++) {
      final RaceSimulation sim = _sim(
        _config(seed: seed, rivals: <Rival>[_rival('weak', 0.1), _rival('strong', 0.95)]),
      );
      _runFor(sim, 3000);
      if (_progress(sim, 'strong') > _progress(sim, 'weak')) skilledAhead++;
    }
    expect(skilledAhead, greaterThanOrEqualTo(4));
  });

  test('harder difficulty covers more ground than easy for the same rival', () {
    double covered(Difficulty d) {
      final RaceSimulation sim = _sim(
        _config(difficulty: d, rivals: <Rival>[_rival('solo', 0.6)]),
      );
      _runFor(sim, 3000);
      return _progress(sim, 'solo');
    }

    expect(covered(Difficulty.hard), greaterThan(covered(Difficulty.easy)));
  });

  test('rubber-banding is capped and eases the leader', () {
    expect(AiTuning.rubberBand(0), 1);
    expect(AiTuning.rubberBand(10000), closeTo(1 - AiTuning.rubberBandEase, 1e-9));
    expect(AiTuning.rubberBand(-10000), closeTo(1 + AiTuning.rubberBandCap, 1e-9));
    expect(AiTuning.rubberBand(50), lessThan(1));
    expect(AiTuning.rubberBand(-50), greaterThan(1));
  });

  test('rivals wait for the lights and then use the boost', () {
    final RaceSimulation sim = _sim(_config(laps: 3));
    bool boosted = false;
    int steps = 0;
    while (sim.phase != RacePhase.finished && steps < 100000) {
      sim.step(const DriveInput(throttle: 1));
      steps++;
      if (sim.cars.any((RaceCar c) => !c.isPlayer && c.boosting)) boosted = true;
      if (sim.phase == RacePhase.countdown) {
        expect(sim.cars.every((RaceCar c) => c.state.speed == 0), isTrue);
      }
    }
    expect(boosted, isTrue);
  });

  test('one driver per rival, in order', () {
    final List<AiDriver> drivers = AiDriver.forRace(_config());
    expect(drivers.map((AiDriver d) => d.rival.id).toList(), testRivals.map((Rival r) => r.id).toList());
  });
}
