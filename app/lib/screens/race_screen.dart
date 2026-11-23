import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:ruach/app_scope.dart';
import 'package:ruach/core/logic/input_strategy.dart';
import 'package:ruach/core/models/settings.dart';
import 'package:ruach/game/hud_layer.dart';
import 'package:ruach/game/input_layer.dart';
import 'package:ruach/game/race_game.dart';
import 'package:ruach/l10n/app_localizations.dart';
import 'package:ruach/providers/race_provider.dart';
import 'package:ruach/screens/routes.dart';
import 'package:ruach/theme/app_theme.dart';
import 'package:ruach/theme/tokens.dart';
import 'package:ruach/widgets/app_row.dart';
import 'package:ruach/widgets/primary_button.dart';

/// The race: the game view with the HUD and the controls over it. Leaving the
/// app pauses the race. There are no ads and no verses during a race.
class RaceScreen extends StatefulWidget {
  const RaceScreen({
    required this.args,
    super.key,
    this.tilt,
    this.tiltAvailable = true,
  });

  final RaceArgs args;

  /// Roll angle stream for tilt steering, from the app shell.
  final Stream<double>? tilt;
  final bool tiltAvailable;

  @override
  State<RaceScreen> createState() => _RaceScreenState();
}

class _RaceScreenState extends State<RaceScreen> with WidgetsBindingObserver {
  late final InputController _controller;
  RaceGame? _game;
  RaceProvider? _race;
  bool _confirmQuit = false;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_game != null) return;
    final AppScope scope = AppScope.of(context);
    final RaceProvider race = scope.race;
    _race = race;
    _controller = InputController(InputStrategies.create(scope.settings.value));
    _begin(race);
    _game = RaceGame(
      race: race,
      readInput: _controller.read,
      reduceMotion: MediaQuery.disableAnimationsOf(context),
    );
    race.addListener(_onRace);
  }

  void _begin(RaceProvider race) {
    _controller.reset();
    race.start(
      widget.args.config,
      wind: widget.args.wind,
      startingBoost: widget.args.startingBoost,
    );
  }

  void _onRace() {
    final RaceProvider? race = _race;
    if (race == null || _left || race.stage != RaceStage.finished) return;
    _left = true;
    unawaited(Navigator.of(context).pushReplacementNamed(Routes.result));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _controller.reset();
      _race?.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _race?.removeListener(_onRace);
    super.dispose();
  }

  void _resume() {
    _controller.reset();
    setState(() => _confirmQuit = false);
    _race?.resume();
  }

  void _restart() {
    final RaceProvider? race = _race;
    if (race == null) return;
    setState(() => _confirmQuit = false);
    _begin(race);
  }

  void _quit() {
    _left = true;
    _race?.abandon();
    unawaited(Navigator.of(context).maybePop());
  }

  @override
  Widget build(BuildContext context) {
    final AppScope scope = AppScope.of(context);
    final AppLocalizations l = AppLocalizations.of(context);
    final RaceProvider race = scope.race;
    final Settings settings = scope.settings.value;
    final RaceGame game = _game!;
    return Stack(
      children: <Widget>[
        Positioned.fill(child: GameWidget<RaceGame>(game: game)),
        Positioned.fill(
          child: HudLayer(
            race: race,
            onPause: race.pause,
            labels: HudLabels(
              position: l.hudPosition,
              lap: l.hudLap,
              boost: l.hudBoost,
              boostValue: l.hudBoostValue,
              go: l.hudGo,
              escapeDistance: l.hudEscapeDistance,
              pause: l.hudPause,
              minimap: l.hudMinimap,
              positionSemantic: l.hudPositionSemantic,
              lapSemantic: l.hudLapSemantic,
              timeSemantic: l.hudTimeSemantic,
            ),
          ),
        ),
        Positioned.fill(
          child: InputLayer(
            controller: _controller,
            settings: settings,
            tilt: widget.tilt,
            tiltAvailable: widget.tiltAvailable,
            labels: InputLabels(
              steerLeft: l.inputSteerLeft,
              steerRight: l.inputSteerRight,
              brake: l.inputBrake,
              boost: l.inputBoost,
              tiltFallback: l.inputTiltFallback,
            ),
          ),
        ),
        ListenableBuilder(
          listenable: race,
          builder: (BuildContext context, Widget? _) {
            if (race.stage != RaceStage.paused) return const SizedBox.shrink();
            return Positioned.fill(
              child: _PauseMenu(
                confirmQuit: _confirmQuit,
                onResume: _resume,
                onRestart: _restart,
                onQuit: () => setState(() => _confirmQuit = true),
                onConfirmQuit: _quit,
                onCancelQuit: () => setState(() => _confirmQuit = false),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PauseMenu extends StatelessWidget {
  const _PauseMenu({
    required this.confirmQuit,
    required this.onResume,
    required this.onRestart,
    required this.onQuit,
    required this.onConfirmQuit,
    required this.onCancelQuit,
  });

  final bool confirmQuit;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onQuit;
  final VoidCallback onConfirmQuit;
  final VoidCallback onCancelQuit;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final AppThemeData theme = AppTheme.of(context);
    return ColoredBox(
      color: theme.colors.bgPrimary.withValues(alpha: 0.88),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: Semantics(
              container: true,
              scopesRoute: true,
              explicitChildNodes: true,
              label: l.pauseTitle,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: confirmQuit
                    ? <Widget>[
                        Text(
                          l.pauseQuitConfirm,
                          textAlign: TextAlign.center,
                          style: theme.type.body.copyWith(color: theme.colors.textPrimary),
                        ),
                        const SizedBox(height: AppSpacing.s16),
                        PrimaryButton(label: l.pauseQuit, onPressed: onConfirmQuit),
                        AppRow(label: l.commonBack, onTap: onCancelQuit),
                      ]
                    : <Widget>[
                        Text(
                          l.pauseTitle,
                          textAlign: TextAlign.center,
                          style: theme.type.title2.copyWith(color: theme.colors.textPrimary),
                        ),
                        const SizedBox(height: AppSpacing.s16),
                        PrimaryButton(label: l.pauseResume, onPressed: onResume),
                        AppRow(label: l.pauseRestart, onTap: onRestart),
                        AppRow(label: l.pauseQuit, onTap: onQuit),
                      ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
