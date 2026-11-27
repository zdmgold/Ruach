import 'package:flutter/widgets.dart';

/// Colour tokens for one theme. Every colour the app draws comes from here;
/// widgets never contain a raw colour value (blueprint section 6).
///
/// Text and graphic pairs are checked by `test/theme/tokens_test.dart`, which
/// recomputes every contrast ratio and fails the build below the floor.
@immutable
class AppColors {
  const AppColors({
    required this.bgPrimary,
    required this.bgSecondary,
    required this.bgTertiary,
    required this.accent,
    required this.onAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.error,
    required this.success,
    required this.warning,
    required this.starFill,
    required this.giftFill,
    required this.ruachMeter,
    required this.verseCardSurface,
  });

  /// Screen background.
  final Color bgPrimary;

  /// Cards, sheets and dialogs.
  final Color bgSecondary;

  /// Inputs and empty or disabled fills.
  final Color bgTertiary;

  /// Primary actions and the active state.
  final Color accent;

  /// Label colour on top of [accent].
  final Color onAccent;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  /// Validation and destructive actions.
  final Color error;

  /// Saved and completed.
  final Color success;

  /// Attention.
  final Color warning;

  /// Earned stars.
  final Color starFill;

  /// Gifts (upgrade points).
  final Color giftFill;

  /// The Ruach boost meter.
  final Color ruachMeter;

  /// Background of a verse card. Text on it uses the three text tokens.
  final Color verseCardSurface;

  /// Hairline border and divider colour: the tertiary text colour, faded.
  Color get border => textTertiary.withValues(alpha: 0.35);

  static const AppColors light = AppColors(
    bgPrimary: Color(0xFFF6F1E7),
    bgSecondary: Color(0xFFFFFFFF),
    bgTertiary: Color(0xFFECE4D3),
    accent: Color(0xFF9A4B0C),
    onAccent: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1A1510),
    textSecondary: Color(0xFF5B5144),
    textTertiary: Color(0xFF6A5F50),
    error: Color(0xFFB3261E),
    success: Color(0xFF1B6B3A),
    warning: Color(0xFF8A5A00),
    starFill: Color(0xFFB8750A),
    giftFill: Color(0xFF1B6B3A),
    ruachMeter: Color(0xFF0E6E8A),
    verseCardSurface: Color(0xFFFBF3E0),
  );

  static const AppColors dark = AppColors(
    bgPrimary: Color(0xFF14110D),
    bgSecondary: Color(0xFF1F1B15),
    bgTertiary: Color(0xFF2C261D),
    accent: Color(0xFFF0A04B),
    onAccent: Color(0xFF1A0E02),
    textPrimary: Color(0xFFF7F2E8),
    textSecondary: Color(0xFFBDB3A2),
    textTertiary: Color(0xFFA89E8D),
    error: Color(0xFFFF8A80),
    success: Color(0xFF5FD08B),
    warning: Color(0xFFF5B94A),
    starFill: Color(0xFFF5B94A),
    giftFill: Color(0xFF5FD08B),
    ruachMeter: Color(0xFF6CCBE8),
    verseCardSurface: Color(0xFF2A2318),
  );
}

/// Colours of the race world. They do not change with the theme, because the
/// track looks the same in light and dark mode. No text is drawn on them
/// directly; the HUD sits on its own panels.
abstract final class WorldColors {
  static const Color trackAsphalt = Color(0xFF59617A);
  static const Color trackSand = Color(0xFFFFD98A);
  static const Color trackStone = Color(0xFFB8A9C9);
  static const Color trackDirt = Color(0xFFD9955A);
  static const Color trackCobble = Color(0xFF9C8FB0);
  static const Color trackFord = Color(0xFF5CC8F0);
  static const Color trackGrass = Color(0xFF7ADB5A);

  /// Ground beside the road.
  static const Color groundGrass = Color(0xFF4CCB4C);
  static const Color groundSand = Color(0xFFFFB85C);

  /// Road markings.
  static const Color line = Color(0xFFF4EFE4);
  static const Color lineDark = Color(0xFF26211A);
  static const Color guardrail = Color(0xFF9A9A94);
  static const Color lampHalo = Color(0xFFFFE9A8);

  /// Scenery.
  static const Color sceneryTree = Color(0xFF1FA14A);
  static const Color sceneryTreeEdge = Color(0xFF0E6B30);
  static const Color sceneryRock = Color(0xFFA7A3C4);
  static const Color sceneryWater = Color(0xFF2FB4F0);

  /// The player's vehicle, and the palette rival teams draw from.
  static const Color playerCar = Color(0xFFFFC400);
  static const List<Color> rivalCars = <Color>[
    Color(0xFFFF3B30),
    Color(0xFF1E7BFF),
    Color(0xFF8E3DFF),
    Color(0xFFFF4FA3),
    Color(0xFF00C2B8),
    Color(0xFFFF7A00),
    Color(0xFF2ED158),
    Color(0xFFF2F2F7),
  ];

  /// Kerb stripes along the road edge.
  static const Color kerbRed = Color(0xFFFF3B30);
  static const Color kerbWhite = Color(0xFFFFFFFF);

  /// Outline drawn round every vehicle so it reads on any ground.
  static const Color carOutline = Color(0xFF14121F);

  /// Car body details.
  static const Color carGlass = Color(0xFF2B3A44);
  static const Color carWheel = Color(0xFF1A1714);
  static const Color carWood = Color(0xFF8A5A2B);
}

/// Spacing scale. Every gap is chosen from this list.
abstract final class AppSpacing {
  static const double s2 = 2;
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s16 = 16;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s48 = 48;
  static const double s64 = 64;
}

/// Corner radii. There are no shadows; separation is by fill and hairline.
abstract final class AppRadii {
  static const double card = 16;
  static const double hero = 24;
  static const double chip = 12;
  static const double button = 12;
  static const double sheet = 20;
  static const double dialog = 16;
  static const double pill = 999;
}

/// Line widths.
abstract final class AppStroke {
  static const double hairline = 0.5;
  static const double focus = 2;
}

/// Animation durations (blueprint section 6, Motion). Under Reduce Motion
/// every interface animation becomes an instant change.
abstract final class AppDurations {
  static const Duration push = Duration(milliseconds: 350);
  static const Duration pop = Duration(milliseconds: 280);
  static const Duration sheet = Duration(milliseconds: 400);
  static const Duration press = Duration(milliseconds: 150);
  static const Duration reveal = Duration(milliseconds: 300);
  static const Duration themeChange = Duration(milliseconds: 200);
  static const Duration none = Duration.zero;
}

/// Touch target sizes.
abstract final class AppHit {
  /// Minimum size of any tappable thing.
  static const double min = 48;

  /// Minimum size of a race control (steer, brake, boost).
  static const double race = 72;

  /// Minimum gap between race controls.
  static const double raceGap = 24;
}

/// Fixed icon sizes.
abstract final class AppIconSizes {
  static const double navBar = 22;
  static const double rowLeading = 22;
  static const double rowTrailing = 16;
  static const double hero = 32;
}

/// Press feedback is opacity only.
abstract final class AppOpacity {
  static const double pressed = 0.7;
  static const double disabled = 0.4;
}
