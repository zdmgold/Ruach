import 'package:flutter/foundation.dart';
import 'package:ruach/core/logic/daily_seed.dart';
import 'package:ruach/core/models/progress.dart';
import 'package:ruach/core/models/settings.dart';
import 'package:ruach/core/ports/device_ports.dart';
import 'package:ruach/providers/progress_provider.dart';
import 'package:ruach/providers/settings_provider.dart';

/// Today's Daily Run: the challenge, the attempts, the streak and the opt-in
/// reminder. The date is the device's local date, read through [clock].
final class DailyProvider extends ChangeNotifier {
  DailyProvider(
    this._progress,
    this._settings,
    this._notifications, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _progress.addListener(notifyListeners);
  }

  final ProgressProvider _progress;
  final SettingsProvider _settings;
  final NotificationPort _notifications;
  final DateTime Function() _clock;

  CivilDate get today {
    final DateTime n = _clock();
    return CivilDate(n.year, n.month, n.day);
  }

  DailyChallenge get challenge => DailySeed.forDate(today);

  DailyRunRecord get record =>
      _progress.value.dailyRuns[today.key] ?? const DailyRunRecord();

  int get attemptsToday => record.attempts;
  bool get completedToday => record.completed;

  /// The first attempt of the day is free; each later one is the player's
  /// choice (a rewarded ad, or free once Remove Ads is owned).
  bool get nextAttemptIsExtra => record.attempts >= 1;

  int get streak => _effectiveStreak();
  int get bestStreak => _progress.value.bestStreak;

  CivilDate? get lastCompleted =>
      CivilDate.tryParse(_progress.value.lastDailyDate ?? '');

  /// True when a welcome-back verse should show: days were missed.
  bool get welcomeBackDue => DailyStreak.welcomeBackDue(lastCompleted, today);

  // A streak that has already lapsed reads as 0 until the next run.
  int _effectiveStreak() {
    final CivilDate? last = lastCompleted;
    if (last == null) return 0;
    return last.daysUntil(today) > 1 ? 0 : _progress.value.currentStreak;
  }

  /// Counts the start of an attempt. Save before the race so quitting
  /// mid-race still uses the attempt.
  Future<void> startAttempt() {
    final String key = today.key;
    return _progress.change((Progress p) {
      final DailyRunRecord r = p.dailyRuns[key] ?? const DailyRunRecord();
      return p.copyWith(
        dailyRuns: <String, DailyRunRecord>{
          ...p.dailyRuns,
          key: r.copyWith(attempts: r.attempts + 1),
        },
      );
    });
  }

  /// Records a finished Daily Run at [position] and updates the streak. The
  /// streak counts once a day, on the first finish.
  Future<StreakUpdate> complete(int position) async {
    final CivilDate day = today;
    late StreakUpdate update;
    await _progress.change((Progress p) {
      final DailyRunRecord r = p.dailyRuns[day.key] ?? const DailyRunRecord();
      final int best = r.bestPosition == 0 || position < r.bestPosition ? position : r.bestPosition;
      update = DailyStreak.onCompleted(
        today: day,
        last: CivilDate.tryParse(p.lastDailyDate ?? ''),
        current: p.currentStreak,
        best: p.bestStreak,
      );
      return p.copyWith(
        dailyRuns: <String, DailyRunRecord>{
          ...p.dailyRuns,
          day.key: r.copyWith(completed: true, bestPosition: best),
        },
        currentStreak: update.current,
        bestStreak: update.best,
        lastDailyDate: day.key,
      );
    });
    return update;
  }

  /// Turns the daily reminder on or off. Turning it on asks for permission
  /// first; if refused, nothing changes. Returns whether it is now on.
  Future<bool> setReminder({
    required bool enabled,
    required String title,
    required String body,
  }) async {
    if (!enabled) {
      await _notifications.cancelDaily();
      await _settings.update((Settings s) => s.copyWith(remindersEnabled: false));
      return false;
    }
    if (!await _notifications.requestPermission()) return false;
    await _notifications.scheduleDaily(
      hour: _settings.value.reminderHour,
      minute: _settings.value.reminderMinute,
      title: title,
      body: body,
    );
    await _settings.update((Settings s) => s.copyWith(remindersEnabled: true));
    return true;
  }

  @override
  void dispose() {
    _progress.removeListener(notifyListeners);
    super.dispose();
  }
}
