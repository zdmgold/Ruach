import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:ruach/app_scope.dart';
import 'package:ruach/core/logic/catalog_ids.dart';
import 'package:ruach/core/logic/mode_rules.dart';
import 'package:ruach/core/models/race_config.dart';
import 'package:ruach/l10n/app_localizations.dart';
import 'package:ruach/l10n/names.dart';
import 'package:ruach/screens/milestone_block.dart';
import 'package:ruach/screens/routes.dart';
import 'package:ruach/screens/verse_block.dart';
import 'package:ruach/theme/app_icon.dart';
import 'package:ruach/theme/app_theme.dart';
import 'package:ruach/theme/icons.dart';
import 'package:ruach/theme/tokens.dart';
import 'package:ruach/widgets/app_card.dart';
import 'package:ruach/widgets/app_chip.dart';
import 'package:ruach/widgets/app_row.dart';
import 'package:ruach/widgets/gift_badge.dart';
import 'package:ruach/widgets/nav_bar.dart';
import 'package:ruach/widgets/pressable.dart';
import 'package:ruach/widgets/screen_frame.dart';
import 'package:ruach/widgets/section_header.dart';

/// The first screen: today's Daily Run and streak, Journey, Quick Race, the
/// Garage, and the other modes. Locked modes are shown, not hidden, so the
/// player can see what is coming.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.banner, this.onShare});

  final ShareText? onShare;

  /// The banner ad widget, supplied by the app shell. Shown only while the
  /// ad rules allow a banner.
  final Widget? banner;

  static const double bannerHeight = 50;

  static const List<RaceMode> _otherModes = <RaceMode>[
    RaceMode.timeTrial,
    RaceMode.weeklyCircuit,
    RaceMode.escapeRun,
    RaceMode.elimination,
  ];

  static IconData _iconFor(RaceMode mode) => switch (mode) {
        RaceMode.journey => AppIcons.journey,
        RaceMode.quickRace => AppIcons.play,
        RaceMode.timeTrial => AppIcons.timeTrial,
        RaceMode.dailyRun => AppIcons.dailyRun,
        RaceMode.weeklyCircuit => AppIcons.weeklyCircuit,
        RaceMode.escapeRun => AppIcons.escapeRun,
        RaceMode.elimination => AppIcons.elimination,
      };

  @override
  Widget build(BuildContext context) {
    final AppScope scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        scope.progress,
        scope.daily,
        scope.garage,
        scope.ads,
      ]),
      builder: (BuildContext context, Widget? _) => _build(context, scope),
    );
  }

  Widget _build(BuildContext context, AppScope scope) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AppThemeData theme = AppTheme.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final int gifts = scope.garage.gifts;
    final int streak = scope.daily.streak;
    final int journeyTotal = TrackIds.journey.length * 3;
    final String dailyTrack = trackName(l, scope.daily.challenge.trackId);

    void openMode(RaceMode mode) => unawaited(
          navigator.pushNamed(Routes.mode, arguments: ModeArgs(mode)),
        );

    return ScreenFrame(
      bannerHeight: scope.ads.bannersAllowed ? bannerHeight : 0,
      banner: scope.ads.bannersAllowed ? banner : null,
      removeAdsLabel: l.settingsRemoveAds,
      onRemoveAds: () => unawaited(Navigator.of(context).pushNamed(Routes.upgrade)),
      navBar: NavBar(
        title: l.appName,
        actions: <Widget>[
          GiftBadge(count: gifts, semanticLabel: l.giftCountSemantic(gifts)),
          Pressable(
            onTap: () => unawaited(navigator.pushNamed(Routes.settings)),
            semanticLabel: l.commonSettings,
            builder: (BuildContext context, bool pressed) => AppIcon(
              AppIcons.settings,
              size: AppIconSizes.navBar,
              color: theme.colors.textPrimary,
            ),
          ),
        ],
      ),
      children: <Widget>[
        WelcomeBackSlot(onShare: onShare),
        const SizedBox(height: AppSpacing.s16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
          child: AppCard(
            icon: _iconFor(RaceMode.dailyRun),
            label: l.homeDailyTitle,
            value: l.homeDailyToday(dailyTrack),
            onTap: () => unawaited(navigator.pushNamed(Routes.dailyRun)),
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: AppChip(
                  label: l.streakDays(streak),
                  tone: streak > 0 ? ChipTone.accent : ChipTone.neutral,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        _card(
          icon: _iconFor(RaceMode.journey),
          label: l.homeJourneyTitle,
          value: l.homeJourneyValue(
            TrackIds.journey.fold<int>(
              0,
              (int sum, String id) => sum + scope.progress.value.starsOn(id),
            ),
            journeyTotal,
          ),
          onTap: () => openMode(RaceMode.journey),
        ),
        const SizedBox(height: AppSpacing.s8),
        _card(
          icon: _iconFor(RaceMode.quickRace),
          label: l.homeQuickRaceTitle,
          value: Unlocks.mode(RaceMode.quickRace, scope.progress.value)
              ? l.homeQuickRaceValue
              : l.commonLocked,
          onTap: Unlocks.mode(RaceMode.quickRace, scope.progress.value)
              ? () => openMode(RaceMode.quickRace)
              : null,
        ),
        const SizedBox(height: AppSpacing.s8),
        _card(
          icon: AppIcons.garage,
          label: l.homeGarageTitle,
          value: l.homeGarageValue(gifts),
          onTap: () => unawaited(navigator.pushNamed(Routes.garage)),
        ),
        SectionHeader(l.homeModesHeader),
        for (final RaceMode mode in _otherModes)
          AppRow(
            icon: Unlocks.mode(mode, scope.progress.value) ? _iconFor(mode) : AppIcons.locked,
            label: modeName(l, mode),
            subtitle: Unlocks.mode(mode, scope.progress.value)
                ? modeBlurb(l, mode)
                : l.commonLocked,
            onTap: Unlocks.mode(mode, scope.progress.value) ? () => openMode(mode) : null,
          ),
        AppRow(
          icon: AppIcons.verse,
          label: l.libraryTitle,
          onTap: () => unawaited(navigator.pushNamed(Routes.verseLibrary)),
        ),
      ],
    );
  }

  Widget _card({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: AppCard(icon: icon, label: label, value: value, onTap: onTap),
    );
  }
}
