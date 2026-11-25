import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ruach/app_services.dart';
import 'package:ruach/core/config/app_config.dart';
import 'package:ruach/l10n/app_localizations.dart';
import 'package:ruach/screens/app_route.dart';
import 'package:ruach/screens/error_screen.dart';
import 'package:ruach/screens/daily_run_screen.dart';
import 'package:ruach/screens/garage_screen.dart';
import 'package:ruach/screens/home_screen.dart';
import 'package:ruach/screens/language_screen.dart';
import 'package:ruach/screens/licenses_screen.dart';
import 'package:ruach/screens/mode_screen.dart';
import 'package:ruach/screens/onboarding_screen.dart';
import 'package:ruach/screens/race_screen.dart';
import 'package:ruach/screens/result_screen.dart';
import 'package:ruach/screens/routes.dart';
import 'package:ruach/screens/settings_screen.dart';
import 'package:ruach/screens/tilt_calibration_screen.dart';
import 'package:ruach/screens/track_intro_screen.dart';
import 'package:ruach/screens/upgrade_screen.dart';
import 'package:ruach/screens/verse_library_screen.dart';
import 'package:ruach/theme/app_theme.dart';
import 'package:ruach/theme/tokens.dart';
import 'package:ruach/utils/error_handler.dart';

/// The app root: the scope, the theme and language, the named routes, and the
/// full-screen fallback when something unexpected goes wrong.
class RuachApp extends StatefulWidget {
  const RuachApp({required this.services, super.key});

  final AppServices services;

  @override
  State<RuachApp> createState() => _RuachAppState();
}

class _RuachAppState extends State<RuachApp> with WidgetsBindingObserver {
  AppServices get _s => widget.services;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeLocales(List<Locale>? locales) => _s.locale.deviceChanged();

  @override
  Widget build(BuildContext context) {
    return _s.scope(
      child: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[_s.locale, _s.theme]),
        builder: (BuildContext context, Widget? _) => WidgetsApp(
          color: AppColors.light.bgPrimary,
          debugShowCheckedModeBanner: false,
          locale: _s.locale.locale,
          localizationsDelegates: const <LocalizationsDelegate<Object?>>[
            AppLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          initialRoute: _s.settings.value.onboardingDone ? Routes.home : Routes.onboarding,
          onGenerateRoute: _route,
          builder: _frame,
        ),
      ),
    );
  }

  /// Theme and fallback around the navigator.
  Widget _frame(BuildContext context, Widget? navigator) {
    final bool deviceIsDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final AppThemeData theme = _s.theme.isDark(deviceIsDark: deviceIsDark)
        ? AppThemeData.dark()
        : AppThemeData.light();
    return AppTheme(
      data: theme,
      child: ValueListenableBuilder<FatalError?>(
        valueListenable: _s.errors.fatal,
        builder: (BuildContext context, FatalError? fatal, Widget? _) {
          if (fatal == null) return navigator ?? const SizedBox.shrink();
          return ErrorScreen(onRetry: _s.errors.clear, onReport: _report);
        },
      ),
    );
  }

  /// Opens an email to support with the end of the local log.
  Future<void> _report() async {
    final String log = await _s.ports.log.readAll();
    final String tail = log.length > _reportChars ? log.substring(log.length - _reportChars) : log;
    final String subject = Uri.encodeComponent('${AppConfig.appName} error report');
    final String body = Uri.encodeComponent(tail);
    await _s.ports.url.open(
      Uri.parse('mailto:${AppConfig.supportEmail}?subject=$subject&body=$body'),
    );
  }

  static const int _reportChars = 1500;

  Route<void> _route(RouteSettings settings) {
    return AppRoute<void>(
      settings: settings,
      reduceMotion: ui.PlatformDispatcher.instance.accessibilityFeatures.disableAnimations,
      builder: (BuildContext context) => _page(settings),
    );
  }

  /// The menu screens get the banner once one is loaded.
  Widget _menu(Widget Function(Widget? banner) build) {
    final BannerHost? host = _s.banner;
    if (host == null) return build(null);
    return ListenableBuilder(
      listenable: host.changes,
      builder: (BuildContext context, Widget? _) => build(host.banner),
    );
  }

  Widget _tilt(Widget Function(bool available) build) {
    return ValueListenableBuilder<bool>(
      valueListenable: _s.tiltAvailable,
      builder: (BuildContext context, bool available, Widget? _) => build(available),
    );
  }

  Widget _page(RouteSettings settings) {
    final Object? args = settings.arguments;
    switch (settings.name) {
      case Routes.onboarding:
        return _tilt((bool tilt) => OnboardingScreen(tiltAvailable: tilt));
      case Routes.dailyRun:
        return DailyRunScreen(onShare: _s.ports.share.shareText);
      case Routes.garage:
        return _menu((Widget? b) => GarageScreen(banner: b, onShare: _s.ports.share.shareText));
      case Routes.settings:
        return _menu((Widget? b) => SettingsScreen(onOpenUrl: _s.ports.url.open, banner: b));
      case Routes.language:
        return const LanguageScreen();
      case Routes.tiltCalibration:
        return _tilt(
          (bool tilt) => TiltCalibrationScreen(tilt: _s.ports.tilt.roll, tiltAvailable: tilt),
        );
      case Routes.licenses:
        return const LicensesScreen();
      case Routes.upgrade:
        return const UpgradeScreen();
      case Routes.verseLibrary:
        return VerseLibraryScreen(onShare: _s.ports.share.shareText);
      case Routes.mode:
        if (args is ModeArgs) {
          return _menu((Widget? b) => ModeScreen(mode: args.mode, banner: b));
        }
      case Routes.trackIntro:
        if (args is TrackIntroArgs) {
          return TrackIntroScreen(
            mode: args.mode,
            trackId: args.trackId,
            weeklyIndex: args.weeklyIndex,
            onShare: _s.ports.share.shareText,
          );
        }
      case Routes.race:
        if (args is RaceArgs) {
          return _tilt(
            (bool tilt) => RaceScreen(args: args, tilt: _s.ports.tilt.roll, tiltAvailable: tilt),
          );
        }
      case Routes.result:
        return ResultScreen(
          onShare: _s.ports.share.shareText,
          onRequestReview: _s.ports.review.requestReview,
        );
    }
    // Home, and any name or arguments that do not fit, land on Home.
    return _menu((Widget? b) => HomeScreen(banner: b, onShare: _s.ports.share.shareText));
  }
}
