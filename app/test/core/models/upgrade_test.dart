import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/models/upgrade.dart';

void main() {
  test('ids round-trip and are unique', () {
    final Set<String> ids = <String>{};
    for (final UpgradeKind kind in UpgradeKind.values) {
      expect(UpgradeKind.fromId(kind.id), kind);
      ids.add(kind.id);
    }
    expect(ids.length, UpgradeKind.values.length);
    expect(UpgradeKind.fromId('nope'), isNull);
  });

  test('levels start at zero and change immutably', () {
    const UpgradeLevels none = UpgradeLevels.none;
    final UpgradeLevels one = none.withLevel(UpgradeKind.might, 3);
    expect(none.levelOf(UpgradeKind.might), 0);
    expect(one.levelOf(UpgradeKind.might), 3);
    expect(one.totalLevels, 3);
  });

  test('levels are forced into range', () {
    final UpgradeLevels l = UpgradeLevels.fromMap(<UpgradeKind, int>{
      UpgradeKind.wisdom: 99,
      UpgradeKind.counsel: -4,
    });
    expect(l.levelOf(UpgradeKind.wisdom), UpgradeLevels.maxLevel);
    expect(l.levelOf(UpgradeKind.counsel), 0);
    expect(none().withLevel(UpgradeKind.might, 50).levelOf(UpgradeKind.might), 5);
  });

  test('isMaxed and equality', () {
    UpgradeLevels l = UpgradeLevels.none;
    for (final UpgradeKind k in UpgradeKind.values) {
      l = l.withLevel(k, UpgradeLevels.maxLevel);
    }
    expect(l.isMaxed, isTrue);
    expect(l.totalLevels, 30);
    expect(UpgradeLevels.none.isMaxed, isFalse);
    expect(UpgradeLevels.none, UpgradeLevels.fromMap(<UpgradeKind, int>{}));
    expect(l == UpgradeLevels.none, isFalse);
  });
}

UpgradeLevels none() => UpgradeLevels.none;
