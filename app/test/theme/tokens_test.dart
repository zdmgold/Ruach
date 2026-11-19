import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/theme/tokens.dart';

/// Relative luminance of a colour, as defined by WCAG 2.
double _luminance(Color color) {
  final int argb = color.toARGB32();
  double channel(int shift) {
    final double c = ((argb >> shift) & 0xFF) / 255;
    return c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(16) + 0.7152 * channel(8) + 0.0722 * channel(0);
}

/// WCAG contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final double la = _luminance(a);
  final double lb = _luminance(b);
  final double lighter = math.max(la, lb);
  final double darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  const double textFloor = 4.5;
  const double graphicFloor = 3.0;

  final Map<String, AppColors> themes = <String, AppColors>{
    'light': AppColors.light,
    'dark': AppColors.dark,
  };

  for (final MapEntry<String, AppColors> entry in themes.entries) {
    final String name = entry.key;
    final AppColors c = entry.value;
    final Map<String, Color> surfaces = <String, Color>{
      'bgPrimary': c.bgPrimary,
      'bgSecondary': c.bgSecondary,
      'bgTertiary': c.bgTertiary,
      'verseCardSurface': c.verseCardSurface,
    };
    final Map<String, Color> texts = <String, Color>{
      'textPrimary': c.textPrimary,
      'textSecondary': c.textSecondary,
      'textTertiary': c.textTertiary,
    };

    group('$name theme contrast', () {
      for (final MapEntry<String, Color> text in texts.entries) {
        for (final MapEntry<String, Color> surface in surfaces.entries) {
          test('${text.key} on ${surface.key} is at least $textFloor:1', () {
            expect(_contrast(text.value, surface.value), greaterThanOrEqualTo(textFloor));
          });
        }
      }

      // Coloured text is only drawn on the two main surfaces.
      final Map<String, Color> coloured = <String, Color>{
        'accent': c.accent,
        'error': c.error,
        'success': c.success,
        'warning': c.warning,
      };
      for (final MapEntry<String, Color> text in coloured.entries) {
        for (final Color surface in <Color>[c.bgPrimary, c.bgSecondary]) {
          test('${text.key} on bgPrimary and bgSecondary is at least $textFloor:1', () {
            expect(_contrast(text.value, surface), greaterThanOrEqualTo(textFloor));
          });
        }
      }

      test('the label on accent is at least $textFloor:1', () {
        expect(_contrast(c.onAccent, c.accent), greaterThanOrEqualTo(textFloor));
      });

      // Meter, star and gift fills are graphics, not text.
      final Map<String, Color> graphics = <String, Color>{
        'starFill': c.starFill,
        'giftFill': c.giftFill,
        'ruachMeter': c.ruachMeter,
      };
      for (final MapEntry<String, Color> graphic in graphics.entries) {
        for (final Color surface in <Color>[c.bgPrimary, c.bgSecondary]) {
          test('${graphic.key} is at least $graphicFloor:1 against the main surfaces', () {
            expect(_contrast(graphic.value, surface), greaterThanOrEqualTo(graphicFloor));
          });
        }
      }
    });
  }

  test('the contrast function matches known values', () {
    const Color black = Color(0xFF000000);
    const Color white = Color(0xFFFFFFFF);
    expect(_contrast(black, white), closeTo(21, 0.001));
    expect(_contrast(white, white), closeTo(1, 0.001));
  });

  test('the spacing scale is the one in the blueprint', () {
    expect(
      <double>[
        AppSpacing.s2,
        AppSpacing.s4,
        AppSpacing.s8,
        AppSpacing.s16,
        AppSpacing.s24,
        AppSpacing.s32,
        AppSpacing.s48,
        AppSpacing.s64,
      ],
      <double>[2, 4, 8, 16, 24, 32, 48, 64],
    );
  });

  test('race controls are larger than ordinary targets', () {
    expect(AppHit.race, greaterThan(AppHit.min));
    expect(AppHit.min, greaterThanOrEqualTo(48));
  });
}
