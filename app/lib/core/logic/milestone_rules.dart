import 'package:ruach/core/catalog/tracks.dart';
import 'package:ruach/core/models/progress.dart';
import 'package:ruach/core/models/track.dart';
import 'package:ruach/core/models/upgrade.dart';

/// Moments of progress that earn a one-time verse card: finishing an era,
/// taking an upgrade to its highest level, and spending the first Gift.
/// Each id is celebrated once ([Progress.milestonesSeen]).
abstract final class Milestones {
  static const String firstGiftSpent = 'first-gift-spent';
  static const String _eraPrefix = 'era:';
  static const String _maxedPrefix = 'maxed:';

  static String eraId(Era era) => '$_eraPrefix${era.name}';

  static String maxedId(UpgradeKind kind) => '$_maxedPrefix${kind.id}';

  /// The era a milestone id is for, or null.
  static Era? eraOf(String id) {
    if (!id.startsWith(_eraPrefix)) return null;
    final String name = id.substring(_eraPrefix.length);
    for (final Era era in Era.values) {
      if (era.name == name) return era;
    }
    return null;
  }

  /// The upgrade a milestone id is for, or null.
  static UpgradeKind? upgradeOf(String id) =>
      id.startsWith(_maxedPrefix) ? UpgradeKind.fromId(id.substring(_maxedPrefix.length)) : null;

  /// Every milestone [p] has reached, in a fixed order.
  static List<String> reached(Progress p) {
    final List<String> ids = <String>[];
    for (final Era era in Era.values) {
      final Iterable<Track> tracks = TrackCatalog.journey.where((Track t) => t.era == era);
      if (tracks.isNotEmpty && tracks.every((Track t) => p.isCleared(t.id))) {
        ids.add(eraId(era));
      }
    }
    for (final UpgradeKind kind in UpgradeKind.values) {
      if (p.upgrades.levelOf(kind) >= UpgradeLevels.maxLevel) ids.add(maxedId(kind));
    }
    if (p.giftsSpent > 0) ids.add(firstGiftSpent);
    return ids;
  }

  /// Reached milestones not yet celebrated.
  static List<String> due(Progress p) =>
      reached(p).where((String id) => !p.milestonesSeen.contains(id)).toList();

  /// A stable number for choosing a milestone's verse.
  static int seedOf(String id) =>
      id.codeUnits.fold<int>(7, (int sum, int unit) => (sum * 31 + unit) & 0x7fffffff);
}
