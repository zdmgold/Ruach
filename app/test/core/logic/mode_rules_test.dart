import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/logic/ai_driver.dart';
import 'package:ruach/core/logic/catalog_ids.dart';
import 'package:ruach/core/logic/mode_rules.dart';
import 'package:ruach/core/logic/race_rules.dart';
import 'package:ruach/core/models/progress.dart';
import 'package:ruach/core/models/race_config.dart';
import 'package:ruach/core/models/rival.dart';

import 'test_support.dart';

Progress _cleared(int upTo) => Progress(
      stars: <String, int>{for (int i = 0; i < upTo; i++) TrackIds.journey[i]: 1},
    );

RaceConfig _build(RaceMode mode, {int seed = 3}) => ModeRules.build(
      mode: mode,
      track: testTrack(),
      vehicle: testVehicle,
      roster: testRivals,
      seed: seed,
    );

void main() {
  group('Unlocks', () {
    test('a new player has track 1 only', () {
      final Progress p = Progress.fresh();
      expect(Unlocks.track('nile_banks', p), isTrue);
      expect(Unlocks.track('red_sea_crossing', p), isFalse);
      expect(Unlocks.track('nile_banks_now', p), isFalse);
      expect(Unlocks.track('nonsense', p), isFalse);
    });

    test('tracks open one after another', () {
      expect(Unlocks.track('red_sea_crossing', _cleared(1)), isTrue);
      expect(Unlocks.track('sinai_wilderness', _cleared(1)), isFalse);
      expect(Unlocks.track('highland_switchbacks', _cleared(15)), isTrue);
    });

    test('a Now variant opens after its Then track is cleared', () {
      expect(Unlocks.track('nile_banks_now', _cleared(1)), isTrue);
      expect(Unlocks.track('red_sea_crossing_now', _cleared(1)), isFalse);
    });

    test('vehicles', () {
      final Progress fresh = Progress.fresh();
      expect(Unlocks.vehicle(VehicleIds.lightChariot, fresh), isTrue);
      expect(Unlocks.vehicle(VehicleIds.heavyChariot, fresh), isTrue);
      expect(Unlocks.vehicle(VehicleIds.hatch, fresh), isFalse);
      expect(Unlocks.vehicle(VehicleIds.roadCart, _cleared(8)), isTrue);
      expect(Unlocks.vehicle(VehicleIds.roadster, _cleared(7)), isFalse);
      expect(Unlocks.vehicle('mystery', _cleared(16)), isFalse);
    });

    test('modes', () {
      final Progress fresh = Progress.fresh();
      expect(Unlocks.mode(RaceMode.journey, fresh), isTrue);
      expect(Unlocks.mode(RaceMode.dailyRun, fresh), isTrue);
      expect(Unlocks.mode(RaceMode.quickRace, fresh), isFalse);
      expect(Unlocks.mode(RaceMode.quickRace, _cleared(1)), isTrue);
      expect(Unlocks.mode(RaceMode.timeTrial, _cleared(1)), isTrue);
      expect(Unlocks.mode(RaceMode.escapeRun, _cleared(1)), isFalse);
      expect(Unlocks.mode(RaceMode.escapeRun, _cleared(2)), isTrue);
      expect(Unlocks.mode(RaceMode.elimination, _cleared(4)), isFalse);
      expect(Unlocks.mode(RaceMode.elimination, _cleared(5)), isTrue);
      expect(Unlocks.mode(RaceMode.weeklyCircuit, fresh), isFalse);
      expect(
        Unlocks.mode(
          RaceMode.weeklyCircuit,
          Progress(dailyRuns: <String, DailyRunRecord>{
            '2026-11-20': const DailyRunRecord(attempts: 1, completed: true, bestPosition: 2),
          }),
        ),
        isTrue,
      );
    });
  });

  group('ModeRules', () {
    test('difficulty ramps with the track number', () {
      expect(ModeRules.journeyDifficulty(1), Difficulty.easy);
      expect(ModeRules.journeyDifficulty(3), Difficulty.easy);
      expect(ModeRules.journeyDifficulty(4), Difficulty.normal);
      expect(ModeRules.journeyDifficulty(12), Difficulty.normal);
      expect(ModeRules.journeyDifficulty(13), Difficulty.hard);
    });

    test('skill rises along the journey and stays in range', () {
      final Rival r = testRivals.first;
      double last = 0;
      for (int n = 1; n <= 16; n++) {
        final double s = ModeRules.skillFor(r, n);
        expect(s, greaterThan(last));
        expect(s, inInclusiveRange(0.05, 0.98));
        last = s;
      }
    });

    test('picking rivals is seeded and complete', () {
      final List<Rival> a = ModeRules.pickRivals(testRivals, 5, 7);
      final List<Rival> b = ModeRules.pickRivals(testRivals, 5, 7);
      expect(a.map((Rival r) => r.id).toList(), b.map((Rival r) => r.id).toList());
      expect(a.length, 5);
      expect(a.map((Rival r) => r.id).toSet().length, 5);
      final Set<String> orders = <String>{
        for (int s = 0; s < 20; s++) ModeRules.pickRivals(testRivals, 5, s).map((Rival r) => r.id).join(),
      };
      expect(orders.length, greaterThan(5));
    });

    test('a short roster gives a short field', () {
      expect(ModeRules.pickRivals(testRivals.sublist(0, 2), 1, 1).length, 2);
      expect(ModeRules.pickRivals(testRivals, 1, 1, count: 3).length, 3);
    });

    test('journey sets its own difficulty and laps', () {
      final RaceConfig c = _build(RaceMode.journey);
      expect(c.laps, 3);
      expect(c.difficulty, Difficulty.easy);
      expect(c.rivals.length, 5);
    });

    test('time trial and escape run have no rivals', () {
      expect(_build(RaceMode.timeTrial).rivals, isEmpty);
      final RaceConfig e = _build(RaceMode.escapeRun);
      expect(e.rivals, isEmpty);
      expect(e.laps, ModeRules.escapeLaps);
    });

    test('elimination runs one lap per car dropped', () {
      final RaceConfig c = _build(RaceMode.elimination);
      expect(c.laps, 5);
      expect(c.rivals.length, 5);
    });
  });

  group('EliminationRule', () {
    test('drops one car each time the leader finishes a lap', () {
      final RaceConfig config = _build(RaceMode.elimination);
      final RaceSimulation sim = RaceSimulation(config: config, controllers: AiDriver.forRace(config));
      final EliminationRule rule = EliminationRule();
      int guard = 0;
      while (sim.phase != RacePhase.finished && guard < 400000) {
        sim.step(follow(sim, sim.player));
        rule.update(sim);
        guard++;
      }
      expect(sim.phase, RacePhase.finished);
      expect(rule.dropped, greaterThan(0));
      expect(rule.dropped, lessThanOrEqualTo(5));
      expect(sim.cars.where((RaceCar c) => c.eliminated).length, rule.dropped);
    });
  });

  group('EscapeRun', () {
    test('a fast player pulls away at first', () {
      final EscapeRun run = EscapeRun();
      for (int i = 0; i < 300; i++) {
        run.step(40);
      }
      expect(run.gap, greaterThan(60));
      expect(run.caught, isFalse);
      expect(run.danger, 0);
    });

    test('a slow player is caught', () {
      final EscapeRun run = EscapeRun();
      int ticks = 0;
      while (!run.caught && ticks < 100000) {
        run.step(10);
        ticks++;
      }
      expect(run.caught, isTrue);
      expect(run.danger, 1);
    });

    test('the wall speeds up and is capped', () {
      final EscapeRun run = EscapeRun();
      final double first = run.wallSpeed;
      for (int i = 0; i < 60 * 60; i++) {
        run.step(30);
      }
      expect(run.wallSpeed, greaterThan(first));
      for (int i = 0; i < 60 * 600; i++) {
        run.step(60);
      }
      expect(run.wallSpeed, EscapeRun.maxWallSpeed);
    });

    test('once caught the gap stays put', () {
      final EscapeRun run = EscapeRun(startGap: 1);
      for (int i = 0; i < 600; i++) {
        run.step(0);
      }
      final double gap = run.gap;
      run.step(100);
      expect(run.gap, gap);
    });
  });
}
