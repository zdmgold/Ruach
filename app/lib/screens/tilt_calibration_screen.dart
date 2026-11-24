import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:ruach/app_scope.dart';
import 'package:ruach/core/logic/input_strategy.dart';
import 'package:ruach/core/models/settings.dart';
import 'package:ruach/l10n/app_localizations.dart';
import 'package:ruach/theme/app_theme.dart';
import 'package:ruach/theme/tokens.dart';
import 'package:ruach/widgets/app_slider.dart';
import 'package:ruach/widgets/nav_bar.dart';
import 'package:ruach/widgets/primary_button.dart';
import 'package:ruach/widgets/screen_frame.dart';

/// Tilt setup: hold the phone the way you play and set that as level, tune
/// the sensitivity, and watch a live bar that shows the steering the race
/// will get. With no tilt sensor the screen says so and changes nothing.
class TiltCalibrationScreen extends StatefulWidget {
  const TiltCalibrationScreen({super.key, this.tilt, this.tiltAvailable = true});

  /// Roll angle in radians from the app shell's sensor, or null.
  final Stream<double>? tilt;
  final bool tiltAvailable;

  @override
  State<TiltCalibrationScreen> createState() => _TiltCalibrationScreenState();
}

class _TiltCalibrationScreenState extends State<TiltCalibrationScreen> {
  StreamSubscription<double>? _sub;
  double _roll = 0;

  bool get _usable => widget.tiltAvailable && widget.tilt != null;

  @override
  void initState() {
    super.initState();
    _sub = widget.tilt?.listen((double r) {
      if (mounted) setState(() => _roll = r);
    });
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppScope scope = AppScope.of(context);
    final AppLocalizations l = AppLocalizations.of(context);
    final AppThemeData theme = AppTheme.of(context);
    return ListenableBuilder(
      listenable: scope.settings,
      builder: (BuildContext context, Widget? _) {
        final Settings s = scope.settings.value;
        final double steer = TiltStrategy.steerFor(_roll, s.tiltCalibration, s.tiltSensitivity);
        final int percent = (steer * 100).round();
        return ScreenFrame(
          navBar: NavBar(
            title: l.tiltTitle,
            onBack: () => unawaited(Navigator.of(context).maybePop()),
            backLabel: l.commonBack,
          ),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    _usable ? l.tiltLead : l.tiltUnavailable,
                    style: theme.type.body.copyWith(color: theme.colors.textPrimary),
                  ),
                  if (_usable) ...<Widget>[
                    const SizedBox(height: AppSpacing.s24),
                    PrimaryButton(
                      label: l.tiltSetLevel,
                      onPressed: () => unawaited(
                        scope.settings.update((Settings v) => v.copyWith(tiltCalibration: _roll)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s24),
                    Text(
                      l.tiltSensitivity,
                      style: theme.type.footnote.copyWith(color: theme.colors.textSecondary),
                    ),
                    AppSlider(
                      value: s.tiltSensitivity,
                      min: Settings.minTiltSensitivity,
                      max: Settings.maxTiltSensitivity,
                      divisions: 35,
                      semanticLabel: l.tiltSensitivity,
                      valueLabel: l.settingsPercent((s.tiltSensitivity * 100).round()),
                      onChanged: (double v) =>
                          unawaited(scope.settings.update((Settings x) => x.copyWith(tiltSensitivity: v))),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    Text(
                      l.tiltLive,
                      style: theme.type.footnote.copyWith(color: theme.colors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Semantics(
                      label: l.tiltLive,
                      value: l.tiltReading(percent),
                      child: ExcludeSemantics(child: _Gauge(steer: steer)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A bar with a centre mark; the fill grows left or right with the steering.
/// It never mirrors: left is left, as in the race.
class _Gauge extends StatelessWidget {
  const _Gauge({required this.steer});

  final double steer;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        height: 24,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints box) {
            final double half = box.maxWidth / 2;
            final double fill = half * steer.abs();
            return Stack(
              children: <Widget>[
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colors.bgTertiary,
                      borderRadius: BorderRadius.circular(AppRadii.chip),
                    ),
                  ),
                ),
                Positioned(
                  left: steer >= 0 ? half : half - fill,
                  width: fill,
                  top: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colors.accent,
                      borderRadius: BorderRadius.circular(AppRadii.chip),
                    ),
                  ),
                ),
                Positioned(
                  left: half - 1,
                  width: 2,
                  top: 0,
                  bottom: 0,
                  child: ColoredBox(color: theme.colors.textTertiary),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
