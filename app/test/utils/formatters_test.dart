import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/utils/formatters.dart';

void main() {
  group('formatLapTime', () {
    test('formats minutes, seconds and hundredths', () {
      expect(
        formatLapTime(const Duration(minutes: 1, seconds: 23, milliseconds: 450)),
        '01:23.45',
      );
    });

    test('pads small values', () {
      expect(formatLapTime(const Duration(milliseconds: 5)), '00:00.00');
      expect(formatLapTime(const Duration(seconds: 7, milliseconds: 90)), '00:07.09');
    });

    test('truncates rather than rounds', () {
      expect(formatLapTime(const Duration(seconds: 1, milliseconds: 999)), '00:01.99');
    });

    test('shows a negative duration as zero', () {
      expect(formatLapTime(const Duration(seconds: -3)), '00:00.00');
    });

    test('lets minutes grow past two digits', () {
      expect(formatLapTime(const Duration(minutes: 100)), '100:00.00');
    });
  });

  test('a missing lap time shows dashes', () {
    expect(formatLapTimeOrDash(null), '--:--.--');
    expect(formatLapTimeOrDash(const Duration(seconds: 61)), '01:01.00');
  });

  test('position, lap and count use plain digits', () {
    expect(formatPosition(3, 6), '3/6');
    expect(formatLap(2, 3), '2/3');
    expect(formatCount(1234), '1234');
  });
}
