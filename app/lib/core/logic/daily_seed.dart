import 'dart:math' as math;

import 'package:ruach/core/logic/catalog_ids.dart';
import 'package:ruach/core/logic/seeded_rng.dart';
import 'package:ruach/core/models/vec2.dart';

/// A calendar date with no time and no time zone. Core never reads the clock:
/// the caller says what day it is, so the Daily Run is the same for everyone
/// on the same date.
final class CivilDate implements Comparable<CivilDate> {
  const CivilDate(this.year, this.month, this.day);

  /// Reads `yyyy-MM-dd`; returns null for anything else or a date that does
  /// not exist.
  static CivilDate? tryParse(String text) {
    final RegExpMatch? m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text);
    if (m == null) return null;
    final CivilDate d = CivilDate(int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!));
    return CivilDate.fromDayNumber(d.dayNumber) == d ? d : null;
  }

  /// The date [days] days after 1970-01-01 (before it if negative).
  factory CivilDate.fromDayNumber(int days) {
    final int z = days + 719468;
    final int era = (z >= 0 ? z : z - 146096) ~/ 146097;
    final int doe = z - era * 146097;
    final int yoe = (doe - doe ~/ 1460 + doe ~/ 36524 - doe ~/ 146096) ~/ 365;
    final int doy = doe - (365 * yoe + yoe ~/ 4 - yoe ~/ 100);
    final int mp = (5 * doy + 2) ~/ 153;
    final int d = doy - (153 * mp + 2) ~/ 5 + 1;
    final int m = mp < 10 ? mp + 3 : mp - 9;
    final int y = yoe + era * 400 + (m <= 2 ? 1 : 0);
    return CivilDate(y, m, d);
  }

  final int year;
  final int month;
  final int day;

  /// Days since 1970-01-01.
  int get dayNumber {
    final int y = month <= 2 ? year - 1 : year;
    final int era = (y >= 0 ? y : y - 399) ~/ 400;
    final int yoe = y - era * 400;
    final int doy = (153 * (month + (month > 2 ? -3 : 9)) + 2) ~/ 5 + day - 1;
    final int doe = yoe * 365 + yoe ~/ 4 - yoe ~/ 100 + doy;
    return era * 146097 + doe - 719468;
  }

  /// 1 for Monday to 7 for Sunday.
  int get weekday => ((dayNumber + 3) % 7 + 7) % 7 + 1;

  /// `yyyy-MM-dd`.
  String get key =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  CivilDate addDays(int days) => CivilDate.fromDayNumber(dayNumber + days);

  /// Whole days from this date to [other] (negative if [other] is earlier).
  int daysUntil(CivilDate other) => other.dayNumber - dayNumber;

  /// The Monday of this date's week.
  CivilDate get weekStart => addDays(-(weekday - 1));

  /// The ISO week, for example `2026-W47`. Weeks start on Monday.
  String get weekId {
    final int thursday = dayNumber - (weekday - 1) + 3;
    final CivilDate t = CivilDate.fromDayNumber(thursday);
    final int jan1 = CivilDate(t.year, 1, 1).dayNumber;
    final int week = (thursday - jan1) ~/ 7 + 1;
    return '${t.year}-W${week.toString().padLeft(2, '0')}';
  }

  @override
  int compareTo(CivilDate other) => dayNumber.compareTo(other.dayNumber);

  @override
  bool operator ==(Object other) =>
      other is CivilDate && other.year == year && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => key;
}

/// One seeded race: the same for every player on the same date.
final class DailyChallenge {
  const DailyChallenge({
    required this.date,
    required this.trackId,
    required this.vehicleId,
    required this.wind,
    required this.laps,
    required this.seed,
    required this.verseSeed,
  });

  final CivilDate date;
  final String trackId;
  final String vehicleId;

  /// Constant sideways push in m/s squared.
  final Vec2 wind;
  final int laps;

  /// Seeds the rivals and anything else random in the race.
  final int seed;

  /// Seeds the verse of the day.
  final int verseSeed;
}

/// Builds the Daily Run and the Weekly Circuit from dates alone.
abstract final class DailySeed {
  static const String _salt = 'ruach-daily-v1';

