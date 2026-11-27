import 'package:ruach/core/logic/boost_meter.dart';
import 'package:ruach/core/logic/boost_pads.dart';
import 'package:ruach/core/logic/car_physics.dart';
import 'package:ruach/core/logic/drive_assist.dart';
import 'package:ruach/core/logic/lap_tracker.dart';
import 'package:ruach/core/logic/surface_model.dart';
import 'package:ruach/core/logic/track_geometry.dart';
import 'package:ruach/core/models/drive_input.dart';
import 'package:ruach/core/models/race_config.dart';
import 'package:ruach/core/models/race_result.dart';
import 'package:ruach/core/models/rival.dart';
import 'package:ruach/core/models/track.dart';
import 'package:ruach/core/models/vec2.dart';
import 'package:ruach/core/models/vehicle.dart';

/// Where a race is.
enum RacePhase { countdown, racing, finished }

/// Decides what a computer-driven car does each step. The rival AI
/// (`ai_driver.dart`) implements this; tests use simple ones.
abstract interface class CarController {
  DriveInput drive(RaceSimulation race, RaceCar car);
}

/// One car in a race, with everything the rules track about it. Fields are
/// public so the AI and the renderer can read them; only [RaceSimulation]
/// changes them.
final class RaceCar {
  RaceCar._({
    required this.index,
    required this.id,
    required this.isPlayer,
    required this.vehicle,
    required this.tuning,
    required this.state,
    required this.tracker,
    required this.meter,
    required this.projection,
    this.rival,
  });

  /// 0 for the player, 1 and up for rivals.
  final int index;
  final String id;
  final bool isPlayer;
  final Rival? rival;
  final Vehicle vehicle;
  final CarTuning tuning;
  final CarState state;
  final LapTracker tracker;
  final BoostMeter meter;

  /// Where the car is relative to the road, updated every step.
  TrackProjection projection;

  /// Seconds of boost left; the car is boosting while this is above zero.
  double boostSeconds = 0;

  /// True once a mode rule has dropped the car (Elimination).
  bool eliminated = false;

  /// Step number of the last contact with another car, or null.
  int? lastContactTick;

  /// Steps spent driving cleanly, and steps spent racing, for the
  /// clean-driving score.
  int cleanTicks = 0;
  int racingTicks = 0;

  /// 1 for the leader.
  int position = 1;

  bool get boosting => boostSeconds > 0;
  bool get finished => tracker.finished;

  /// Total race distance covered, used to rank cars.
  double get progress => tracker.totalDistance;
}

/// The pure race state machine: grid, countdown, start, laps, finish and
/// positions. It reads the player's [DriveInput] each step and asks each
/// rival's [CarController] for theirs, then advances every car one fixed step.
///
/// Nothing here reads a clock or draws a random number, so the same config,
/// controllers and inputs always give the same race.
final class RaceSimulation {
  RaceSimulation({
    required this.config,
    List<Vehicle>? rivalVehicles,
    this.controllers = const <CarController>[],
    CarTuning playerTuning = const CarTuning(),
    CarTuning rivalTuning = const CarTuning(),
    this.wind = Vec2.zero,
    double startingBoost = 0,
    this.assist,
    bool boostPads = false,
  })  : geometry = TrackGeometry.of(config.track),
        assert(
          rivalVehicles == null || rivalVehicles.length == config.rivals.length,
          'one vehicle per rival',
        ) {
    final List<Vehicle> vehicles = rivalVehicles ??
        List<Vehicle>.filled(config.rivals.length, config.vehicle);
    pads = boostPads ? BoostPads.forTrack(config.track, geometry) : const <BoostPad>[];
    final CarTuning shownPlayerTuning = assist == null ? playerTuning : assist!.stabilise(playerTuning);
    final int field = config.fieldSize;
    cars = <RaceCar>[];
    for (int i = 0; i < field; i++) {
      final bool isPlayer = i == 0;
      // Rivals take the front grid slots; the player starts at the back. Slots
      // are staggered 3.5 m apart and alternate sides.
      final int slot = isPlayer ? field - 1 : i - 1;
      final double back = 8.0 + 3.5 * slot;
      final double side = (slot.isEven ? -1.0 : 1.0) * 0.4;
      final double startDistance = geometry.length - back;
      final Vec2 tangent = geometry.tangentAt(startDistance);
      final double halfWidth = geometry.widthAt(startDistance) / 2;
      final Vec2 position = geometry.positionAt(startDistance) +
          tangent.perpendicular * (side * halfWidth);
      final CarState state = CarState(position: position, heading: tangent.angle);
      cars.add(
        RaceCar._(
          index: i,
          id: isPlayer ? 'player' : config.rivals[i - 1].id,
          isPlayer: isPlayer,
          rival: isPlayer ? null : config.rivals[i - 1],
          vehicle: isPlayer ? config.vehicle : vehicles[i - 1],
          tuning: isPlayer ? shownPlayerTuning : rivalTuning,
          state: state,
          tracker: LapTracker(
            trackLength: geometry.length,
            checkpointFractions: config.track.checkpointFractions,
            laps: config.laps,
            startBehindLine: back,
          ),
          meter: BoostMeter(initial: isPlayer ? startingBoost : 0),
          projection: geometry.project(position),
        ),
      );
    }
    _updateRanking();
  }

