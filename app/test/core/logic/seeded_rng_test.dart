import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/logic/seeded_rng.dart';

List<int> _draw(SeededRng rng, int n) =>
    <int>[for (int i = 0; i < n; i++) rng.nextUint32()];

void main() {
  test('the same seed gives the same sequence', () {
    expect(_draw(SeededRng(42), 20), _draw(SeededRng(42), 20));
  });

  test('different seeds give different sequences', () {
    expect(_draw(SeededRng(1), 10), isNot(_draw(SeededRng(2), 10)));
  });

  test('values stay in range', () {
    final SeededRng rng = SeededRng(7);
    for (int i = 0; i < 2000; i++) {
      final double d = rng.nextDouble();
      expect(d >= 0 && d < 1, isTrue);
      final int n = rng.nextInt(6);
      expect(n >= 0 && n < 6, isTrue);
      final double r = rng.nextRange(-3, 5);
      expect(r >= -3 && r < 5, isTrue);
    }
  });

  test('the spread is roughly even', () {
    final SeededRng rng = SeededRng(99);
    double sum = 0;
    const int n = 5000;
    for (int i = 0; i < n; i++) {
      sum += rng.nextDouble();
    }
    expect(sum / n, closeTo(0.5, 0.03));
    final List<int> counts = List<int>.filled(4, 0);
    for (int i = 0; i < n; i++) {
      counts[rng.nextInt(4)]++;
    }
    for (final int c in counts) {
      expect(c, greaterThan(n ~/ 4 - 250));
      expect(c, lessThan(n ~/ 4 + 250));
    }
  });

  test('a fork does not depend on how much was drawn before it', () {
    final SeededRng a = SeededRng(5);
    final SeededRng b = SeededRng(5);
    _draw(a, 17);
    expect(_draw(a.fork('wind'), 5), _draw(b.fork('wind'), 5));
  });

  test('forks with different labels are independent streams', () {
    final SeededRng rng = SeededRng(5);
    expect(_draw(rng.fork('wind'), 8), isNot(_draw(rng.fork('ai'), 8)));
  });

  test('a fork of a different seed differs', () {
    expect(
      _draw(SeededRng(1).fork('ai'), 8),
      isNot(_draw(SeededRng(2).fork('ai'), 8)),
    );
  });

  test('pick returns members and nextBool gives both values', () {
    final SeededRng rng = SeededRng(3);
    const List<String> items = <String>['a', 'b', 'c'];
    final Set<String> seen = <String>{};
    final Set<bool> bools = <bool>{};
    for (int i = 0; i < 200; i++) {
      seen.add(rng.pick(items));
      bools.add(rng.nextBool());
    }
    expect(seen, items.toSet());
    expect(bools.length, 2);
  });
}
