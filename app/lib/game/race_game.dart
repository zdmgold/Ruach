import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:ruach/core/logic/race_rules.dart';
import 'package:ruach/core/models/drive_input.dart';
import 'package:ruach/game/camera_rig.dart';
import 'package:ruach/game/effects.dart';
import 'package:ruach/game/ghost_component.dart';
import 'package:ruach/game/track_renderer.dart';
import 'package:ruach/game/vehicle_component.dart';
import 'package:ruach/providers/race_provider.dart';
import 'package:ruach/theme/tokens.dart';

/// The Flame game that hosts the race. It owns no rules: every frame it asks
/// the input for a [DriveInput], hands the frame time to the race provider
/// (which steps the simulation at a fixed 60 Hz) and draws what the
/// simulation holds. Menus, HUD and verse cards are ordinary Flutter widgets
/// around it.
final class RaceGame extends FlameGame {
  RaceGame({
    required this.race,
    required this.readInput,
    this.reduceMotion = false,
  });

  final RaceProvider race;

  /// The current input for this frame; the argument is the frame time in
  /// seconds.
  final DriveInput Function(double dt) readInput;

  /// True when the player asked for Reduce Motion: effects that shake or
  /// flash stay off.
  final bool reduceMotion;

  late final RaceView view;

  @override
  Color backgroundColor() => WorldColors.groundGrass;

  @override
  Future<void> onLoad() async {
    view = RaceView(this);
    await add(view);
  }

  @override
  void update(double dt) {
    if (race.isRunning) race.advance(dt, readInput(dt));
    super.update(dt);
  }
}

/// The drawn race: track, cars and the camera that follows the player. It
/// rebuilds itself whenever the provider starts a new race.
final class RaceView extends Component {
  RaceView(this.game);

  final RaceGame game;
  final CameraRig rig = CameraRig();

  RaceSimulation? _sim;
  TrackRenderer? _renderer;

  /// The renderer for the current race, or null before one starts.
  TrackRenderer? get renderer => _renderer;

  /// How many cars are drawn.
  int get vehicleCount => children.whereType<VehicleComponent>().length;

  @override
  void update(double dt) {
    super.update(dt);
    final RaceSimulation? sim = game.race.simulation;
    if (sim == null) return;
    if (!identical(sim, _sim)) _rebuild(sim);
    final RaceCar player = sim.player;
    rig.update(
      dt,
      position: player.state.position,
      heading: player.state.heading,
      speed: player.state.speed,
      viewportWidth: game.canvasSize.x,
    );
  }

  void _rebuild(RaceSimulation sim) {
    _sim = sim;
    _renderer?.dispose();
    _renderer = TrackRenderer(sim.config.track);
    removeAll(children.toList());
    // Back to front: wall, effects, ghost, rivals, then the player on top.
    add(PursuitWall(race: game.race, reduceMotion: game.reduceMotion));
    add(EffectsLayer(race: game.race, reduceMotion: game.reduceMotion));
    add(GhostComponent(race: game.race));
    for (final RaceCar car in sim.cars.reversed) {
      add(
        VehicleComponent(
          car: car,
          color: car.isPlayer ? WorldColors.playerCar : VehicleArt.teamColor(car.rival?.team ?? car.id),
        ),
      );
    }
    rig.snapTo(
      position: sim.player.state.position,
      heading: sim.player.state.heading,
      viewportWidth: game.canvasSize.x,
    );
  }

  @override
  void renderTree(Canvas canvas) {
    final TrackRenderer? track = _renderer;
    if (track == null) return;
    final Vector2 size = game.canvasSize;
    canvas.save();
    canvas.clipRect(Offset.zero & Size(size.x, size.y));
    canvas.translate(size.x / 2, size.y * rig.anchorY);
    canvas.scale(rig.zoom);
    canvas.rotate(rig.rotation);
    canvas.translate(-rig.center.x, -rig.center.y);
    track.paint(canvas);
    super.renderTree(canvas);
    canvas.restore();
  }

  @override
  void onRemove() {
    _renderer?.dispose();
    _renderer = null;
    super.onRemove();
  }
}
