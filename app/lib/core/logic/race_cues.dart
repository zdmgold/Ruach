import 'package:ruach/core/logic/race_rules.dart';

/// A sound-and-touch moment during a race.
enum RaceCue { countdownTick, go, boost, contact, lap, finishWin, finishPodium, finishOther }

/// Watches a race simulation between steps and reports the moments worth a
/// sound. Pure: it only reads the simulation, so it is tested without audio.
final class RaceCueDetector {
  int? _lastCountdown;
  bool _started = false;
  bool _wasBoosting = false;
  int? _lastContact;
  int _laps = 0;
  bool _finished = false;

  /// Cues that happened since the last call, in order.
  List<RaceCue> poll(RaceSimulation sim) {
    final List<RaceCue> cues = <RaceCue>[];
    final RaceCar me = sim.player;
    if (sim.phase == RacePhase.countdown) {
      final int second = sim.countdownSeconds.ceil();
      if (second > 0 && second != _lastCountdown) {
        _lastCountdown = second;
        cues.add(RaceCue.countdownTick);
      }
    } else if (!_started) {
      _started = true;
      cues.add(RaceCue.go);
    }
    if (me.boosting && !_wasBoosting) cues.add(RaceCue.boost);
    _wasBoosting = me.boosting;
    final int? contact = me.lastContactTick;
    if (contact != null && contact != _lastContact) {
      _lastContact = contact;
      cues.add(RaceCue.contact);
    }
    final int laps = me.tracker.lapTimes.length;
    if (laps > _laps) {
      _laps = laps;
      if (!me.finished) cues.add(RaceCue.lap);
    }
    if (me.finished && !_finished) {
      _finished = true;
      cues.add(
        me.position == 1
            ? RaceCue.finishWin
            : (me.position <= 3 ? RaceCue.finishPodium : RaceCue.finishOther),
      );
    }
    return cues;
  }
}
