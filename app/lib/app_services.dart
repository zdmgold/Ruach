import 'package:flutter/widgets.dart';
import 'package:ruach/app_scope.dart';
import 'package:ruach/core/ports/device_ports.dart';
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
import 'package:ruach/utils/error_handler.dart';

/// The device hooks screens use but the providers do not own.
final class ShellPorts {
  const ShellPorts({
    required this.share,
    required this.url,
    required this.tilt,
    required this.log,
    required this.review,
  });

  final SharePort share;
  final UrlPort url;
  final TiltPort tilt;
  final LogPort log;
  final ReviewPort review;
}

/// Supplies the banner widget to menu screens: [banner] is null until an ad is
/// loaded and allowed, and [changes] fires when that changes.
abstract interface class BannerHost {
  Listenable get changes;

  Widget? get banner;
}

/// Everything the app root needs, built once at start (see `boot.dart`) or
/// from fakes in tests.
final class AppServices {
  AppServices({
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
    required this.ports,
    required this.errors,
    this.banner,
    this.onStart,
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
  final ShellPorts ports;
  final AppErrorHandler errors;
  final BannerHost? banner;

  /// Work that runs after the first frame (purchase state, consent, flags).
  final Future<void> Function()? onStart;

  /// Whether the phone has a tilt sensor; true until the check says otherwise.
  final ValueNotifier<bool> tiltAvailable = ValueNotifier<bool>(true);

  AppScope scope({required Widget child}) => AppScope(
        settings: settings,
        theme: theme,
        locale: locale,
        progress: progress,
        garage: garage,
        entitlement: entitlement,
        race: race,
        consent: consent,
        ads: ads,
        daily: daily,
        verses: verses,
        flags: flags,
        child: child,
      );
}
