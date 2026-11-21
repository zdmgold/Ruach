import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/ports/device_ports.dart';
import 'package:ruach/platform/audio_service.dart';
import 'package:ruach/platform/notification_service.dart';
import 'package:ruach/platform/tilt_service.dart';

void main() {
  group('TiltService.rollFrom', () {
    test('upright is zero', () {
      expect(TiltService.rollFrom(0, 9.8), closeTo(0, 1e-9));
    });

    test('right edge down is positive, left edge down is negative', () {
      expect(TiltService.rollFrom(-4.9, 8.5), greaterThan(0));
      expect(TiltService.rollFrom(4.9, 8.5), lessThan(0));
    });

    test('a 30 degree turn reads as 30 degrees', () {
      final double a = 30 * math.pi / 180;
      expect(TiltService.rollFrom(-9.8 * math.sin(a), 9.8 * math.cos(a)), closeTo(a, 1e-9));
    });

    test('no reading is zero', () {
      expect(TiltService.rollFrom(0, 0), 0);
    });
  });

  group('NotificationService.nextOccurrence', () {
    test('later today when the time has not passed', () {
      expect(
        NotificationService.nextOccurrence(DateTime(2026, 11, 21, 8, 0), 19, 30),
        DateTime(2026, 11, 21, 19, 30),
      );
    });

    test('tomorrow when it has passed or is exactly now', () {
      expect(
        NotificationService.nextOccurrence(DateTime(2026, 11, 21, 20), 19, 30),
        DateTime(2026, 11, 22, 19, 30),
      );
      expect(
        NotificationService.nextOccurrence(DateTime(2026, 11, 21, 19, 30), 19, 30),
        DateTime(2026, 11, 22, 19, 30),
      );
    });

    test('rolls over month ends', () {
      expect(
        NotificationService.nextOccurrence(DateTime(2026, 11, 30, 23), 7, 0),
        DateTime(2026, 12, 1, 7, 0),
      );
    });
  });

  test('every sound effect has its own asset name', () {
    final Set<String> names = <String>{for (final SoundEffect e in SoundEffect.values) AudioService.assetFor(e)};
    expect(names.length, SoundEffect.values.length);
    expect(AudioService.assetFor(SoundEffect.go), 'audio/go.ogg');
  });
}
