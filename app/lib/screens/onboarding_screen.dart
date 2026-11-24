import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:ruach/app_scope.dart';
import 'package:ruach/core/logic/catalog_ids.dart';
import 'package:ruach/core/models/race_config.dart';
import 'package:ruach/core/models/settings.dart';
import 'package:ruach/l10n/app_localizations.dart';
import 'package:ruach/screens/routes.dart';
import 'package:ruach/theme/app_icon.dart';
import 'package:ruach/theme/app_theme.dart';
import 'package:ruach/theme/icons.dart';
import 'package:ruach/theme/tokens.dart';
import 'package:ruach/widgets/app_row.dart';
import 'package:ruach/widgets/primary_button.dart';

/// First run: a welcome, a choice of controls, and the first race. Skipping
/// goes to Home; either way the screen is not shown again.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.tiltAvailable = true});

  final bool tiltAvailable;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  ControlScheme _scheme = ControlScheme.buttons;

  Future<void> _finish(AppScope scope, {required bool race}) async {
    final NavigatorState nav = Navigator.of(context);
    await scope.settings.update(
      (Settings s) => s.copyWith(controlScheme: _scheme, onboardingDone: true),
    );
    if (!mounted) return;
    unawaited(
      race
          ? nav.pushReplacementNamed(
              Routes.trackIntro,
              arguments: TrackIntroArgs(mode: RaceMode.journey, trackId: TrackIds.journey.first),
            )
          : nav.pushReplacementNamed(Routes.home),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppScope scope = AppScope.of(context);
    final AppLocalizations l = AppLocalizations.of(context);
    final AppThemeData theme = AppTheme.of(context);
    final double bottom = MediaQuery.paddingOf(context).bottom;
    Widget choice(ControlScheme scheme, String label, String blurb, {bool enabled = true}) {
      final bool selected = _scheme == scheme;
      return Semantics(
        selected: selected,
        inMutuallyExclusiveGroup: true,
        child: AppRow(
          label: label,
          subtitle: enabled ? blurb : l.tiltUnavailable,
          trailing: selected ? const AppIcon(AppIcons.check) : null,
          onTap: enabled ? () => setState(() => _scheme = scheme) : null,
        ),
      );
    }

    return ColoredBox(
      color: theme.colors.bgPrimary,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top, bottom: bottom + AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Semantics(
                    header: true,
                    child: Text(
                      l.onboardWelcome,
                      style: theme.type.display.copyWith(color: theme.colors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  Text(l.onboardLead, style: theme.type.body.copyWith(color: theme.colors.textSecondary)),
                ],
              ),
            ),
            choice(ControlScheme.buttons, l.controlButtons, l.onboardButtonsBlurb),
            choice(ControlScheme.dragSteer, l.controlDrag, l.onboardDragBlurb),
            choice(ControlScheme.tilt, l.controlTilt, l.onboardTiltBlurb, enabled: widget.tiltAvailable),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s24),
              child: PrimaryButton(
                label: l.onboardStart,
                onPressed: () => unawaited(_finish(scope, race: true)),
              ),
            ),
            AppRow(label: l.onboardSkip, onTap: () => unawaited(_finish(scope, race: false))),
          ],
        ),
      ),
    );
  }
}
