import 'package:ruach/core/logic/car_physics.dart';
import 'package:ruach/core/models/progress.dart';
import 'package:ruach/core/models/upgrade.dart';

/// Which unit an upgrade's effect is shown in.
enum EffectUnit { percent, metres }

/// Cost, effect and spending of the six upgrades (blueprint section 2). One
/// Gift is earned per star; a level costs its number (1, 2, 3, 4, 5), so one
/// upgrade costs 15 and the full set of six costs 90 Gifts. Upgrades are earned
/// by play and are never sold.
abstract final class UpgradeRules {
  /// Gifts for the next level of an upgrade at [currentLevel], or null if it
  /// is already at the top.
  static int? costOfNext(int currentLevel) {
    if (currentLevel < 0 || currentLevel >= UpgradeLevels.maxLevel) return null;
    return currentLevel + 1;
  }

  /// Gifts for a whole upgrade from level 0 to the top.
  static int get costOfOneUpgrade {
    int total = 0;
    for (int level = 0; level < UpgradeLevels.maxLevel; level++) {
      total += level + 1;
    }
    return total;
  }

  /// Gifts for all six.
  static int get costOfEverything => costOfOneUpgrade * UpgradeKind.values.length;

  static bool canBuy(Progress progress, UpgradeKind kind) {
    final int? cost = costOfNext(progress.upgrades.levelOf(kind));
    return cost != null && progress.gifts >= cost;
  }

  /// The progress after buying the next level of [kind], or null if the
  /// upgrade is maxed or there are not enough Gifts.
  static Progress? buy(Progress progress, UpgradeKind kind) {
    final int level = progress.upgrades.levelOf(kind);
    final int? cost = costOfNext(level);
    if (cost == null || progress.gifts < cost) return null;
    return progress.copyWith(
      giftsSpent: progress.giftsSpent + cost,
      upgrades: progress.upgrades.withLevel(kind, level + 1),
    );
  }

  /// What one level adds, for the effect line beside each upgrade.
  static double effectPerLevel(UpgradeKind kind) => switch (kind) {
        UpgradeKind.wisdom => 10, // percent faster Ruach meter fill
        UpgradeKind.understanding => 3, // percent more grip
        UpgradeKind.counsel => 30, // metres of racing-line guide
        UpgradeKind.might => 2, // percent more top speed
        UpgradeKind.knowledge => 20, // percent quicker recovery
        UpgradeKind.fearOfTheLord => 12, // percent less lost on rough ground
      };

  static EffectUnit effectUnit(UpgradeKind kind) =>
      kind == UpgradeKind.counsel ? EffectUnit.metres : EffectUnit.percent;

  /// The total effect at [level].
  static double effectAt(UpgradeKind kind, int level) => effectPerLevel(kind) * level;

  /// Length of the racing-line guide: 40 m with no Counsel, plus 30 m a level.
  static double guideLengthMetres(UpgradeLevels levels) =>
      40 + effectAt(UpgradeKind.counsel, levels.levelOf(UpgradeKind.counsel));

  /// The multipliers the physics uses for a player with these [levels].
  static CarTuning tuningFor(UpgradeLevels levels) => CarTuning(
        topSpeedMultiplier: 1 + effectAt(UpgradeKind.might, levels.levelOf(UpgradeKind.might)) / 100,
        gripMultiplier:
            1 + effectAt(UpgradeKind.understanding, levels.levelOf(UpgradeKind.understanding)) / 100,
        steadiness:
            effectAt(UpgradeKind.fearOfTheLord, levels.levelOf(UpgradeKind.fearOfTheLord)) / 100,
        recovery: effectAt(UpgradeKind.knowledge, levels.levelOf(UpgradeKind.knowledge)) / 100,
        meterFillMultiplier:
            1 + effectAt(UpgradeKind.wisdom, levels.levelOf(UpgradeKind.wisdom)) / 100,
      );
}
