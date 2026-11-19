import 'package:ruach/core/models/json_read.dart';
import 'package:ruach/core/models/upgrade.dart';

/// One day of Daily Run. Keyed by date text (`2026-11-19`) in [Progress].
final class DailyRunRecord {
  const DailyRunRecord({
    this.attempts = 0,
    this.completed = false,
    this.bestPosition = 0,
  });

  factory DailyRunRecord.fromJson(Object? json) {
    final Map<String, Object?> m = asJsonMap(json);
    return DailyRunRecord(
      attempts: readInt(m['attempts'], 0).clamp(0, 1000).toInt(),
      completed: readBool(m['completed'], false),
      bestPosition: readInt(m['bestPosition'], 0).clamp(0, 6).toInt(),
    );
  }

  /// Races started that day, including extra attempts from a rewarded ad.
  final int attempts;

  /// True once the player has finished the day's race.
  final bool completed;

  /// The best finishing position that day, 1 to 6, or 0 if none.
  final int bestPosition;

  DailyRunRecord copyWith({int? attempts, bool? completed, int? bestPosition}) =>
      DailyRunRecord(
        attempts: attempts ?? this.attempts,
        completed: completed ?? this.completed,
        bestPosition: bestPosition ?? this.bestPosition,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'attempts': attempts,
        'completed': completed,
        'bestPosition': bestPosition,
      };
}

/// Everything the game remembers about the player, in one value. Immutable:
/// every change returns a new [Progress]. It is saved as one JSON file that
/// carries [schemaVersion]; reading and migrating that file is
/// `progress_codec.dart` (batch p2d).
///
/// Keys are stable ids: track ids, vehicle ids, verse ids, `yyyy-MM-dd` dates.
final class Progress {
  Progress({
    this.schemaVersion = currentSchemaVersion,
    Map<String, int> stars = const <String, int>{},
    this.giftsEarned = 0,
    this.giftsSpent = 0,
    this.upgrades = UpgradeLevels.none,
    Set<String> ownedVehicleIds = const <String>{},
    Set<String> earnedLiveryIds = const <String>{},
    Map<String, int> bestLapMillis = const <String, int>{},
    Map<String, String> ghosts = const <String, String>{},
    Map<String, DailyRunRecord> dailyRuns = const <String, DailyRunRecord>{},
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastDailyDate,
    this.weeklyCircuitWeek,
    Map<String, int> weeklyCircuitMillis = const <String, int>{},
    this.escapeRunBestMetres = 0,
    Set<String> seenVerseIds = const <String>{},
    Set<String> bookmarks = const <String>{},
    Map<String, int> highlights = const <String, int>{},
  })  : stars = Map<String, int>.unmodifiable(stars),
        ownedVehicleIds = Set<String>.unmodifiable(ownedVehicleIds),
        earnedLiveryIds = Set<String>.unmodifiable(earnedLiveryIds),
        bestLapMillis = Map<String, int>.unmodifiable(bestLapMillis),
        ghosts = Map<String, String>.unmodifiable(ghosts),
        dailyRuns = Map<String, DailyRunRecord>.unmodifiable(dailyRuns),
        weeklyCircuitMillis = Map<String, int>.unmodifiable(weeklyCircuitMillis),
        seenVerseIds = Set<String>.unmodifiable(seenVerseIds),
        bookmarks = Set<String>.unmodifiable(bookmarks),
        highlights = Map<String, int>.unmodifiable(highlights);

  /// A new player's progress.
  factory Progress.fresh() => Progress();

  /// Reads the current schema from decoded JSON. Missing or invalid values
  /// become defaults; it never throws. Older versions are brought up to date by
  /// the migrations before this is called.
  factory Progress.fromJson(Object? json) {
    final Map<String, Object?> m = asJsonMap(json);
    final Map<String, int> upgradeLevels = readIntMap(m['upgrades']);
    final Map<String, DailyRunRecord> daily = <String, DailyRunRecord>{};
    asJsonMap(m['dailyRuns']).forEach((String date, Object? value) {
      daily[date] = DailyRunRecord.fromJson(value);
    });
    final Map<String, int> stars = <String, int>{};
    readIntMap(m['stars']).forEach((String id, int value) {
      stars[id] = value.clamp(0, 3).toInt();
    });
    return Progress(
      schemaVersion: readInt(m['schemaVersion'], currentSchemaVersion),
      stars: stars,
      giftsEarned: _nonNegative(readInt(m['giftsEarned'], 0)),
      giftsSpent: _nonNegative(readInt(m['giftsSpent'], 0)),
      upgrades: UpgradeLevels.fromMap(<UpgradeKind, int>{
        for (final MapEntry<String, int> e in upgradeLevels.entries)
          if (UpgradeKind.fromId(e.key) != null) UpgradeKind.fromId(e.key)!: e.value,
      }),
      ownedVehicleIds: readStringSet(m['ownedVehicleIds']),
      earnedLiveryIds: readStringSet(m['earnedLiveryIds']),
      bestLapMillis: readIntMap(m['bestLapMillis']),
      ghosts: readStringMap(m['ghosts']),
      dailyRuns: daily,
      currentStreak: _nonNegative(readInt(m['currentStreak'], 0)),
      bestStreak: _nonNegative(readInt(m['bestStreak'], 0)),
      lastDailyDate: readStringOrNull(m['lastDailyDate']),
      weeklyCircuitWeek: readStringOrNull(m['weeklyCircuitWeek']),
      weeklyCircuitMillis: readIntMap(m['weeklyCircuitMillis']),
      escapeRunBestMetres: _nonNegative(readInt(m['escapeRunBestMetres'], 0)),
      seenVerseIds: readStringSet(m['seenVerseIds']),
      bookmarks: readStringSet(m['bookmarks']),
      highlights: readIntMap(m['highlights']),
    );
  }

