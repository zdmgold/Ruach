import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/models/race_config.dart';
import 'package:ruach/core/models/race_result.dart';
import 'package:ruach/core/models/rival.dart';

RacerStanding _s(String id, int pos,
        {bool player = false, bool finished = true, List<int> laps = const <int>[60, 58]}) =>
    RacerStanding(
      racerId: id,
      isPlayer: player,
      position: pos,
      finished: finished,
      totalTime: Duration(seconds: laps.fold<int>(0, (int a, int b) => a + b)),
      lapTimes: <Duration>[for (final int l in laps) Duration(seconds: l)],
    );

void main() {
  test('best lap is the fastest completed lap', () {
    expect(_s('a', 1).bestLap, const Duration(seconds: 58));
    expect(_s('a', 1, laps: <int>[]).bestLap, isNull);
  });

  test('result exposes the player standing', () {
    final RaceResult r = RaceResult(
      trackId: 't',
      mode: RaceMode.quickRace,
      seed: 1,
      standings: <RacerStanding>[_s('rival_a', 1), _s('player', 2, player: true)],
      stars: 2,
      cleanDrivingScore: 0.8,
    );
    expect(r.playerPosition, 2);
    expect(r.playerWon, isFalse);
  });

  test('a player who did not finish has not won', () {
    final RaceResult r = RaceResult(
      trackId: 't',
      mode: RaceMode.elimination,
      seed: 1,
      standings: <RacerStanding>[_s('player', 1, player: true, finished: false)],
      stars: 0,
      cleanDrivingScore: 0,
    );
    expect(r.playerWon, isFalse);
  });

  test('invalid results are rejected', () {
    expect(
      () => RaceResult(
        trackId: 't',
        mode: RaceMode.quickRace,
        seed: 1,
        standings: <RacerStanding>[_s('a', 1)],
        stars: 1,
        cleanDrivingScore: 0.5,
      ),
      throwsAssertionError,
    );
    expect(
      () => RaceResult(
        trackId: 't',
        mode: RaceMode.quickRace,
        seed: 1,
        standings: <RacerStanding>[_s('player', 1, player: true)],
        stars: 4,
        cleanDrivingScore: 0.5,
      ),
      throwsAssertionError,
    );
  });

  test('rival values must be 0 to 1 and equality is by id', () {
    expect(
      () => Rival(id: 'r', name: 'n', team: 't', skill: 1.2, aggression: 0, consistency: 0),
      throwsAssertionError,
    );
    const Rival a = Rival(id: 'r', name: 'A', team: 'T', skill: 0.5, aggression: 0.5, consistency: 0.5);
    const Rival b = Rival(id: 'r', name: 'B', team: 'T', skill: 0.1, aggression: 0.1, consistency: 0.1);
    expect(a, b);
  });
}
