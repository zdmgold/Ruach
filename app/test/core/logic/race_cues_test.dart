import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/logic/race_cues.dart';
import 'package:ruach/core/logic/race_rules.dart';
import 'package:ruach/core/models/drive_input.dart';

import 'test_support.dart';

RaceSimulation _race() => RaceSimulation(config: testConfig(laps: 1, rivals: 0), controllers: const []);

void main() {
  test('the countdown ticks once per second, then Go', () {
    final RaceSimulation sim = _race();
    final RaceCueDetector detector = RaceCueDetector();
    final List<RaceCue> all = <RaceCue>[];
    for (int i = 0; i < RaceSimulation.countdownTicks + 2; i++) {
      all.addAll(detector.poll(sim));
      sim.step(DriveInput.idle);
    }
    all.addAll(detector.poll(sim));
    expect(all.where((RaceCue c) => c == RaceCue.countdownTick).length, 3);
    expect(all.where((RaceCue c) => c == RaceCue.go).length, 1);
    expect(all.indexOf(RaceCue.go), greaterThan(all.lastIndexOf(RaceCue.countdownTick)));
  });

  test('a win gives one finish cue and nothing repeats', () {
    final RaceSimulation sim = _race();
    final RaceCueDetector detector = RaceCueDetector();
    for (int i = 0; i < RaceSimulation.countdownTicks + 5; i++) {
      sim.step(DriveInput.idle);
    }
    detector.poll(sim);
    sim.player.tracker.forceFinish(sim.elapsedSeconds);
    sim.step(DriveInput.idle);
    expect(detector.poll(sim), contains(RaceCue.finishWin));
    expect(detector.poll(sim), isEmpty);
  });
}
