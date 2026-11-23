import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:ruach/core/logic/ai_driver.dart';
import 'package:ruach/core/logic/car_physics.dart';
import 'package:ruach/core/logic/ghost.dart';
import 'package:ruach/core/logic/mode_rules.dart';
import 'package:ruach/core/logic/race_rules.dart';
import 'package:ruach/core/logic/star_rules.dart';
import 'package:ruach/core/logic/upgrade_rules.dart';
import 'package:ruach/core/models/drive_input.dart';
import 'package:ruach/core/models/progress.dart';
import 'package:ruach/core/models/race_config.dart';
import 'package:ruach/core/models/race_result.dart';
import 'package:ruach/core/models/vec2.dart';
import 'package:ruach/providers/progress_provider.dart';

enum RaceStage { idle, running, paused, finished }

/// Which race of the Weekly Circuit a race is: the ISO week (for example
/// `2026-W47`) and the day index 0 to 6, Monday first.
final class WeeklySlot {
  const WeeklySlot(this.weekId, this.index);

  final String weekId;
  final int index;
}

/// Runs one race at a time: owns the simulation, steps it at a fixed 60 Hz
/// from the frame time the game loop gives it, applies the mode rule, and on
/// finish builds the result and records it in the saved game.
final class RaceProvider extends ChangeNotifier {
  RaceProvider(this._progress);

  /// The most steps one call to [advance] runs, so a long pause between
  /// frames cannot freeze the game catching up.
  static const int maxStepsPerAdvance = 8;

  final ProgressProvider _progress;

  RaceSimulation? _sim;
  EliminationRule? _elimination;
  EscapeRun? _escape;
  RaceStage _stage = RaceStage.idle;
  RaceResult? _result;
  double _accumulator = 0;
  double _escapeMetres = 0;
  bool _committed = false;
  int _giftsGained = 0;
  WeeklySlot? _weekly;

  // Time Trial ghost: the saved best lap to race against, and the lap being
  // recorded now.
  GhostLap? _ghost;
  final GhostRecorder _recorder = GhostRecorder();
  int _lapStartTick = 0;
  int _lapsSeen = 0;
  int? _bestGhostMillis;
  String? _bestGhostText;

  /// The saved best lap to show as a ghost car, or null.
  GhostLap? get ghost => _ghost;

  /// The Weekly Circuit race being run, or null for any other race.
  WeeklySlot? get weekly => _weekly;

  RaceSimulation? get simulation => _sim;
  RaceStage get stage => _stage;
  RaceResult? get result => _result;
  EscapeRun? get escape => _escape;

  /// Metres covered so far in an Escape Run.
  double get escapeMetres => _escapeMetres;

  /// Gifts gained by the last committed result.
  int get giftsGained => _giftsGained;

  bool get isRunning => _stage == RaceStage.running;

  /// Begins [config]. Any race in progress is dropped.
  void start(
    RaceConfig config, {
    Vec2 wind = Vec2.zero,
    double startingBoost = 0,
    WeeklySlot? weekly,
  }) {
    _weekly = weekly;
    final CarTuning tuning = UpgradeRules.tuningFor(config.upgrades);
    _sim = RaceSimulation(
      config: config,
      controllers: AiDriver.forRace(config),
      playerTuning: tuning,
      wind: wind,
      startingBoost: startingBoost,
    );
    _elimination = config.mode == RaceMode.elimination ? EliminationRule() : null;
    _escape = config.mode == RaceMode.escapeRun ? EscapeRun() : null;
    _stage = RaceStage.running;
    _result = null;
    _accumulator = 0;
    _escapeMetres = 0;
    _committed = false;
    _giftsGained = 0;
    _recorder.startLap();
    _lapStartTick = 0;
    _lapsSeen = 0;
    _bestGhostMillis = null;
    _bestGhostText = null;
    final String? saved = config.mode == RaceMode.timeTrial ? _progress.value.ghosts[config.track.id] : null;
    _ghost = saved == null ? null : GhostCodec.decode(saved);
    notifyListeners();
  }

  void pause() {
    if (_stage != RaceStage.running) return;
    _stage = RaceStage.paused;
    notifyListeners();
  }

  void resume() {
    if (_stage != RaceStage.paused) return;
    _stage = RaceStage.running;
    notifyListeners();
  }

  /// Leaves the race without a result.
  void abandon() {
    _sim = null;
    _elimination = null;
    _escape = null;
    _result = null;
    _stage = RaceStage.idle;
    notifyListeners();
  }

