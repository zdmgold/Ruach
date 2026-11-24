import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ruach/app_services.dart';
import 'package:ruach/core/config/ad_units.dart';
import 'package:ruach/core/logic/progress_codec.dart';
import 'package:ruach/core/logic/verse_repository.dart';
import 'package:ruach/platform/ad_banner.dart';
import 'package:ruach/platform/ad_service.dart';
import 'package:ruach/platform/asset_verse_source.dart';
import 'package:ruach/platform/billing_service.dart';
import 'package:ruach/platform/consent_service.dart';
import 'package:ruach/platform/flags_service.dart';
import 'package:ruach/platform/log_service.dart';
import 'package:ruach/platform/notification_service.dart';
import 'package:ruach/platform/share_service.dart';
import 'package:ruach/platform/storage_service.dart';
import 'package:ruach/platform/tilt_service.dart';
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

/// Builds every service and provider in boot order and loads the saved state.
/// Nothing here waits for the network: purchase state, consent and flags are
/// read after the first frame (see [AppServices.onStart]).
Future<AppServices> bootServices() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[DeviceOrientation.portraitUp]);

  final DirectoryFileStore files = await DirectoryFileStore.open();
  final PreferencesStore prefs = PreferencesStore();

  final LogService log = LogService(files);
  await log.load();
  final AppErrorHandler errors = AppErrorHandler(
    (Object error, StackTrace? stack, {required bool fatal}) {
      final String trace = stack?.toString() ?? '';
      final String short = trace.length > 600 ? trace.substring(0, 600) : trace;
      log.log('${fatal ? 'FATAL' : 'error'}: $error\n$short');
    },
  )..install();

  final SettingsProvider settings = SettingsProvider(prefs, onError: log.log);
  await settings.load();
  final ProgressProvider progress = ProgressProvider(ProgressRepository(files), log: log);
  await progress.load();
  final bool firstSession = progress.origin == ProgressOrigin.firstRun;
  final GarageProvider garage = GarageProvider(progress, prefs);
  await garage.load();

  final ThemeProvider theme = ThemeProvider(settings);
  final LocaleProvider locale = LocaleProvider(
    settings,
    deviceTag: () => ui.PlatformDispatcher.instance.locale.toLanguageTag(),
  );

  final BillingService billing = BillingService(prefs, onError: log.log);
  final EntitlementProvider entitlement = EntitlementProvider(billing);
  final ConsentProvider consent = ConsentProvider(ConsentService(onError: log.log), entitlement);
  final FlagsProvider flags = FlagsProvider(FlagsService());
  final AdService adService = AdService(
    defaultTargetPlatform == TargetPlatform.iOS ? AdUnits.iosTest : AdUnits.androidTest,
    onError: log.log,
  );
  final AdProvider ads = AdProvider(adService, consent, flags, firstSession: firstSession);
  final DailyProvider daily = DailyProvider(progress, settings, NotificationService(onError: log.log));
  final VerseProvider verses = VerseProvider(VerseRepository(AssetVerseSource()), progress, locale);

  final TiltService tilt = TiltService();
  late final AppServices services;
  services = AppServices(
    settings: settings,
    theme: theme,
    locale: locale,
    progress: progress,
    garage: garage,
    entitlement: entitlement,
    race: RaceProvider(progress),
    consent: consent,
    ads: ads,
    daily: daily,
    verses: verses,
    flags: flags,
    ports: ShellPorts(share: ShareService(), url: UrlService(), tilt: tilt, log: log),
    errors: errors,
    banner: AdBannerHost(adService, ads),
    onStart: () async {
      unawaited(flags.load());
      unawaited(tilt.isAvailable().then((bool ok) => services.tiltAvailable.value = ok));
      await entitlement.refresh();
      await consent.refresh();
      await consent.showFormIfRequired();
      await ads.initialize();
    },
  );
  return services;
}
