/// A small deterministic random number generator (mulberry32). Nothing in
/// core reads the wall clock or `dart:math`'s `Random`, so the same seed always
/// gives the same sequence on every device (blueprint section 4).
///
/// Use [fork] to give each part of the game (rival AI, wind, Daily Run) its
/// own independent stream. A fork depends only on the seed and the label, not
/// on how many numbers have already been drawn.
final class SeededRng {
  SeededRng(int seed)
      : _seed = seed & _mask,
        _state = seed & _mask;

  static const int _mask = 0xFFFFFFFF;

  final int _seed;
  int _state;

  /// The seed this generator started from.
  int get seed => _seed;

  /// An independent generator derived from this one's seed and [label].
  SeededRng fork(String label) {
    int hash = 0x811C9DC5 ^ _seed;
    for (final int unit in label.codeUnits) {
      hash = _imul(hash ^ (unit & 0xFF), 0x01000193);
      hash = _imul(hash ^ (unit >> 8), 0x01000193);
    }
    return SeededRng(hash);
  }

  /// The next 32-bit unsigned integer.
  int nextUint32() {
    _state = (_state + 0x6D2B79F5) & _mask;
    int t = _state;
    t = _imul(t ^ (t >> 15), t | 1);
    t = (t ^ (t + _imul(t ^ (t >> 7), t | 61))) & _mask;
    return (t ^ (t >> 14)) & _mask;
  }

  /// A number from 0 (inclusive) to 1 (exclusive).
  double nextDouble() => nextUint32() / 4294967296.0;

  /// A number from [min] (inclusive) to [max] (exclusive).
  double nextRange(double min, double max) => min + (max - min) * nextDouble();

  /// An integer from 0 (inclusive) to [max] (exclusive). [max] must be 1 or
  /// more.
  int nextInt(int max) {
    assert(max >= 1, 'max must be at least 1');
    return (nextDouble() * max).floor();
  }

  bool nextBool() => nextUint32() & 1 == 1;

  /// An element of [items] chosen uniformly. [items] must not be empty.
  T pick<T>(List<T> items) => items[nextInt(items.length)];

  /// 32-bit multiply that keeps only the low 32 bits.
  static int _imul(int a, int b) {
    final int ah = (a >> 16) & 0xFFFF;
    final int al = a & 0xFFFF;
    return ((al * b) + (((ah * b) & 0xFFFF) << 16)) & _mask;
  }
}
