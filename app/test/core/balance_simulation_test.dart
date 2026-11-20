import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/logic/ai_driver.dart';
import 'package:ruach/core/logic/race_rules.dart';
import 'package:ruach/core/models/race_config.dart';

import 'logic/test_support.dart';

/// Runs a race with the player following the line and returns the player's
/// finishing position (1 = first) and the race's final state hash.
(int, int) _race(int seed, Difficulty difficulty) {
  final RaceConfig config = RaceConfig(
    track: testTrack(),
    vehicle: testVehicle,
    mode: RaceMode.quickRace,
    laps: 2,
    difficulty: difficulty,
    seed: seed,
    rivals: testRivals,
  );
  final RaceSimulation sim = RaceSimulation(config: config, controllers: AiDriver.forRace(config));
  int guard = 0;
  while (sim.phase != RacePhase.finished && guard < 200000) {
    sim.step(follow(sim, sim.player));
    guard++;
  }
  int hash = 17;
  for (final RaceCar c in sim.cars) {
    hash = (hash * 31 + (c.state.position.x * 100).round()) & 0x7fffffff;
    hash = (hash * 31 + (c.state.position.y * 100).round()) & 0x7fffffff;
  }
  final int position = sim.cars.where((RaceCar c) => c.progress > sim.player.progress).length + 1;
  return (position, hash);
}

void main() {
  test('the same seed gives exactly the same race', () {
    expect(_race(4, Difficulty.normal), _race(4, Difficulty.normal));
  });

  test('different seeds give different races', () {
    final Set<int> hashes = <int>{for (int s = 1; s <= 5; s++) _race(s, Difficulty.normal).$2};
    expect(hashes.length, greaterThan(1));
  });

  test('a harder setting is no easier to win', () {
    int wins(Difficulty d) {
      int w = 0;
      for (int s = 1; s <= 8; s++) {
        if (_race(s, d).$1 == 1) w++;
      }
      return w;
    }

    expect(wins(Difficulty.easy), greaterThanOrEqualTo(wins(Difficulty.hard)));
  });

  test('every race finishes with a legal position', () {
    for (int s = 1; s <= 6; s++) {
      final int position = _race(s, Difficulty.hard).$1;
      expect(position, inInclusiveRange(1, 6));
    }
  });
}
