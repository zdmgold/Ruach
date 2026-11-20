/// Counts one car's progress round a lap: checkpoints in order, laps, lap
/// times, and a total distance used to rank cars.
///
/// Progress is only credited for small forward steps along the road. A jump
/// (cutting across the infield, being put back on the track) is not credited,
/// so shortcuts earn nothing: the car must still cover the road to finish the
/// lap.
final class LapTracker {
  LapTracker({
    required this.trackLength,
    required List<double> checkpointFractions,
    required this.laps,
    double startBehindLine = 0,
  })  : checkpointFractions = List<double>.unmodifiable(checkpointFractions),
        _totalDistance = -startBehindLine,
        _lastDistance = (trackLength - startBehindLine) % trackLength;

  /// The longest step along the road that is credited, in metres. At 60 Hz a
  /// car at 80 m/s moves 1.3 m per step, so this leaves a wide margin.
  static const double maxCreditedStep = 30;

  /// Steps in a row with a jump before the tracker re-anchors to the car's
  /// new position (without crediting the jump).
  static const int reanchorAfter = 120;

  final double trackLength;
  final List<double> checkpointFractions;
  final int laps;

  double _totalDistance;
  double _lastDistance;
  int _lap = 0;
  int _nextCheckpoint = 0;
  int _rejected = 0;
  double _lapStartSeconds = 0;
  bool _finished = false;
  double? _finishSeconds;
  final List<double> _lapTimes = <double>[];

  /// Laps completed.
  int get lap => _lap;

  /// Index of the next checkpoint to pass in the current lap.
  int get nextCheckpoint => _nextCheckpoint;

  /// Credited distance since the start line (negative on the grid).
  double get totalDistance => _totalDistance;

  bool get finished => _finished;

  /// Seconds at which the final lap was completed, or null.
  double? get finishSeconds => _finishSeconds;

  /// Completed lap times in seconds.
  List<double> get lapTimes => List<double>.unmodifiable(_lapTimes);

  /// Share of the whole race covered, 0 to 1.
  double get raceProgress {
    final double p = _totalDistance / (trackLength * laps);
    return p < 0 ? 0 : (p > 1 ? 1 : p);
  }

  /// Marks the car as finished now, for a mode rule that ends its race
  /// (the last car standing in Elimination).
  void forceFinish(double elapsedSeconds) {
    if (_finished) return;
    _finished = true;
    _finishSeconds = elapsedSeconds;
  }

  /// Updates with the car's current [distance] along the centreline (0 to the
  /// lap length) and the race clock in seconds.
  void update(double distance, double elapsedSeconds) {
    if (_finished) return;
    double delta = distance - _lastDistance;
    if (delta > trackLength / 2) delta -= trackLength;
    if (delta < -trackLength / 2) delta += trackLength;

    if (delta.abs() > maxCreditedStep) {
      _rejected++;
      if (_rejected >= reanchorAfter) {
        _lastDistance = distance;
        _rejected = 0;
      }
      return;
    }
    _rejected = 0;
    _lastDistance = distance;
    _totalDistance += delta;

    while (_nextCheckpoint < checkpointFractions.length &&
        _totalDistance >= _lap * trackLength + checkpointFractions[_nextCheckpoint] * trackLength) {
      _nextCheckpoint++;
    }
    if (_nextCheckpoint == checkpointFractions.length &&
        _totalDistance >= (_lap + 1) * trackLength) {
      _lap++;
      _nextCheckpoint = 0;
      _lapTimes.add(elapsedSeconds - _lapStartSeconds);
      _lapStartSeconds = elapsedSeconds;
      if (_lap >= laps) {
        _finished = true;
        _finishSeconds = elapsedSeconds;
      }
    }
  }
}
