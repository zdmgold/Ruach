import 'package:flutter/widgets.dart';
import 'package:ruach/providers/ad_provider.dart';
import 'package:ruach/providers/consent_provider.dart';
import 'package:ruach/providers/daily_provider.dart';
import 'package:ruach/providers/entitlement_provider.dart';
import 'package:ruach/providers/flags_provider.dart';
import 'package:ruach/providers/garage_provider.dart';
import 'package:ruach/providers/locale_provider.dart';
import 'package:ruach/providers/progress_provider.dart';
import 'package:ruach/providers/race_provider.dart';
import 'package:ruach/providers/settings_provider.dart';
import 'package:ruach/providers/theme_provider.dart';
import 'package:ruach/providers/verse_provider.dart';

/// Every provider, handed down the widget tree. The providers are listenables,
/// so screens listen to the one they need (with `ListenableBuilder`); the
/// scope itself never changes after start-up.
final class AppScope extends InheritedWidget {
  const AppScope({
    required this.settings,
    required this.theme,
    required this.locale,
    required this.progress,
    required this.garage,
    required this.entitlement,
    required this.race,
    required this.consent,
    required this.ads,
    required this.daily,
    required this.verses,
    required this.flags,
    required super.child,
    super.key,
  });

  final SettingsProvider settings;
  final ThemeProvider theme;
  final LocaleProvider locale;
  final ProgressProvider progress;
  final GarageProvider garage;
  final EntitlementProvider entitlement;
  final RaceProvider race;
  final ConsentProvider consent;
  final AdProvider ads;
  final DailyProvider daily;
  final VerseProvider verses;
  final FlagsProvider flags;

  static AppScope of(BuildContext context) {
    final AppScope? scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope above this context');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => false;
}
