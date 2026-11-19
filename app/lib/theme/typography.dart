import 'package:flutter/widgets.dart';

import 'package:ruach/theme/tokens.dart';

/// Text styles per role (blueprint section 6, Typography).
///
/// One bundled Latin face, Barlow, serves every role. Arabic, Hebrew, Hindi,
/// Japanese, Korean and Chinese glyphs are not in Barlow, so the platform
/// falls back to its own system fonts for them and the app stays small.
@immutable
class AppTypography {
  AppTypography(AppColors colors)
      : display = TextStyle(
          fontFamily: family,
          fontSize: 34,
          fontWeight: FontWeight.w700,
          height: 1.1,
          color: colors.textPrimary,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        ),
        headline = TextStyle(
          fontFamily: family,
          fontSize: 28,
          fontWeight: FontWeight.w600,
          height: 1.2,
          color: colors.textPrimary,
        ),
        title1 = TextStyle(
          fontFamily: family,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: colors.textPrimary,
        ),
        title2 = TextStyle(
          fontFamily: family,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: colors.textPrimary,
        ),
        body = TextStyle(
          fontFamily: family,
          fontSize: 17,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: colors.textPrimary,
        ),
        callout = TextStyle(
          fontFamily: family,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.4,
          color: colors.textPrimary,
        ),
        footnote = TextStyle(
          fontFamily: family,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          height: 1.4,
          color: colors.textSecondary,
        ),
        caption = TextStyle(
          fontFamily: family,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.3,
          color: colors.textSecondary,
        ),
        sectionHeader = TextStyle(
          fontFamily: family,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.3,
          letterSpacing: 0.8,
          color: colors.textTertiary,
        );

  /// The bundled font family, declared in pubspec.yaml.
  static const String family = 'Barlow';

  /// Brand name, race position and lap times. Tabular figures keep digits
  /// from jittering as a timer runs.
  final TextStyle display;

  final TextStyle headline;
  final TextStyle title1;
  final TextStyle title2;

  /// Verses and reader text.
  final TextStyle body;

  /// Buttons and labels.
  final TextStyle callout;

  final TextStyle footnote;
  final TextStyle caption;

  /// Uppercase, letter-spaced labels above lists. The widget that uses it
  /// uppercases the text.
  final TextStyle sectionHeader;
}