  /// Advances by [seconds] of real time with the player's [input].
  void advance(double seconds, DriveInput input) {
    final RaceSimulation? sim = _sim;
    if (sim == null || _stage != RaceStage.running) return;
    _accumulator += math.max(0, seconds);
    int steps = 0;
    while (_accumulator >= RaceSimulation.dt && steps < maxStepsPerAdvance) {
      _accumulator -= RaceSimulation.dt;
      steps++;
      sim.step(input);
      if (sim.config.mode == RaceMode.timeTrial && sim.phase == RacePhase.racing) _recordGhost(sim);
      if (sim.phase == RacePhase.racing || sim.phase == RacePhase.finished) {
        _elimination?.update(sim);
        final EscapeRun? escape = _escape;
        if (escape != null && sim.phase == RacePhase.racing) {
          _escapeMetres += math.max(0, sim.player.state.forwardSpeed) * RaceSimulation.dt;
          escape.apply(sim);
        }
      }
      if (sim.phase == RacePhase.finished) {
        _finish(sim);
        break;
      }
    }
    // Drop time the cap could not use, so the game does not run fast later.
    if (steps == maxStepsPerAdvance) _accumulator = 0;
    notifyListeners();
  }

  void _recordGhost(RaceSimulation sim) {
    final RaceCar player = sim.player;
    final List<double> laps = player.tracker.lapTimes;
    if (laps.length > _lapsSeen) {
      _lapsSeen = laps.length;
      final double seconds = laps.last;
      final int millis = (seconds * 1000).round();
      final GhostLap? lap = _recorder.finish(seconds);
      if (lap != null && (_bestGhostMillis == null || millis < _bestGhostMillis!)) {
        _bestGhostMillis = millis;
        _bestGhostText = GhostCodec.encode(lap);
      }
      _recorder.startLap();
      _lapStartTick = sim.raceTick;
    }
    _recorder.sample(sim.raceTick - _lapStartTick, player.state.position, player.state.heading);
  }

  void _finish(RaceSimulation sim) {
    final RaceConfig config = sim.config;
    final RaceResult draft = sim.toResult();
    final RacerStanding me = draft.standings.firstWhere((RacerStanding s) => s.isPlayer);
    final int stars = switch (config.mode) {
      RaceMode.timeTrial => StarRules.forTimeTrial(
          me.bestLap == null ? 0 : me.bestLap!.inMicroseconds / 1e6,
          config.track.parLapSeconds,
        ),
      RaceMode.escapeRun => StarRules.forEscape(_escapeMetres),
      _ => StarRules.forPosition(me.position, finished: me.finished),
    };
    _result = sim.toResult(stars: stars);
    _stage = RaceStage.finished;
  }

  /// Saves the finished race: stars (and Gifts), best lap and best Escape Run
  /// distance. Does nothing twice. Returns the Gifts gained.
  Future<int> commit() async {
    final RaceResult? result = _result;
    final RaceSimulation? sim = _sim;
    if (result == null || sim == null || _committed) return _giftsGained;
    _committed = true;
    final RaceConfig config = sim.config;
    final String key = StarRules.starKey(config.mode, config.track.id);
    _giftsGained = await _progress.awardStars(key, result.stars);
    final RacerStanding me = result.standings.firstWhere((RacerStanding s) => s.isPlayer);
    final Duration? lap = me.bestLap;
    final double metres = _escapeMetres;
    await _progress.change((Progress p) {
      Progress next = p;
      if (lap != null && config.mode != RaceMode.escapeRun) {
        final int ms = lap.inMilliseconds;
        final int? old = p.bestLapMillis[config.track.id];
        if (old == null || ms < old) {
          next = next.copyWith(
            bestLapMillis: <String, int>{...p.bestLapMillis, config.track.id: ms},
          );
        }
        final String? ghostText = _bestGhostText;
        final int? ghostMillis = _bestGhostMillis;
        if (config.mode == RaceMode.timeTrial &&
            ghostText != null &&
            ghostMillis != null &&
            (old == null || ghostMillis < old)) {
          next = next.copyWith(
            ghosts: <String, String>{...p.ghosts, config.track.id: ghostText},
          );
        }
      }
      final WeeklySlot? slot = _weekly;
      if (slot != null && me.finished) {
        final Map<String, int> times = p.weeklyCircuitWeek == slot.weekId
            ? p.weeklyCircuitMillis
            : const <String, int>{};
        final String entry = slot.index.toString();
        final int ms = me.totalTime.inMilliseconds;
        final int? old = times[entry];
        next = next.copyWith(
          weeklyCircuitWeek: slot.weekId,
          weeklyCircuitMillis: <String, int>{
            ...times,
            entry: old == null || ms < old ? ms : old,
          },
        );
      }
      if (config.mode == RaceMode.escapeRun && metres.floor() > p.escapeRunBestMetres) {
        next = next.copyWith(escapeRunBestMetres: metres.floor());
      }
      return next;
    });
    notifyListeners();
    return _giftsGained;
  }
}
