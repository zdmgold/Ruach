import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/logic/ai_driver.dart';
import 'package:ruach/core/logic/boost_pads.dart';
import 'package:ruach/core/logic/car_physics.dart';
import 'package:ruach/core/logic/drive_assist.dart';
import 'package:ruach/core/logic/race_rules.dart';
import 'package:ruach/core/models/drive_input.dart';
import 'package:ruach/core/models/race_config.dart';

import 'test_support.dart';

const DriveInput _straight = DriveInput(throttle: 1);

RaceSimulation _sim({int rivals = 0, bool pads = false, int laps = 2}) {
  final RaceConfig config = testConfig(laps: laps, rivals: rivals);
  return RaceSimulation(
    config: config,
    controllers: AiDriver.forRace(config),
    assist: const PlayerAssist(),
    boostPads: pads,
  );
}

void main() {
  group('PlayerAssist', () {
    test('with no touch at all the car stays on the road and finishes', () {
      final RaceSimulation sim = _sim();
      int onTrack = 0;
      int ticks = 0;
      while (sim.phase != RacePhase.finished && ticks < 60 * 400) {
        sim.step(_straight);
        if (sim.phase == RacePhase.racing && sim.player.projection.onTrack) onTrack++;
        ticks++;
      }
      expect(sim.player.finished, isTrue);
      expect(onTrack / sim.raceTick, greaterThan(0.95));
    });

    test('touching right moves the car to the right of the road, left to the left', () {
      double meanLateral(double steer) {
        final RaceSimulation sim = _sim();
        double total = 0;
        int n = 0;
        for (int i = 0; i < 60 * 30; i++) {
          sim.step(DriveInput(steer: steer, throttle: 1));
          if (sim.raceTick > 60 * 8) {
            total += sim.player.projection.lateral;
            n++;
          }
        }
        return total / n;
      }

      final double right = meanLateral(1);
      final double left = meanLateral(-1);
      expect(right, greaterThan(left + 2));
    });

    test('a touch never takes the car off the road', () {
      final RaceSimulation sim = _sim();
      int off = 0;
      for (int i = 0; i < 60 * 60; i++) {
        sim.step(const DriveInput(steer: 1, throttle: 1));
        if (sim.phase == RacePhase.racing && !sim.player.projection.onTrack) off++;
      }
      expect(off, lessThan(60));
    });

    test('it slows for a corner by itself', () {
      final RaceSimulation sim = _sim();
      double fastest = 0;
      double slowestAfter = 1000;
      for (int i = 0; i < 60 * 40; i++) {
        sim.step(_straight);
        final double v = sim.player.state.forwardSpeed;
        if (v > fastest) fastest = v;
        if (fastest > 30 && v < slowestAfter) slowestAfter = v;
      }
      expect(slowestAfter, lessThan(fastest - 3));
    });

    test('it adds grip and steadiness but keeps the rest of the tuning', () {
      final CarTuning t = const PlayerAssist().stabilise(const CarTuning(topSpeedMultiplier: 1.1));
      expect(t.gripMultiplier, greaterThan(1));
      expect(t.steadiness, greaterThanOrEqualTo(0.5));
      expect(t.topSpeedMultiplier, 1.1);
    });

    test('a car that is not assisted is driven exactly as asked', () {
      final RaceConfig config = testConfig();
      final RaceSimulation plain = RaceSimulation(config: config);
      final RaceSimulation assisted = _sim();
      for (int i = 0; i < 60 * 10; i++) {
        plain.step(const DriveInput(throttle: 1));
        assisted.step(const DriveInput(throttle: 1));
      }
      expect(plain.player.state.position.x, isNot(assisted.player.state.position.x));
    });
  });

  group('BoostPads', () {
    test('the same track always has the same pads, spread round the lap', () {
      final RaceSimulation a = _sim(pads: true);
      final RaceSimulation b = _sim(pads: true);
      expect(a.pads.length, greaterThanOrEqualTo(3));
      expect(a.pads.length, b.pads.length);
      for (int i = 0; i < a.pads.length; i++) {
        expect(a.pads[i].distance, b.pads[i].distance);
        expect(a.pads[i].lateral, b.pads[i].lateral);
        expect(a.pads[i].distance, inInclusiveRange(30, a.geometry.length - 30));
        expect(a.pads[i].lateral.abs(), lessThan(a.geometry.widthAt(a.pads[i].distance) / 2));
      }
    });

    test('a race without pads has none', () {
      expect(_sim().pads, isEmpty);
    });

    test('hit is true on the pad and false beside it or along the road', () {
      const BoostPad pad = BoostPad(distance: 100, lateral: 2);
      expect(BoostPads.hit(pad, 100, 2, 1000), isTrue);
      expect(BoostPads.hit(pad, 103, 3, 1000), isTrue);
      expect(BoostPads.hit(pad, 100, 6, 1000), isFalse);
      expect(BoostPads.hit(pad, 120, 2, 1000), isFalse);
      expect(BoostPads.hit(const BoostPad(distance: 2, lateral: 0), 998, 0, 1000), isTrue);
    });

    test('driving over a pad starts a boost', () {
      final RaceSimulation sim = _sim(pads: true, laps: 3);
      const double half = 7;
      bool sawBoost = false;
      for (int i = 0; i < 60 * 150 && sim.phase != RacePhase.finished; i++) {
        double steer = 0;
        for (final BoostPad pad in sim.pads) {
          final double ahead = (pad.distance - sim.player.projection.distance) % sim.geometry.length;
          if (ahead < 80) {
            steer = (pad.lateral / (0.65 * half)).clamp(-1.0, 1.0).toDouble();
            break;
          }
        }
        sim.step(DriveInput(steer: steer, throttle: 1));
        if (sim.player.boosting) sawBoost = true;
      }
      expect(sawBoost, isTrue);
    });
  });

  group('catch-up', () {
    test('a rival far ahead of the player eases off more than one behind pushes', () {
      final double ease = 1 - AiTuning.rubberBand(10000);
      final double push = AiTuning.rubberBand(-10000) - 1;
      expect(ease, greaterThan(push));
    });

    test('with the assist the player stays within sight of the field', () {
      final RaceSimulation sim = _sim(rivals: 5, laps: 2);
      double worst = 0;
      for (int i = 0; i < 60 * 200 && sim.phase != RacePhase.finished; i++) {
        sim.step(_straight);
        if (sim.phase != RacePhase.racing) continue;
        double lead = 0;
        for (final RaceCar c in sim.cars) {
          if (c.progress - sim.player.progress > lead) lead = c.progress - sim.player.progress;
        }
        if (lead > worst) worst = lead;
      }
      expect(worst, lessThan(400));
    });
  });
}
