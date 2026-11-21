/// Sound effects the race and menus ask for. Each has a distinct sound.
enum SoundEffect {
  tap,
  countdownTick,
  go,
  boost,
  collision,
  lap,
  finishWin,
  finishPodium,
  finishOther,
  star,
  gift,
  upgrade,
}

abstract interface class AudioPort {
  Future<void> play(SoundEffect effect);

  Future<void> startMusic();

  Future<void> stopMusic();

  /// Volumes are 0 to 1.
  Future<void> setVolumes({required double effects, required double music});

  /// Holds all sound while the app is in the background.
  Future<void> pause();

  Future<void> resume();
}

enum HapticKind { light, medium, heavy, selection }

abstract interface class HapticsPort {
  Future<void> play(HapticKind kind);
}

/// The phone's roll angle for tilt steering.
abstract interface class TiltPort {
  /// True when the device has a usable sensor.
  Future<bool> isAvailable();

  /// Roll in radians, positive when the right edge is down. Emits nothing
  /// when no sensor is available.
  Stream<double> get roll;
}

abstract interface class SharePort {
  /// Opens the system share sheet. True if it opened.
  Future<bool> shareText(String text);
}

abstract interface class UrlPort {
  /// Opens [uri] outside the app (support page, privacy policy, mail).
  Future<bool> open(Uri uri);
}

abstract interface class NotificationPort {
  /// Asks for notification permission (at the time of use, never at launch).
  Future<bool> requestPermission();

  Future<bool> isPermitted();

  /// Schedules the daily reminder at a local time, replacing any earlier one.
  Future<void> scheduleDaily({
    required int hour,
    required int minute,
    required String title,
    required String body,
  });

  Future<void> cancelDaily();
}

abstract interface class LogPort {
  /// Adds a line to the rolling local log. Never throws.
  void log(String message);

  /// The whole log, oldest first.
  Future<String> readAll();

  Future<void> clear();
}

abstract interface class ReviewPort {
  /// Asks the store to show its rating prompt. The store decides whether it
  /// appears.
  Future<void> requestReview();
}
