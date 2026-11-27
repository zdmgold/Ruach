/// The Ruach meter: three segments that fill from clean driving, from
/// slipstreaming a rival and (for drift-capable vehicles) from drifting. The
/// player spends one segment at a time for a boost. It is a skill resource:
/// never random, never sold, never given by an ad that skips play
/// (blueprint section 2).
final class BoostMeter {
  BoostMeter({double initial = 0}) : _fill = initial.clamp(0.0, segments.toDouble()).toDouble();

  static const int segments = 3;

  /// Segments per second of clean driving: three segments take 20 seconds.
  static const double cleanRate = 0.15;

  /// Segments per second while slipstreaming, after [slipstreamDelay].
  static const double slipstreamRate = 0.5;

  /// Seconds behind a rival before the slipstream starts to charge.
  static const double slipstreamDelay = 0.5;

  /// Segments per second while drifting.
  static const double driftRate = 0.2;

  double _fill;
  double _slipstreamTime = 0;

  /// 0 to 3, in segments. A whole number of segments can be spent.
  double get fill => _fill;

  /// Full segments ready to spend.
  int get fullSegments => _fill.floor();

  bool get canSpend => _fill >= 1;

  /// Adds clean-driving charge for [dt] seconds. [multiplier] is the Wisdom
  /// upgrade.
  void addCleanDriving(double dt, {double multiplier = 1}) =>
      _add(cleanRate * dt * multiplier);

  void addDrift(double dt, {double multiplier = 1}) =>
      _add(driftRate * dt * multiplier);

  /// Reports whether the car is in a rival's slipstream this step. Charging
  /// starts once it has lasted [slipstreamDelay] seconds; leaving resets it.
  void updateSlipstream(bool inSlipstream, double dt, {double multiplier = 1}) {
    if (!inSlipstream) {
      _slipstreamTime = 0;
      return;
    }
    _slipstreamTime += dt;
    if (_slipstreamTime >= slipstreamDelay) {
      _add(slipstreamRate * dt * multiplier);
    }
  }

  /// Spends one segment. Returns false, changing nothing, if none is ready.
  bool spend() {
    if (!canSpend) return false;
    _fill -= 1;
    return true;
  }

  /// Adds a starting charge, for the rewarded "start with extra boost".
  void grant(double segmentsToAdd) => _add(segmentsToAdd);

  void _add(double amount) {
    final double next = _fill + amount;
    _fill = next > segments ? segments.toDouble() : next;
  }
}
