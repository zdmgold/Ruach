import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ruach/core/logic/mode_rules.dart';
import 'package:ruach/core/logic/race_rules.dart';
import 'package:ruach/core/logic/track_geometry.dart';
import 'package:ruach/core/models/track.dart';
import 'package:ruach/core/models/vec2.dart';
import 'package:ruach/game/vehicle_component.dart';
import 'package:ruach/providers/race_provider.dart';
import 'package:ruach/theme/app_icon.dart';
import 'package:ruach/theme/app_theme.dart';
import 'package:ruach/theme/icons.dart';
import 'package:ruach/theme/tokens.dart';
import 'package:ruach/utils/formatters.dart';
import 'package:ruach/widgets/boost_meter.dart';
import 'package:ruach/widgets/pressable.dart';

/// Every word the race HUD shows or speaks. The shell fills it from the
/// language files; the HUD holds no literal text.
final class HudLabels {
  const HudLabels({
    required this.position,
    required this.lap,
    required this.boost,
    required this.boostValue,
    required this.go,
    required this.escapeDistance,
    required this.pause,
    required this.minimap,
    required this.positionSemantic,
    required this.lapSemantic,
    required this.timeSemantic,
  });

  /// "3/6".
  final String Function(int position, int field) position;

  /// "2/3".
  final String Function(int lap, int laps) lap;

  /// The visible name of the boost meter.
  final String boost;

  /// "2 of 3 segments".
  final String Function(int segments, int total) boostValue;

  /// Shown for a moment when the race starts.
  final String go;

  /// "1,240 m".
  final String Function(int metres) escapeDistance;

  /// Spoken label of the pause button.
  final String pause;

  /// Spoken label of the minimap.
  final String minimap;

  /// "Position 3 of 6".
  final String Function(int position, int field) positionSemantic;

  /// "Lap 2 of 3".
  final String Function(int lap, int laps) lapSemantic;

  /// "Time 01:02.33".
  final String Function(String time) timeSemantic;
}

/// The overlay drawn over the race: position, lap, time, boost, minimap,
/// the Escape Run distance and danger bar, the countdown, and the pause
/// button. It is plain Flutter, so every language and right-to-left layout
/// works, and it caps its own text scale at 120% so it never covers the track.
class HudLayer extends StatelessWidget {
  const HudLayer({
    required this.race,
    required this.labels,
    required this.onPause,
    super.key,
  });

  final RaceProvider race;
  final HudLabels labels;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: ListenableBuilder(
        listenable: race,
        builder: (BuildContext context, Widget? child) {
          final RaceSimulation? sim = race.simulation;
          if (sim == null) return const SizedBox.shrink();
          return _Hud(race: race, sim: sim, labels: labels, onPause: onPause);
        },
      ),
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({required this.race, required this.sim, required this.labels, required this.onPause});

  final RaceProvider race;
  final RaceSimulation sim;
  final HudLabels labels;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final RaceCar player = sim.player;
    final int field = sim.cars.length;
    final int laps = sim.config.laps;
    final int lap = (player.tracker.lap + 1).clamp(1, laps).toInt();
    final double top = MediaQuery.maybePaddingOf(context)?.top ?? 0;
    final String time = formatLapTime(Duration(milliseconds: (sim.elapsedSeconds * 1000).round()));
    final EscapeRun? escape = race.escape;
    final bool counting = sim.phase == RacePhase.countdown;
    final bool showGo = sim.phase == RacePhase.racing && sim.raceTick < 45;

    return Stack(
      children: <Widget>[
        // Left (start) column: position, lap and time, then the boost meter
        // and, in an Escape Run, the distance and danger bar.
        PositionedDirectional(
          top: top + AppSpacing.s8,
          start: AppSpacing.s16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Semantics(
                      label: labels.positionSemantic(player.position, field),
                      excludeSemantics: true,
                      child: Text(labels.position(player.position, field), style: theme.type.display),
                    ),
                    Semantics(
                      label: labels.lapSemantic(lap, laps),
                      excludeSemantics: true,
                      child: Text(labels.lap(lap, laps), style: theme.type.callout),
                    ),
                    Semantics(
                      label: labels.timeSemantic(time),
                      excludeSemantics: true,
                      child: Text(
                        time,
                        style: theme.type.callout.copyWith(
                          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              _Panel(
                child: BoostMeter(
                  fill: player.meter.fill,
                  label: labels.boost,
                  semanticValue: labels.boostValue(player.meter.fullSegments, 3),
                ),
              ),
              if (escape != null && !counting) ...<Widget>[
                const SizedBox(height: AppSpacing.s8),
                _Panel(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(labels.escapeDistance(race.escapeMetres.floor()), style: theme.type.callout),
                      const SizedBox(height: AppSpacing.s4),
                      _DangerBar(danger: escape.danger),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        // Right (end) column: the minimap, with the pause button under it.
        PositionedDirectional(
          top: top + AppSpacing.s8,
          end: AppSpacing.s16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Semantics(
                label: labels.minimap,
                excludeSemantics: true,
                child: _Minimap(race: race, sim: sim),
              ),
              const SizedBox(height: AppSpacing.s8),
              Pressable(
                onTap: onPause,
                semanticLabel: labels.pause,
                builder: (BuildContext context, bool pressed) => _Panel(
                  child: AppIcon(AppIcons.pause, size: AppIconSizes.navBar, color: theme.colors.textPrimary),
                ),
              ),
            ],
          ),
        ),
        if (counting || showGo)
          IgnorePointer(
            child: Center(
              child: Text(
                counting ? '${sim.countdownSeconds.ceil()}' : labels.go,
                style: theme.type.display.copyWith(fontSize: 96, color: theme.colors.textPrimary),
              ),
            ),
          ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.bgSecondary.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(AppRadii.chip),
        border: Border.all(color: theme.colors.border, width: AppStroke.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: AppSpacing.s4),
        child: child,
      ),
    );
  }
}

class _DangerBar extends StatelessWidget {
  const _DangerBar({required this.danger});

  final double danger;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.bgTertiary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: SizedBox(
        width: 120,
        height: 8,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: FractionallySizedBox(
            widthFactor: danger.clamp(0, 1).toDouble(),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colors.error,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const SizedBox(height: 8),
            ),
          ),
        ),
      ),
    );
  }
}

