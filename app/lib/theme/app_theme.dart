import 'package:flutter/widgets.dart';

import 'package:ruach/theme/tokens.dart';
import 'package:ruach/theme/typography.dart';

/// The resolved look for one theme: colours and text styles.
@immutable
class AppThemeData {
  AppThemeData._(this.brightness, this.colors) : type = AppTypography(colors);

  /// The warm light theme (the default).
  factory AppThemeData.light() => AppThemeData._(Brightness.light, AppColors.light);

  /// The dark theme.
  factory AppThemeData.dark() => AppThemeData._(Brightness.dark, AppColors.dark);

  /// Light or dark, for the theme the system or the player chose.
  factory AppThemeData.of(Brightness brightness) =>
      brightness == Brightness.dark ? AppThemeData.dark() : AppThemeData.light();

  final Brightness brightness;
  final AppColors colors;
  final AppTypography type;

  // Two themes are equal when they are the same brightness, so rebuilding the
  // theme from the same setting does not rebuild every widget that reads it.
  @override
  bool operator ==(Object other) =>
      other is AppThemeData && other.brightness == brightness;

  @override
  int get hashCode => brightness.hashCode;
}

/// Makes the theme available to widgets below it. This is a plain
/// inherited widget, not Material's Theme: Ruach draws its own components.
class AppTheme extends InheritedWidget {
  const AppTheme({super.key, required this.data, required super.child});

  final AppThemeData data;

  /// The theme in effect at [context].
  static AppThemeData of(BuildContext context) {
    final AppTheme? scope = context.dependOnInheritedWidgetOfExactType<AppTheme>();
    assert(scope != null, 'No AppTheme found above this widget.');
    return scope!.data;
  }

  @override
  bool updateShouldNotify(AppTheme oldWidget) => data != oldWidget.data;
}