  /// The challenge for [date].
  static DailyChallenge forDate(CivilDate date) {
    final SeededRng root = SeededRng(date.dayNumber * 2654435761 + 12345).fork(_salt);
    final String trackId = root.fork('track').pick(TrackIds.all);
    return _build(date, trackId, root);
  }

  /// Seven different tracks for the week containing [anyDay], one per day,
  /// Monday first. Missed days can be run later that week.
  static List<DailyChallenge> weeklyCircuit(CivilDate anyDay) {
    final CivilDate monday = anyDay.weekStart;
    final SeededRng root = SeededRng(monday.dayNumber * 2654435761 + 777).fork('ruach-weekly-v1');
    final List<String> ids = List<String>.of(TrackIds.all);
    // Seeded shuffle, then take seven.
    final SeededRng shuffle = root.fork('shuffle');
    for (int i = ids.length - 1; i > 0; i--) {
      final int j = shuffle.nextInt(i + 1);
      final String tmp = ids[i];
      ids[i] = ids[j];
      ids[j] = tmp;
    }
    return <DailyChallenge>[
      for (int i = 0; i < 7; i++)
        _build(monday.addDays(i), ids[i], root.fork('day$i')),
    ];
  }

  static DailyChallenge _build(CivilDate date, String trackId, SeededRng root) {
    final SeededRng rng = root.fork('setup');
    final double angle = rng.nextRange(0, 2 * math.pi);
    final double strength = rng.nextRange(0, 1.2);
    return DailyChallenge(
      date: date,
      trackId: trackId,
      vehicleId: _vehicleFor(trackId, rng),
      wind: Vec2(math.cos(angle) * strength, math.sin(angle) * strength),
      laps: rng.nextBool() ? 2 : 3,
      seed: rng.fork('race').nextUint32(),
      verseSeed: rng.fork('verse').nextUint32(),
    );
  }

  /// A vehicle that suits the track's era: chariots on tracks 1 to 8, the
  /// cart on 9 to 12, modern vehicles on 13 to 16 and on every Now variant.
  static String _vehicleFor(String trackId, SeededRng rng) {
    final int n = TrackIds.numberOf(trackId);
    if (TrackIds.isNowVariant(trackId) || n >= 13) {
      return rng.pick(<String>[VehicleIds.hatch, VehicleIds.roadster, VehicleIds.utility4x4]);
    }
    if (n >= 9) return VehicleIds.roadCart;
    return rng.pick(<String>[VehicleIds.lightChariot, VehicleIds.heavyChariot]);
  }
}

/// The result of finishing a Daily Run.
final class StreakUpdate {
  const StreakUpdate({
    required this.current,
    required this.best,
    required this.counted,
    required this.welcomeBack,
  });

  final int current;
  final int best;

  /// False when today was already counted.
  final bool counted;

  /// True when the player is back after a missed day or more. The game shows
  /// a gentle welcome with a welcome-back verse, never a shaming reset.
  final bool welcomeBack;
}

abstract final class DailyStreak {
  /// Whole days missed since the last completed Daily Run: 0 when it was today
  /// or yesterday, or when there was none.
  static int daysMissed(CivilDate? last, CivilDate today) {
    if (last == null) return 0;
    final int gap = last.daysUntil(today);
    return gap > 1 ? gap - 1 : 0;
  }

  /// True when a welcome-back verse should be shown today.
  static bool welcomeBackDue(CivilDate? last, CivilDate today) =>
      daysMissed(last, today) > 0;

  /// The streak after completing today's run.
  static StreakUpdate onCompleted({
    required CivilDate today,
    required CivilDate? last,
    required int current,
    required int best,
  }) {
    if (last != null && last.daysUntil(today) == 0) {
      return StreakUpdate(current: current, best: best, counted: false, welcomeBack: false);
    }
    final bool consecutive = last != null && last.daysUntil(today) == 1;
    final int next = consecutive ? current + 1 : 1;
    return StreakUpdate(
      current: next,
      best: next > best ? next : best,
      counted: true,
      welcomeBack: daysMissed(last, today) > 0,
    );
  }
}