/// A fixed-size outline of the track with a dot for every car. It never
/// mirrors, whatever the language.
class _Minimap extends StatefulWidget {
  const _Minimap({required this.race, required this.sim});

  final RaceProvider race;
  final RaceSimulation sim;

  @override
  State<_Minimap> createState() => _MinimapState();
}

class _MinimapState extends State<_Minimap> {
  late MinimapData _data = MinimapData.of(widget.sim.config.track);

  @override
  void didUpdateWidget(_Minimap old) {
    super.didUpdateWidget(old);
    if (old.sim.config.track != widget.sim.config.track) {
      _data = MinimapData.of(widget.sim.config.track);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.bgSecondary.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(AppRadii.chip),
        border: Border.all(color: theme.colors.border, width: AppStroke.hairline),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: CustomPaint(
          size: const Size.square(MinimapData.side),
          painter: _MinimapPainter(
            data: _data,
            sim: widget.sim,
            line: theme.colors.textTertiary,
            player: theme.colors.accent,
            repaint: widget.race,
          ),
        ),
      ),
    );
  }
}

/// The track outline scaled into a square, computed once per track.
final class MinimapData {
  MinimapData._(this.outline, this._min, this._scale, this._offset);

  static const double side = 76;
  static const double padding = 8;

  /// The outline in minimap pixels.
  final List<Offset> outline;
  final Vec2 _min;
  final double _scale;
  final Offset _offset;

  factory MinimapData.of(Track track) {
    final TrackGeometry g = TrackGeometry.of(track);
    const int n = 72;
    final List<Vec2> pts = <Vec2>[for (int i = 0; i < n; i++) g.positionAt(g.length * i / n)];
    double minX = pts.first.x;
    double maxX = pts.first.x;
    double minY = pts.first.y;
    double maxY = pts.first.y;
    for (final Vec2 p in pts) {
      minX = math.min(minX, p.x);
      maxX = math.max(maxX, p.x);
      minY = math.min(minY, p.y);
      maxY = math.max(maxY, p.y);
    }
    final double w = math.max(1, maxX - minX);
    final double h = math.max(1, maxY - minY);
    final double scale = (side - 2 * padding) / math.max(w, h);
    final Offset offset = Offset((side - w * scale) / 2, (side - h * scale) / 2);
    final MinimapData probe = MinimapData._(const <Offset>[], Vec2(minX, minY), scale, offset);
    return MinimapData._(<Offset>[for (final Vec2 p in pts) probe.project(p)], Vec2(minX, minY), scale, offset);
  }

  /// Where a world point lands on the minimap.
  Offset project(Vec2 p) => Offset((p.x - _min.x) * _scale + _offset.dx, (p.y - _min.y) * _scale + _offset.dy);
}

class _MinimapPainter extends CustomPainter {
  _MinimapPainter({
    required this.data,
    required this.sim,
    required this.line,
    required this.player,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final MinimapData data;
  final RaceSimulation sim;
  final Color line;
  final Color player;

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path()..addPolygon(data.outline, true);
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
    for (final RaceCar car in sim.cars) {
      if (car.isPlayer || car.eliminated) continue;
      canvas.drawCircle(
        data.project(car.state.position),
        2.5,
        Paint()..color = VehicleArt.teamColor(car.rival?.team ?? car.id),
      );
    }
    canvas.drawCircle(data.project(sim.player.state.position), 4, Paint()..color = player);
  }

  @override
  bool shouldRepaint(_MinimapPainter old) => old.sim != sim || old.data != data;
}