  /// The fixed step: 60 per second.
  static const double dt = 1 / 60;
  static const int ticksPerSecond = 60;

  /// Steps of countdown before the start (three seconds).
  static const int countdownTicks = 180;

  /// How far outside the road edge a car can go before it is held back, in
  /// metres.
  static const double runoff = 14;

  /// Steps after a contact during which driving is not "clean".
  static const int contactMemoryTicks = 60;

  final RaceConfig config;
  final TrackGeometry geometry;

  /// One controller per rival, in the order of [RaceConfig.rivals]. A missing
  /// one leaves that rival standing still.
  final List<CarController> controllers;

  /// Constant sideways push on every car, in m/s squared (Galilee wind).
  final Vec2 wind;

  /// Makes the player's car easy to drive; null drives it exactly as asked.
  final PlayerAssist? assist;

  /// The boost pads on the road; empty when the race has none.
  late final List<BoostPad> pads;

  late final List<RaceCar> cars;

  RacePhase _phase = RacePhase.countdown;
  int _countdownLeft = countdownTicks;
  int _raceTick = 0;
  int? _finishTick;

  RacePhase get phase => _phase;

  /// Steps since the lights went out.
  int get raceTick => _raceTick;

  /// Seconds since the lights went out.
  double get elapsedSeconds => _raceTick * dt;

  /// Seconds of countdown left (0 once racing).
  double get countdownSeconds => _countdownLeft * dt;

  RaceCar get player => cars.first;

  /// The longest a race can run before it ends with whoever has finished.
  int get maxTicks =>
      ((config.track.parLapSeconds * config.laps * 3 + 60) * ticksPerSecond).round();

  /// Advances the race by one step with the player's [playerInput].
  void step(DriveInput playerInput) {
    if (_phase == RacePhase.finished) return;
    if (_phase == RacePhase.countdown) {
      _countdownLeft--;
      if (_countdownLeft <= 0) _phase = RacePhase.racing;
      return;
    }

    final List<DriveInput> inputs = <DriveInput>[];
    for (final RaceCar car in cars) {
      if (car.finished || car.eliminated) {
        inputs.add(const DriveInput(brake: 0.3));
      } else if (car.isPlayer) {
        inputs.add(assist?.apply(this, car, playerInput) ?? playerInput);
      } else {
        final int c = car.index - 1;
        inputs.add(c < controllers.length ? controllers[c].drive(this, car) : DriveInput.idle);
      }
    }

    for (final RaceCar car in cars) {
      _stepCar(car, inputs[car.index]);
    }
    _resolveContacts();
    for (final RaceCar car in cars) {
      _afterMove(car, inputs[car.index]);
    }
    _raceTick++;
    _updateRanking();
    _checkFinish();
  }

  void _stepCar(RaceCar car, DriveInput input) {
    if (!car.boosting && input.boost && !car.finished && car.meter.spend()) {
      car.boostSeconds = car.vehicle.boost.durationSeconds;
    }
    final SurfaceType surfaceType = car.projection.onTrack
        ? geometry.surfaceAt(car.projection.distance / geometry.length)
        : SurfaceModel.offTrack;
    final SurfaceEffect surface = SurfaceModel.effect(
      surfaceType,
      car.vehicle.kind,
      steadiness: car.tuning.steadiness,
    );
    CarPhysics.step(
      car.state,
      car.vehicle,
      car.tuning,
      input,
      surface,
      dt: dt,
      boosting: car.boosting,
      wind: wind,
    );
    if (car.boostSeconds > 0) {
      car.boostSeconds = car.boostSeconds - dt;
      if (car.boostSeconds < 0) car.boostSeconds = 0;
    }
  }

  void _resolveContacts() {
    for (int i = 0; i < cars.length; i++) {
      for (int j = i + 1; j < cars.length; j++) {
        final RaceCar a = cars[i];
        final RaceCar b = cars[j];
        if (a.eliminated || b.eliminated) continue;
        if (CarPhysics.resolveContact(a.state, a.vehicle, b.state, b.vehicle)) {
          a.lastContactTick = _raceTick;
          b.lastContactTick = _raceTick;
        }
      }
    }
  }

