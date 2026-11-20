import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/logic/star_rules.dart';
import 'package:ruach/core/models/progress.dart';
import 'package:ruach/core/models/race_config.dart';

void main() {
  test('position stars: win 3, top two 2, top four 1, otherwise none', () {
    expect(<int>[for (int p = 1; p <= 6; p++) StarRules.forPosition(p, finished: true)], <int>[3, 2, 1, 1, 0, 0]);
  });

  test('a car that did not finish earns nothing', () {
    expect(StarRules.forPosition(1, finished: false), 0);
  });

  test('time trial stars follow the par lap', () {
    expect(StarRules.forTimeTrial(70, 60), 0);
    expect(StarRules.forTimeTrial(68, 60), 1);
    expect(StarRules.forTimeTrial(62, 60), 2);
    expect(StarRules.forTimeTrial(60, 60), 3);
    expect(StarRules.forTimeTrial(0, 60), 0);
  });

  test('escape run stars follow the distance', () {
    expect(StarRules.forEscape(500), 0);
    expect(StarRules.forEscape(1000), 1);
    expect(StarRules.forEscape(3500), 2);
    expect(StarRules.forEscape(9000), 3);
  });

  test('time trial and escape run keep their own stars', () {
    expect(StarRules.starKey(RaceMode.journey, 'nile_banks'), 'nile_banks');
    expect(StarRules.starKey(RaceMode.quickRace, 'nile_banks'), 'nile_banks');
    expect(StarRules.starKey(RaceMode.timeTrial, 'nile_banks'), 'tt:nile_banks');
    expect(StarRules.starKey(RaceMode.escapeRun, 'nile_banks'), 'escape:nile_banks');
  });

  test('only an improvement earns Gifts, one per new star', () {
    Progress p = Progress.fresh();
    p = StarRules.award(p, 'nile_banks', 2);
    expect(p.starsOn('nile_banks'), 2);
    expect(p.giftsEarned, 2);
    p = StarRules.award(p, 'nile_banks', 1);
    expect(p.starsOn('nile_banks'), 2);
    expect(p.giftsEarned, 2);
    p = StarRules.award(p, 'nile_banks', 3);
    expect(p.giftsEarned, 3);
    expect(p.totalStars, 3);
  });

  test('stars are kept within 0 to 3', () {
    final Progress p = StarRules.award(Progress.fresh(), 'a', 9);
    expect(p.starsOn('a'), 3);
    expect(StarRules.award(Progress.fresh(), 'a', -2).starsOn('a'), 0);
  });
}
