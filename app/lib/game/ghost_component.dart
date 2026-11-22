import 'dart:ui';

import 'package:flame/components.dart';
import 'package:ruach/core/logic/ghost.dart';
import 'package:ruach/core/logic/race_rules.dart';
import 'package:ruach/core/models/vec2.dart';
import 'package:ruach/game/vehicle_component.dart';
import 'package:ruach/providers/race_provider.dart';
import 'package:ruach/theme/tokens.dart';

/// The Time Trial ghost: the player's best lap, replayed as a faint car that
/// keeps lapping. It is drawn from the saved position log and takes no part
/// in the race: no contact, no effect on the result.
final class GhostComponent extends Component {
  GhostComponent({required this.race});

  final RaceProvider race;

  /// Where the ghost is now, or null when there is nothing to show.
  ({double x, double y, double heading})? get currentPose {
    final GhostLap? lap = race.ghost;
    final RaceSimulation? sim = race.simulation;
    if (lap == null || sim == null || sim.phase == RacePhase.countdown) return null;
    final double t = sim.elapsedSeconds;
    final Vec2 pos = lap.positionAt(t);
    return (x: pos.x, y: pos.y, heading: lap.headingAt(t));
  }

  @override
  void render(Canvas canvas) {
    final ({double x, double y, double heading})? pose = currentPose;
    final RaceSimulation? sim = race.simulation;
    if (pose == null || sim == null) return;
    canvas.saveLayer(null, Paint()..color = const Color(0x80FFFFFF));
    canvas.translate(pose.x, pose.y);
    canvas.rotate(pose.heading);
    VehicleArt.paint(canvas, sim.player.vehicle.kind, WorldColors.line);
    canvas.restore();
  }
}