  void _afterMove(RaceCar car, DriveInput input) {
    car.projection = geometry.project(car.state.position, hint: car.projection.index);

    // Hold a car that has gone far off the road.
    final double limit = car.projection.halfWidth + runoff;
    if (car.projection.lateral.abs() > limit) {
      final Vec2 normal = car.projection.tangent.perpendicular;
      final double sign = car.projection.lateral > 0 ? 1.0 : -1.0;
      final double excess = car.projection.lateral.abs() - limit;
      car.state.position = car.state.position - normal * (sign * excess);
      final double outward = car.state.velocity.dot(normal) * sign;
      if (outward > 0) {
        car.state.velocity = car.state.velocity - normal * (sign * outward);
      }
      car.state.velocity = car.state.velocity * 0.9;
      car.projection = geometry.project(car.state.position, hint: car.projection.index);
    }

    car.tracker.update(car.projection.distance, (_raceTick + 1) * dt);
    if (pads.isNotEmpty && !car.finished && !car.eliminated) {
      for (final BoostPad pad in pads) {
        if (BoostPads.hit(pad, car.projection.distance, car.projection.lateral, geometry.length)) {
          if (car.boostSeconds < BoostPads.boostSeconds) car.boostSeconds = BoostPads.boostSeconds;
          break;
        }
      }
    }

    if (car.finished || car.eliminated) return;
    car.racingTicks++;
    final bool recentContact = car.lastContactTick != null &&
        _raceTick - car.lastContactTick! < contactMemoryTicks;
    final bool clean = car.projection.onTrack && !recentContact;
    if (clean) car.cleanTicks++;

    final double multiplier = car.tuning.meterFillMultiplier;
    if (clean && car.state.forwardSpeed > 8) {
      car.meter.addCleanDriving(dt, multiplier: multiplier);
    }
    if (car.state.drifting) car.meter.addDrift(dt, multiplier: multiplier);
    car.meter.updateSlipstream(_inSlipstream(car), dt, multiplier: multiplier);
  }

  bool _inSlipstream(RaceCar car) {
    final Vec2 forward = car.state.forward;
    final Vec2 right = forward.perpendicular;
    for (final RaceCar other in cars) {
      if (identical(other, car) || other.eliminated) continue;
      final Vec2 offset = other.state.position - car.state.position;
      final double ahead = offset.dot(forward);
      final double side = offset.dot(right);
      if (ahead > 3 && ahead < 22 && side.abs() < 2.5 && other.state.forwardSpeed > 10) {
        return true;
      }
    }
    return false;
  }

  void _updateRanking() {
    final List<RaceCar> order = List<RaceCar>.of(cars)..sort(_compare);
    for (int i = 0; i < order.length; i++) {
      order[i].position = i + 1;
    }
  }

  int _compare(RaceCar a, RaceCar b) {
    if (a.eliminated != b.eliminated) return a.eliminated ? 1 : -1;
    if (a.finished != b.finished) return a.finished ? -1 : 1;
    if (a.finished && b.finished) {
      final int byTime = a.tracker.finishSeconds!.compareTo(b.tracker.finishSeconds!);
      if (byTime != 0) return byTime;
    } else {
      final int byProgress = b.progress.compareTo(a.progress);
      if (byProgress != 0) return byProgress;
    }
    return a.index.compareTo(b.index);
  }

  void _checkFinish() {
    if (player.finished || _raceTick >= maxTicks) endRace();
  }

  /// Drops a car from the race (Elimination). If it is the player's car the
  /// race ends.
  void eliminate(RaceCar car) {
    car.eliminated = true;
    _updateRanking();
    if (car.isPlayer) endRace();
  }

  /// Ends the race now: used when a mode rule ends it (the player is dropped
  /// in Elimination, or caught in Escape Run).
  void endRace() {
    if (_phase == RacePhase.finished) return;
    _phase = RacePhase.finished;
    _finishTick = _raceTick;
  }

  /// Every car's result, ranked. Cars that had not finished when the race
  /// ended are ranked by distance covered and marked as not finished.
  List<RacerStanding> standings() {
    final List<RaceCar> order = List<RaceCar>.of(cars)..sort(_compare);
    final int endTick = _finishTick ?? _raceTick;
    return <RacerStanding>[
      for (final RaceCar car in order)
        RacerStanding(
          racerId: car.id,
          isPlayer: car.isPlayer,
          position: car.position,
          finished: car.finished,
          totalTime: _duration(car.tracker.finishSeconds ?? endTick * dt),
          lapTimes: <Duration>[for (final double s in car.tracker.lapTimes) _duration(s)],
        ),
    ];
  }

  /// The player's share of the race driven cleanly, 0 to 1.
  double get cleanDrivingScore =>
      player.racingTicks == 0 ? 0 : player.cleanTicks / player.racingTicks;

  /// The finished race as a [RaceResult]. Stars come from the star rules
  /// (batch p2c) and are passed in.
  RaceResult toResult({int stars = 0}) => RaceResult(
        trackId: config.track.id,
        mode: config.mode,
        seed: config.seed,
        standings: standings(),
        stars: stars,
        cleanDrivingScore: cleanDrivingScore,
      );

  /// A number that summarises the state of the race, for determinism tests:
  /// the same race always gives the same hash.
  int stateHash() {
    int hash = 0x811C9DC5;
    void mix(int value) {
      hash = ((hash ^ (value & 0xFFFFFFFF)) * 0x01000193) & 0xFFFFFFFF;
    }

    mix(_raceTick);
    for (final RaceCar car in cars) {
      mix((car.state.position.x * 1000).round());
      mix((car.state.position.y * 1000).round());
      mix((car.state.heading * 10000).round());
      mix((car.state.velocity.x * 1000).round());
      mix((car.state.velocity.y * 1000).round());
      mix(car.tracker.lap);
    }
    return hash;
  }

  static Duration _duration(double seconds) =>
      Duration(microseconds: (seconds * 1000000).round());
}
