import 'package:ruach/core/models/race_config.dart';
import 'package:ruach/core/models/vec2.dart';
import 'package:ruach/providers/race_provider.dart';

/// Route names. The full router (which screen each name builds, and the
/// transitions) is assembled in the app shell (batch p6a); screens only push
/// these names.
abstract final class Routes {
  static const String home = '/';
  static const String garage = '/garage';
  static const String settings = '/settings';
  static const String verseLibrary = '/verses';

  /// The entry screen of a mode (Journey map, track picker, and so on).
  /// Argument: [ModeArgs].
  static const String mode = '/mode';

  /// A track's introduction before a race. Argument: [TrackIntroArgs].
  static const String trackIntro = '/track-intro';

  /// The race itself. Argument: [RaceArgs].
  static const String race = '/race';

  /// The result of the race that just finished.
  static const String result = '/result';
}

final class ModeArgs {
  const ModeArgs(this.mode);

  final RaceMode mode;
}

final class TrackIntroArgs {
  const TrackIntroArgs({
    required this.mode,
    required this.trackId,
    this.weeklyIndex,
  });

  final RaceMode mode;
  final String trackId;

  /// For the Weekly Circuit: which day's race, 0 to 6.
  final int? weeklyIndex;
}

final class RaceArgs {
  const RaceArgs({
    required this.config,
    this.wind = Vec2.zero,
    this.startingBoost = 0,
    this.weekly,
  });

  final RaceConfig config;

  /// Wind for the Daily Run; zero otherwise.
  final Vec2 wind;

  /// Set for a Weekly Circuit race so its time is saved against its day.
  final WeeklySlot? weekly;

  /// 0 to 1, from the "start with extra boost" reward.
  final double startingBoost;
}
