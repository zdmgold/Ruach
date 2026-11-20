import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/logic/car_physics.dart';
import 'package:ruach/core/logic/upgrade_rules.dart';
import 'package:ruach/core/models/progress.dart';
import 'package:ruach/core/models/upgrade.dart';

void main() {
  test('levels cost 1 to 5 Gifts, 15 an upgrade and 90 for all six', () {
    expect(<int?>[for (int l = 0; l <= 5; l++) UpgradeRules.costOfNext(l)], <int?>[1, 2, 3, 4, 5, null]);
    expect(UpgradeRules.costOfOneUpgrade, 15);
    expect(UpgradeRules.costOfEverything, 90);
  });

  test('buying spends Gifts and raises the level', () {
    final Progress p = Progress(giftsEarned: 4);
    final Progress? bought = UpgradeRules.buy(p, UpgradeKind.might);
    expect(bought, isNotNull);
    expect(bought!.upgrades.levelOf(UpgradeKind.might), 1);
    expect(bought.gifts, 3);
    final Progress? second = UpgradeRules.buy(bought, UpgradeKind.might);
    expect(second!.gifts, 1);
    expect(UpgradeRules.canBuy(second, UpgradeKind.might), isFalse);
    expect(UpgradeRules.buy(second, UpgradeKind.might), isNull);
  });

  test('a maxed upgrade cannot be bought even with Gifts to spare', () {
    final Progress p = Progress(
      giftsEarned: 100,
      upgrades: UpgradeLevels.none.withLevel(UpgradeKind.wisdom, UpgradeLevels.maxLevel),
    );
    expect(UpgradeRules.canBuy(p, UpgradeKind.wisdom), isFalse);
    expect(UpgradeRules.buy(p, UpgradeKind.wisdom), isNull);
  });

  test('buying everything with exactly 90 Gifts leaves none', () {
    Progress p = Progress(giftsEarned: 90);
    for (final UpgradeKind kind in UpgradeKind.values) {
      for (int i = 0; i < UpgradeLevels.maxLevel; i++) {
        p = UpgradeRules.buy(p, kind)!;
      }
    }
    expect(p.upgrades.isMaxed, isTrue);
    expect(p.gifts, 0);
  });

  test('no upgrades means no change', () {
    final CarTuning t = UpgradeRules.tuningFor(UpgradeLevels.none);
    expect(t.topSpeedMultiplier, 1);
    expect(t.gripMultiplier, 1);
    expect(t.steadiness, 0);
    expect(t.recovery, 0);
    expect(t.meterFillMultiplier, 1);
    expect(UpgradeRules.guideLengthMetres(UpgradeLevels.none), 40);
  });

  test('full upgrades give the documented maximums', () {
    UpgradeLevels full = UpgradeLevels.none;
    for (final UpgradeKind k in UpgradeKind.values) {
      full = full.withLevel(k, 5);
    }
    final CarTuning t = UpgradeRules.tuningFor(full);
    expect(t.topSpeedMultiplier, closeTo(1.10, 1e-9));
    expect(t.gripMultiplier, closeTo(1.15, 1e-9));
    expect(t.steadiness, closeTo(0.6, 1e-9));
    expect(t.recovery, closeTo(1.0, 1e-9));
    expect(t.meterFillMultiplier, closeTo(1.5, 1e-9));
    expect(UpgradeRules.guideLengthMetres(full), 190);
  });

  test('every upgrade has an effect and counsel is in metres', () {
    for (final UpgradeKind k in UpgradeKind.values) {
      expect(UpgradeRules.effectPerLevel(k), greaterThan(0));
    }
    expect(UpgradeRules.effectUnit(UpgradeKind.counsel), EffectUnit.metres);
    expect(UpgradeRules.effectUnit(UpgradeKind.might), EffectUnit.percent);
  });
}
