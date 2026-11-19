import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/models/progress.dart';
import 'package:ruach/core/models/upgrade.dart';

String _encode(Progress p) => jsonEncode(p.toJson());

void main() {
  test('a fresh player has nothing', () {
    final Progress p = Progress.fresh();
    expect(p.schemaVersion, Progress.currentSchemaVersion);
    expect(p.gifts, 0);
    expect(p.totalStars, 0);
    expect(p.isCleared('nile_banks'), isFalse);
    expect(p.upgrades, UpgradeLevels.none);
    expect(p.lastDailyDate, isNull);
  });

  test('a full progress round-trips through JSON text', () {
    final Progress p = Progress(
      stars: <String, int>{'nile_banks': 3, 'red_sea_crossing': 1},
      giftsEarned: 9,
      giftsSpent: 4,
      upgrades: UpgradeLevels.none.withLevel(UpgradeKind.might, 2),
      ownedVehicleIds: <String>{'light_chariot', 'heavy_chariot'},
      earnedLiveryIds: <String>{'gold'},
      bestLapMillis: <String, int>{'nile_banks': 61234},
      ghosts: <String, String>{'nile_banks': 'QUJD'},
      dailyRuns: <String, DailyRunRecord>{
        '2026-11-19': const DailyRunRecord(attempts: 2, completed: true, bestPosition: 1),
      },
      currentStreak: 3,
      bestStreak: 5,
      lastDailyDate: '2026-11-19',
      weeklyCircuitWeek: '2026-W47',
      weeklyCircuitMillis: <String, int>{'1': 180000},
      escapeRunBestMetres: 1200,
      seenVerseIds: <String>{'en:Ps.23.1'},
      bookmarks: <String>{'John.3.16'},
      highlights: <String, int>{'John.3.16': 2},
    );
    final Progress back = Progress.fromJson(jsonDecode(_encode(p)));
    expect(_encode(back), _encode(p));
    expect(back.gifts, 5);
    expect(back.totalStars, 4);
    expect(back.isCleared('red_sea_crossing'), isTrue);
    expect(back.upgrades.levelOf(UpgradeKind.might), 2);
    expect(back.dailyRuns['2026-11-19']!.completed, isTrue);
  });

  test('encoding is stable whatever order things were added', () {
    final Progress a = Progress(stars: <String, int>{'b': 1, 'a': 2});
    final Progress b = Progress(stars: <String, int>{'a': 2, 'b': 1});
    expect(_encode(a), _encode(b));
  });

  test('damaged input falls back to defaults and never throws', () {
    expect(_encode(Progress.fromJson(null)), _encode(Progress.fresh()));
    expect(_encode(Progress.fromJson('nonsense')), _encode(Progress.fresh()));
    final Progress p = Progress.fromJson(<String, Object?>{
      'stars': <String, Object?>{'a': 99, 'b': 'x', 'c': -5},
      'giftsEarned': -10,
      'upgrades': <String, Object?>{'might': 40, 'unknown_one': 3},
      'ownedVehicleIds': <Object?>['ok', 5, null],
      'dailyRuns': <String, Object?>{'2026-11-19': 'bad'},
    });
    expect(p.starsOn('a'), 3);
    expect(p.starsOn('b'), 0);
    expect(p.starsOn('c'), 0);
    expect(p.giftsEarned, 0);
    expect(p.upgrades.levelOf(UpgradeKind.might), UpgradeLevels.maxLevel);
    expect(p.ownedVehicleIds, <String>{'ok'});
    expect(p.dailyRuns['2026-11-19']!.attempts, 0);
  });

  test('collections cannot be changed from outside', () {
    final Progress p = Progress(stars: <String, int>{'a': 1});
    expect(() => p.stars['b'] = 2, throwsUnsupportedError);
    expect(() => p.seenVerseIds.add('x'), throwsUnsupportedError);
  });

  test('copyWith changes one thing and keeps the schema version', () {
    final Progress p = Progress(giftsEarned: 3);
    final Progress q = p.copyWith(giftsSpent: 1);
    expect(q.gifts, 2);
    expect(q.schemaVersion, p.schemaVersion);
    expect(p.gifts, 3);
  });

  test('a newer schema version is kept as read', () {
    final Progress p = Progress.fromJson(<String, Object?>{'schemaVersion': 99});
    expect(p.schemaVersion, 99);
  });
}