  /// The schema this version of the app writes.
  static const int currentSchemaVersion = 1;

  final int schemaVersion;

  /// Best stars per track id, 0 to 3. A track with at least one star is
  /// cleared.
  final Map<String, int> stars;

  /// Gifts earned in total (one per star) and spent in total. The balance is
  /// [gifts]; keeping both lets the totals be checked against each other.
  final int giftsEarned;
  final int giftsSpent;

  final UpgradeLevels upgrades;

  final Set<String> ownedVehicleIds;
  final Set<String> earnedLiveryIds;

  /// Best lap per track id, in milliseconds.
  final Map<String, int> bestLapMillis;

  /// Time Trial ghosts per track id: a compressed input log as base64 text,
  /// roughly 20 KB at most each.
  final Map<String, String> ghosts;

  /// Daily Run history by `yyyy-MM-dd` date.
  final Map<String, DailyRunRecord> dailyRuns;

  final int currentStreak;
  final int bestStreak;

  /// The last date a Daily Run was completed, `yyyy-MM-dd`.
  final String? lastDailyDate;

  /// The id of the week the Weekly Circuit times belong to, for example
  /// `2026-W47`, and the combined-time entries per race number in it.
  final String? weeklyCircuitWeek;
  final Map<String, int> weeklyCircuitMillis;

  /// Furthest Escape Run distance, in metres.
  final int escapeRunBestMetres;

  /// Verse ids (`language:ref`) the player has seen, for the Verse library.
  final Set<String> seenVerseIds;

  /// Reader bookmarks (verse keys) and highlights (verse key to colour index).
  /// Used from batch p8b.
  final Set<String> bookmarks;
  final Map<String, int> highlights;

  /// Gifts available to spend.
  int get gifts => giftsEarned - giftsSpent;

  int starsOn(String trackId) => stars[trackId] ?? 0;

  bool isCleared(String trackId) => starsOn(trackId) > 0;

  int get totalStars =>
      stars.values.fold<int>(0, (int sum, int value) => sum + value);

  Progress copyWith({
    Map<String, int>? stars,
    int? giftsEarned,
    int? giftsSpent,
    UpgradeLevels? upgrades,
    Set<String>? ownedVehicleIds,
    Set<String>? earnedLiveryIds,
    Map<String, int>? bestLapMillis,
    Map<String, String>? ghosts,
    Map<String, DailyRunRecord>? dailyRuns,
    int? currentStreak,
    int? bestStreak,
    String? lastDailyDate,
    String? weeklyCircuitWeek,
    Map<String, int>? weeklyCircuitMillis,
    int? escapeRunBestMetres,
    Set<String>? seenVerseIds,
    Set<String>? bookmarks,
    Map<String, int>? highlights,
  }) =>
      Progress(
        schemaVersion: schemaVersion,
        stars: stars ?? this.stars,
        giftsEarned: giftsEarned ?? this.giftsEarned,
        giftsSpent: giftsSpent ?? this.giftsSpent,
        upgrades: upgrades ?? this.upgrades,
        ownedVehicleIds: ownedVehicleIds ?? this.ownedVehicleIds,
        earnedLiveryIds: earnedLiveryIds ?? this.earnedLiveryIds,
        bestLapMillis: bestLapMillis ?? this.bestLapMillis,
        ghosts: ghosts ?? this.ghosts,
        dailyRuns: dailyRuns ?? this.dailyRuns,
        currentStreak: currentStreak ?? this.currentStreak,
        bestStreak: bestStreak ?? this.bestStreak,
        lastDailyDate: lastDailyDate ?? this.lastDailyDate,
        weeklyCircuitWeek: weeklyCircuitWeek ?? this.weeklyCircuitWeek,
        weeklyCircuitMillis: weeklyCircuitMillis ?? this.weeklyCircuitMillis,
        escapeRunBestMetres: escapeRunBestMetres ?? this.escapeRunBestMetres,
        seenVerseIds: seenVerseIds ?? this.seenVerseIds,
        bookmarks: bookmarks ?? this.bookmarks,
        highlights: highlights ?? this.highlights,
      );

  /// The saved form. Keys and set members are sorted, so the same progress
  /// always encodes to the same text.
  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': schemaVersion,
        'stars': sortedMap<int>(stars),
        'giftsEarned': giftsEarned,
        'giftsSpent': giftsSpent,
        'upgrades': <String, int>{
          for (final UpgradeKind kind in UpgradeKind.values)
            kind.id: upgrades.levelOf(kind),
        },
        'ownedVehicleIds': ownedVehicleIds.toList()..sort(),
        'earnedLiveryIds': earnedLiveryIds.toList()..sort(),
        'bestLapMillis': sortedMap<int>(bestLapMillis),
        'ghosts': sortedMap<String>(ghosts),
        'dailyRuns': sortedMap<Object?>(<String, Object?>{
          for (final MapEntry<String, DailyRunRecord> e in dailyRuns.entries)
            e.key: e.value.toJson(),
        }),
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
        'lastDailyDate': lastDailyDate,
        'weeklyCircuitWeek': weeklyCircuitWeek,
        'weeklyCircuitMillis': sortedMap<int>(weeklyCircuitMillis),
        'escapeRunBestMetres': escapeRunBestMetres,
        'seenVerseIds': seenVerseIds.toList()..sort(),
        'bookmarks': bookmarks.toList()..sort(),
        'highlights': sortedMap<int>(highlights),
      };
}

int _nonNegative(int value) => value < 0 ? 0 : value;
