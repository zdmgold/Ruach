// Display helpers for race numbers.
//
// Race numbers use Western digits and fixed separators in every language, so
// a lap time reads the same everywhere and tabular figures line up. Only
// words are translated.

/// Lap time as minutes, seconds and hundredths: `01:23.45`.
///
/// Hundredths are truncated, not rounded, so a displayed time never reads
/// better than the real one. A negative duration is shown as zero. Minutes
/// grow past two digits when needed.
String formatLapTime(Duration time) {
  final int totalHundredths = (time.isNegative ? 0 : time.inMilliseconds) ~/ 10;
  final int minutes = totalHundredths ~/ 6000;
  final int seconds = (totalHundredths ~/ 100) % 60;
  final int hundredths = totalHundredths % 100;
  return '${_two(minutes)}:${_two(seconds)}.${_two(hundredths)}';
}

/// Lap time, or dashes when there is no time yet: `--:--.--`.
String formatLapTimeOrDash(Duration? time) =>
    time == null ? '--:--.--' : formatLapTime(time);

/// Finishing position out of the field: `3/6`.
String formatPosition(int position, int fieldSize) => '$position/$fieldSize';

/// Current lap out of the total: `2/3`.
String formatLap(int lap, int totalLaps) => '$lap/$totalLaps';

/// A whole-number count such as Gifts or stars, with no grouping: `42`.
String formatCount(int value) => value.toString();

/// A clock time as `07:05`, the same in every language.
String formatClock(int hour, int minute) => '${_two(hour)}:${_two(minute)}';

String _two(int value) => value.toString().padLeft(2, '0');
