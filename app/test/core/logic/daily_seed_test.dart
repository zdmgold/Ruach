import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/logic/catalog_ids.dart';
import 'package:ruach/core/logic/daily_seed.dart';

void main() {
  group('CivilDate', () {
    test('day numbers match known dates', () {
      expect(const CivilDate(1970, 1, 1).dayNumber, 0);
      expect(const CivilDate(2000, 3, 1).dayNumber, 11017);
      expect(CivilDate.fromDayNumber(11017), const CivilDate(2000, 3, 1));
      expect(const CivilDate(1969, 12, 31).dayNumber, -1);
    });

    test('every day in a few years round-trips', () {
      for (int n = -800; n < 20000; n += 37) {
        expect(CivilDate.fromDayNumber(n).dayNumber, n);
      }
    });

    test('weekday and ISO week', () {
      expect(const CivilDate(1970, 1, 1).weekday, 4);
      expect(const CivilDate(2026, 11, 20).weekday, 5);
      expect(const CivilDate(2026, 11, 16).weekId, '2026-W47');
      expect(const CivilDate(2026, 11, 22).weekId, '2026-W47');
      expect(const CivilDate(2026, 11, 23).weekId, '2026-W48');
      expect(const CivilDate(2021, 1, 3).weekId, '2020-W53');
      expect(const CivilDate(2024, 12, 30).weekId, '2025-W01');
      expect(const CivilDate(2026, 11, 20).weekStart, const CivilDate(2026, 11, 16));
    });

    test('adding days crosses months and leap days', () {
      expect(const CivilDate(2028, 2, 28).addDays(1), const CivilDate(2028, 2, 29));
      expect(const CivilDate(2027, 2, 28).addDays(1), const CivilDate(2027, 3, 1));
      expect(const CivilDate(2026, 12, 31).addDays(1), const CivilDate(2027, 1, 1));
      expect(const CivilDate(2026, 11, 20).daysUntil(const CivilDate(2026, 11, 25)), 5);
    });

    test('keys parse and bad text is refused', () {
      expect(const CivilDate(2026, 3, 9).key, '2026-03-09');
      expect(CivilDate.tryParse('2026-03-09'), const CivilDate(2026, 3, 9));
      expect(CivilDate.tryParse('2026-02-30'), isNull);
      expect(CivilDate.tryParse('2026-13-01'), isNull);
      expect(CivilDate.tryParse('nope'), isNull);
    });
  });

  group('Daily Run', () {
    const CivilDate day = CivilDate(2026, 11, 20);

    test('the same date gives the same challenge', () {
      final DailyChallenge a = DailySeed.forDate(day);
      final DailyChallenge b = DailySeed.forDate(day);
      expect(a.trackId, b.trackId);
      expect(a.vehicleId, b.vehicleId);
      expect(a.seed, b.seed);
      expect(a.wind, b.wind);
      expect(a.laps, b.laps);
      expect(a.verseSeed, b.verseSeed);
    });

    test('different days give a varied mix', () {
      final Set<String> tracks = <String>{};
      final Set<int> seeds = <int>{};
      for (int i = 0; i < 90; i++) {
        final DailyChallenge c = DailySeed.forDate(day.addDays(i));
        tracks.add(c.trackId);
        seeds.add(c.seed);
        expect(TrackIds.all.contains(c.trackId), isTrue);
        expect(VehicleIds.all.contains(c.vehicleId), isTrue);
        expect(c.laps == 2 || c.laps == 3, isTrue);
        expect(c.wind.length, lessThanOrEqualTo(1.2 + 1e-9));
      }
      expect(tracks.length, greaterThan(12));
      expect(seeds.length, greaterThan(85));
    });

    test('the vehicle suits the track', () {
      for (int i = 0; i < 200; i++) {
        final DailyChallenge c = DailySeed.forDate(day.addDays(i));
        final int n = TrackIds.numberOf(c.trackId);
        if (TrackIds.isNowVariant(c.trackId) || n >= 13) {
          expect(<String>[VehicleIds.hatch, VehicleIds.roadster, VehicleIds.utility4x4].contains(c.vehicleId), isTrue);
        } else if (n >= 9) {
          expect(c.vehicleId, VehicleIds.roadCart);
        } else {
          expect(<String>[VehicleIds.lightChariot, VehicleIds.heavyChariot].contains(c.vehicleId), isTrue);
        }
      }
    });
  });

  group('Weekly Circuit', () {
    test('seven different tracks, Monday to Sunday', () {
      final List<DailyChallenge> week = DailySeed.weeklyCircuit(const CivilDate(2026, 11, 20));
      expect(week.length, 7);
      expect(week.first.date, const CivilDate(2026, 11, 16));
      expect(week.last.date, const CivilDate(2026, 11, 22));
      expect(week.map((DailyChallenge c) => c.trackId).toSet().length, 7);
    });

    test('every day of a week gives the same circuit', () {
      final List<String> a = DailySeed.weeklyCircuit(const CivilDate(2026, 11, 16)).map((DailyChallenge c) => c.trackId).toList();
      final List<String> b = DailySeed.weeklyCircuit(const CivilDate(2026, 11, 22)).map((DailyChallenge c) => c.trackId).toList();
      expect(a, b);
    });

    test('the next week is different', () {
      final List<String> a = DailySeed.weeklyCircuit(const CivilDate(2026, 11, 16)).map((DailyChallenge c) => c.trackId).toList();
      final List<String> b = DailySeed.weeklyCircuit(const CivilDate(2026, 11, 23)).map((DailyChallenge c) => c.trackId).toList();
      expect(a, isNot(b));
    });
  });

  group('streak', () {
    const CivilDate today = CivilDate(2026, 11, 20);

    test('the first run starts a streak of one', () {
      final StreakUpdate u = DailyStreak.onCompleted(today: today, last: null, current: 0, best: 0);
      expect(u.current, 1);
      expect(u.best, 1);
      expect(u.counted, isTrue);
      expect(u.welcomeBack, isFalse);
    });

    test('the next day extends it', () {
      final StreakUpdate u = DailyStreak.onCompleted(today: today, last: const CivilDate(2026, 11, 19), current: 4, best: 4);
      expect(u.current, 5);
      expect(u.best, 5);
      expect(u.welcomeBack, isFalse);
    });

    test('the same day is not counted twice', () {
      final StreakUpdate u = DailyStreak.onCompleted(today: today, last: today, current: 4, best: 6);
      expect(u.counted, isFalse);
      expect(u.current, 4);
    });

    test('a missed day starts again gently and keeps the best', () {
      final StreakUpdate u = DailyStreak.onCompleted(today: today, last: const CivilDate(2026, 11, 17), current: 9, best: 9);
      expect(u.current, 1);
      expect(u.best, 9);
      expect(u.welcomeBack, isTrue);
    });

    test('days missed and the welcome-back prompt', () {
      expect(DailyStreak.daysMissed(null, today), 0);
      expect(DailyStreak.daysMissed(today, today), 0);
      expect(DailyStreak.daysMissed(const CivilDate(2026, 11, 19), today), 0);
      expect(DailyStreak.daysMissed(const CivilDate(2026, 11, 17), today), 2);
      expect(DailyStreak.welcomeBackDue(const CivilDate(2026, 11, 18), today), isTrue);
      expect(DailyStreak.welcomeBackDue(const CivilDate(2026, 11, 19), today), isFalse);
    });
  });
}
