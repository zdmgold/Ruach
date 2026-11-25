import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/logic/catalog_ids.dart';
import 'package:ruach/core/logic/milestone_rules.dart';
import 'package:ruach/core/logic/review_rule.dart';
import 'package:ruach/core/models/progress.dart';
import 'package:ruach/core/models/race_config.dart';
import 'package:ruach/core/models/race_result.dart';
import 'package:ruach/core/models/track.dart';
import 'package:ruach/core/models/upgrade.dart';

Progress _cleared(Iterable<String> ids) => Progress(stars: <String, int>{for (final String id in ids) id: 1});

void main() {
  group('Milestones', () {
    test('a new player has reached none', () {
      expect(Milestones.reached(Progress()), isEmpty);
    });

    test('an era is complete only when all four of its tracks are cleared', () {
      final List<String> first = TrackIds.journey.take(4).toList();
      expect(Milestones.reached(_cleared(first.take(3))), isEmpty);
      expect(Milestones.reached(_cleared(first)), <String>[Milestones.eraId(Era.chariotAge)]);
    });

    test('an upgrade at its highest level and the first spent Gift each count', () {
      final Progress p = Progress(
        giftsSpent: 1,
        upgrades: UpgradeLevels.fromMap(<UpgradeKind, int>{UpgradeKind.might: UpgradeLevels.maxLevel}),
      );
      expect(
        Milestones.reached(p),
        <String>[Milestones.maxedId(UpgradeKind.might), Milestones.firstGiftSpent],
      );
    });

    test('a milestone already seen is not due again', () {
      final Progress p = Progress(giftsSpent: 3, milestonesSeen: <String>{Milestones.firstGiftSpent});
      expect(Milestones.reached(p), contains(Milestones.firstGiftSpent));
      expect(Milestones.due(p), isEmpty);
    });

    test('ids parse back to their era and upgrade', () {
      expect(Milestones.eraOf(Milestones.eraId(Era.gospelRoads)), Era.gospelRoads);
      expect(Milestones.upgradeOf(Milestones.maxedId(UpgradeKind.wisdom)), UpgradeKind.wisdom);
      expect(Milestones.eraOf(Milestones.firstGiftSpent), isNull);
      expect(Milestones.upgradeOf(Milestones.firstGiftSpent), isNull);
    });

    test('the verse seed is stable and differs between milestones', () {
      expect(Milestones.seedOf('a'), Milestones.seedOf('a'));
      expect(Milestones.seedOf('era:today'), isNot(Milestones.seedOf('era:gospelRoads')));
    });
  });

  group('ReviewRule', () {
    RaceResult result(int position, {bool finished = true}) => RaceResult(
          trackId: TrackIds.journey.first,
          mode: RaceMode.quickRace,
          seed: 1,
          standings: <RacerStanding>[
            RacerStanding(
              racerId: 'player',
              isPlayer: true,
              position: position,
              finished: finished,
              totalTime: const Duration(seconds: 90),
              lapTimes: const <Duration>[Duration(seconds: 30)],
            ),
          ],
          stars: 1,
          cleanDrivingScore: 0.5,
        );

    test('asks after a podium finish once enough races are done', () {
      expect(ReviewRule.shouldAsk(Progress(racesFinished: 3), result(2)), isTrue);
    });

    test('never asks after a poor result, an unfinished race or too early', () {
      expect(ReviewRule.shouldAsk(Progress(racesFinished: 9), result(4)), isFalse);
      expect(ReviewRule.shouldAsk(Progress(racesFinished: 9), result(1, finished: false)), isFalse);
      expect(ReviewRule.shouldAsk(Progress(racesFinished: 2), result(1)), isFalse);
    });

    test('never asks twice', () {
      expect(
        ReviewRule.shouldAsk(Progress(racesFinished: 9, reviewAsked: true), result(1)),
        isFalse,
      );
    });
  });
}
