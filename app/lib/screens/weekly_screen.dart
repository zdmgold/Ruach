import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:ruach/app_scope.dart';
import 'package:ruach/core/logic/daily_seed.dart';
import 'package:ruach/core/models/race_config.dart';
import 'package:ruach/l10n/app_localizations.dart';
import 'package:ruach/l10n/names.dart';
import 'package:ruach/screens/routes.dart';
import 'package:ruach/theme/icons.dart';
import 'package:ruach/theme/tokens.dart';
import 'package:ruach/utils/formatters.dart';
import 'package:ruach/widgets/app_chip.dart';
import 'package:ruach/widgets/app_row.dart';
import 'package:ruach/widgets/nav_bar.dart';
import 'package:ruach/widgets/screen_frame.dart';

/// The Weekly Circuit: seven races, one a day from Monday. A day that has
/// passed can still be run later in the week; a day that has not come yet is
/// shown but closed. The week's total appears once all seven are run.
class WeeklyScreen extends StatelessWidget {
  const WeeklyScreen({super.key, this.banner});

  final Widget? banner;

  @override
  Widget build(BuildContext context) {
    final AppScope scope = AppScope.of(context);
    final AppLocalizations l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[scope.progress, scope.daily, scope.ads]),
      builder: (BuildContext context, Widget? _) {
        final List<DailyChallenge> week = scope.daily.week;
        final CivilDate today = scope.daily.today;
        final List<Duration?> times = <Duration?>[
          for (int i = 0; i < week.length; i++) scope.daily.weeklyTime(i),
        ];
        final bool complete = times.every((Duration? t) => t != null);
        final Duration total = times.fold<Duration>(
          Duration.zero,
          (Duration sum, Duration? t) => sum + (t ?? Duration.zero),
        );
        final bool bannerOn = scope.ads.bannersAllowed;
        return ScreenFrame(
          bannerHeight: bannerOn ? 50 : 0,
          banner: bannerOn ? banner : null,
          removeAdsLabel: l.settingsRemoveAds,
          onRemoveAds: () => unawaited(Navigator.of(context).pushNamed(Routes.upgrade)),
          navBar: NavBar(
            title: l.modeWeeklyCircuit,
            onBack: () => Navigator.of(context).maybePop(),
            backLabel: l.commonBack,
          ),
          children: <Widget>[
            if (complete)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AppChip(
                    label: l.weeklyTotal(formatLapTime(total)),
                    tone: ChipTone.accent,
                  ),
                ),
              ),
            for (int i = 0; i < week.length; i++)
              _day(context, l, week[i], i, times[i], today),
          ],
        );
      },
    );
  }

  Widget _day(
    BuildContext context,
    AppLocalizations l,
    DailyChallenge c,
    int index,
    Duration? time,
    CivilDate today,
  ) {
    final bool open = c.date.compareTo(today) <= 0;
    final String label = l.weeklyDay(index + 1);
    if (!open) {
      return AppRow(
        icon: AppIcons.locked,
        label: label,
        subtitle: l.weeklyOpensLater,
      );
    }
    return AppRow(
      icon: AppIcons.weeklyCircuit,
      label: label,
      subtitle: trackName(l, c.trackId),
      trailing: time == null ? null : AppChip(label: l.weeklyTime(formatLapTime(time))),
      onTap: () => unawaited(
        Navigator.of(context).pushNamed(
          Routes.trackIntro,
          arguments: TrackIntroArgs(
            mode: RaceMode.weeklyCircuit,
            trackId: c.trackId,
            weeklyIndex: index,
          ),
        ),
      ),
    );
  }
}
