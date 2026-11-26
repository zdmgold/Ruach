import 'package:flutter/widgets.dart';
import 'package:ruach/app_scope.dart';
import 'package:ruach/core/logic/progress_codec.dart';
import 'package:ruach/core/logic/verse_repository.dart';
import 'package:ruach/core/ports/verse_source.dart';
import 'package:ruach/l10n/app_localizations.dart';
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
import 'package:ruach/theme/app_theme.dart';

import 'fakes.dart';

/// One verse for every moment, so screens that show a verse have something to
/// show.
final class StubVerses implements VerseDataSource {
  @override
  Future<Object?> load(String language) async => <String, Object?>{
        'verses': <Object?>[
          <String, Object?>{
            'ref': 'Ps.23.1',
            'text': 'The LORD is my shepherd.',
            'moments': <String>[
              'win',
              'podium',
              'encouragement',
              'daily',
              'track-intro',
              'milestone',
              'welcome-back',
            ],
          },
        ],
      };
}

/// Every provider on fakes, an [AppScope] around a screen, and a record of
/// the routes the screen pushed.
final class TestScope {
  TestScope({DateTime? now}) : now = now ?? DateTime(2026, 11, 23, 12) {
    settings = SettingsProvider(FakeKeyValueStore());
    theme = ThemeProvider(settings);
    locale = LocaleProvider(settings, deviceTag: () => 'en');
    progress = ProgressProvider(ProgressRepository(FakeFileStore()));
    garage = GarageProvider(progress, FakeKeyValueStore());
    entitlement = EntitlementProvider(billing);
    consent = ConsentProvider(consentPort, entitlement);
    flags = FlagsProvider(flagsPort);
    ads = AdProvider(
      adsPort,
      consent,
      flags,
      firstSession: false,
      clock: () => this.now,
    );
    race = RaceProvider(progress);
    daily = DailyProvider(progress, settings, notifications, clock: () => this.now);
    verses = VerseProvider(VerseRepository(StubVerses()), progress, locale);
  }

  final DateTime now;
  final FakeBilling billing = FakeBilling();
  final FakeConsent consentPort = FakeConsent();
  final FakeAds adsPort = FakeAds();
  final FakeFlags flagsPort = FakeFlags();
  final FakeNotifications notifications = FakeNotifications();

  late final SettingsProvider settings;
  late final ThemeProvider theme;
  late final LocaleProvider locale;
  late final ProgressProvider progress;
  late final GarageProvider garage;
  late final EntitlementProvider entitlement;
  late final ConsentProvider consent;
  late final FlagsProvider flags;
  late final AdProvider ads;
  late final RaceProvider race;
  late final DailyProvider daily;
  late final VerseProvider verses;

  /// Route names pushed so far, with their arguments, oldest first.
  final List<(String, Object?)> pushed = <(String, Object?)>[];
  bool homeBuilt = false;

  /// [home] inside the scope, the theme and a [WidgetsApp] whose other routes
  /// are placeholders that are recorded in [pushed].
  Widget app(Widget home) {
    return AppScope(
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
      child: AppTheme(
        data: AppThemeData.light(),
        child: WidgetsApp(
          color: const Color(0xFF000000),
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const <LocalizationsDelegate<Object?>>[
            AppLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          onGenerateRoute: (RouteSettings s) {
            // The first '/' is the screen under test; asking for '/' again
            // (the app's Home) is recorded like any other route.
            if (s.name == '/' && !homeBuilt) {
              homeBuilt = true;
              return PageRouteBuilder<void>(
                settings: s,
                pageBuilder: (BuildContext c, Animation<double> a, Animation<double> b) => home,
              );
            }
            pushed.add((s.name ?? '', s.arguments));
            return PageRouteBuilder<void>(
              settings: s,
              pageBuilder: (BuildContext c, Animation<double> a, Animation<double> b) =>
                  const SizedBox.shrink(),
            );
          },
          pageRouteBuilder: <T>(RouteSettings s, WidgetBuilder builder) =>
              PageRouteBuilder<T>(
            settings: s,
            pageBuilder: (BuildContext c, Animation<double> a, Animation<double> b) =>
                builder(c),
          ),
        ),
      ),
    );
  }
}
