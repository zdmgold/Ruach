import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:ruach/app_scope.dart';
import 'package:ruach/core/catalog/vehicles.dart';
import 'package:ruach/core/logic/daily_seed.dart';
import 'package:ruach/core/models/race_config.dart';
import 'package:ruach/core/models/verse.dart';
import 'package:ruach/l10n/app_localizations.dart';
import 'package:ruach/l10n/names.dart';
import 'package:ruach/screens/routes.dart';
import 'package:ruach/screens/verse_block.dart';
import 'package:ruach/theme/app_theme.dart';
import 'package:ruach/theme/icons.dart';
import 'package:ruach/theme/tokens.dart';
import 'package:ruach/widgets/app_chip.dart';
import 'package:ruach/widgets/app_row.dart';
import 'package:ruach/widgets/app_switch.dart';
import 'package:ruach/widgets/nav_bar.dart';
import 'package:ruach/widgets/primary_button.dart';
import 'package:ruach/widgets/screen_frame.dart';
import 'package:ruach/widgets/section_header.dart';

/// Today's Daily Run: the fixed setup everyone shares, how many tries are used,
/// the streak, the opt-in reminder and the verse of the day. Start goes to the
/// track introduction, which handles the extra-attempt rule.
class DailyRunScreen extends StatefulWidget {
  const DailyRunScreen({super.key, this.onShare});

  final ShareText? onShare;

  /// Wind stronger than this reads as "strong wind", weaker than
  /// [calmBelow] as "calm air" (the daily wind runs from 0 to 1.2).
  static const double strongFrom = 0.8;
  static const double calmBelow = 0.2;

  @override
  State<DailyRunScreen> createState() => _DailyRunScreenState();
}

class _DailyRunScreenState extends State<DailyRunScreen> {
  String? _note;

  Future<void> _setReminder(AppScope scope, AppLocalizations l, bool on) async {
    final bool ok = await scope.daily.setReminder(
      enabled: on,
      title: l.reminderTitle,
      body: l.reminderBody,
    );
    if (mounted) setState(() => _note = on && !ok ? l.settingsReminderDenied : null);
  }

  String _wind(AppLocalizations l, DailyChallenge c) {
    final double strength = c.wind.length;
    if (strength >= DailyRunScreen.strongFrom) return l.dailyWindStrong;
    if (strength < DailyRunScreen.calmBelow) return l.dailyWindCalm;
    return l.dailyWindLight;
  }

  @override
  Widget build(BuildContext context) {
    final AppScope scope = AppScope.of(context);
    final AppLocalizations l = AppLocalizations.of(context);
    final AppThemeData theme = AppTheme.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[scope.daily, scope.settings, scope.entitlement]),
      builder: (BuildContext context, Widget? _) {
        final DailyChallenge c = scope.daily.challenge;
        final bool done = scope.daily.completedToday;
        final int streak = scope.daily.streak;
        final bool extra = scope.daily.nextAttemptIsExtra && !scope.entitlement.adsRemoved;
        return ScreenFrame(
          navBar: NavBar(
            title: l.homeDailyTitle,
            onBack: () => Navigator.of(context).maybePop(),
            backLabel: l.commonBack,
          ),
          children: <Widget>[
            SectionHeader(l.dailySetupHeader),
            AppRow(
              icon: AppIcons.dailyRun,
              label: trackName(l, c.trackId),
              subtitle: vehicleName(l, VehicleCatalog.byId(c.vehicleId)!.kind),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
              child: Wrap(
                spacing: AppSpacing.s8,
                runSpacing: AppSpacing.s8,
                children: <Widget>[
                  AppChip(label: l.dailyLapsWind(c.laps, _wind(l, c))),
                  AppChip(
                    label: l.streakDays(streak),
                    tone: streak > 0 ? ChipTone.accent : ChipTone.neutral,
                  ),
                  AppChip(label: l.dailyAttempts(scope.daily.attemptsToday)),
                  if (done) AppChip(label: l.dailyDoneToday, icon: AppIcons.check, tone: ChipTone.accent),
                ],
              ),
            ),
            if (scope.daily.nextAttemptIsExtra)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.s16, AppSpacing.s8, AppSpacing.s16, 0),
                child: Text(
                  l.dailyExtraNote,
                  style: theme.type.footnote.copyWith(color: theme.colors.textSecondary),
                ),
              ),
            const SizedBox(height: AppSpacing.s16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
              child: PrimaryButton(
                label: done || extra ? l.dailyTryAgain : l.dailyStart,
                onPressed: () => unawaited(
                  Navigator.of(context).pushNamed(
                    Routes.trackIntro,
                    arguments: TrackIntroArgs(mode: RaceMode.dailyRun, trackId: c.trackId),
                  ),
                ),
              ),
            ),
            SectionHeader(l.dailyVerseHeader),
            VerseBlock(
              load: () => scope.verses.pick(VerseMoment.daily, seed: c.verseSeed),
              onShare: widget.onShare,
            ),
            SectionHeader(l.settingsReminders),
            AppRow(
              icon: AppIcons.reminderOn,
              label: l.settingsReminders,
              trailing: AppSwitch(
                value: scope.settings.value.remindersEnabled,
                semanticLabel: l.settingsReminders,
                onChanged: (bool v) => unawaited(_setReminder(scope, l, v)),
              ),
            ),
            if (_note != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.s16, AppSpacing.s8, AppSpacing.s16, 0),
                child: Semantics(
                  liveRegion: true,
                  child: Text(_note!, style: theme.type.body.copyWith(color: theme.colors.textPrimary)),
                ),
              ),
          ],
        );
      },
    );
  }
}
