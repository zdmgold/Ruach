import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:ruach/core/logic/mode_rules.dart';
import 'package:ruach/core/logic/race_rules.dart';
import 'package:ruach/core/logic/seeded_rng.dart';
import 'package:ruach/core/models/track.dart';
import 'package:ruach/core/models/vec2.dart';
import 'package:ruach/providers/race_provider.dart';
import 'package:ruach/theme/tokens.dart';

enum ParticleKind { dust, spark, flame }

final class _Particle {
  bool alive = false;
  ParticleKind kind = ParticleKind.dust;
  double x = 0;
  double y = 0;
  double vx = 0;
  double vy = 0;
  double life = 0;
  double maxLife = 1;
  double size = 0.5;
  Color color = const Color(0xFFFFFFFF);
}

/// Dust, sparks and boost flames. A fixed pool, so a race allocates nothing
/// per frame, and a hard cap so a crowd of cars cannot slow a cheap phone.
/// Switched off entirely under Reduce Motion.
final class EffectsLayer extends Component {
  EffectsLayer({required this.race, required this.reduceMotion});

  /// Most particles alive at once.
  static const int capacity = 160;

  final RaceProvider race;
  final bool reduceMotion;

  final List<_Particle> _pool = List<_Particle>.generate(capacity, (int _) => _Particle());
  final SeededRng _rng = SeededRng(1).fork('effects');
  final Map<int, double> _dustTimer = <int, double>{};
  final Map<int, double> _flameTimer = <int, double>{};
  final Map<int, int> _lastContact = <int, int>{};
  final Paint _paint = Paint();

  /// How many particles are alive; for tests.
  int get aliveCount => _pool.where((_Particle p) => p.alive).length;

  @override
  void update(double dt) {
    super.update(dt);
    if (reduceMotion) return;
    for (final _Particle p in _pool) {
      if (!p.alive) continue;
      p.life -= dt;
      if (p.life <= 0) {
        p.alive = false;
        continue;
      }
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      if (p.kind == ParticleKind.dust) p.size += dt * 1.2;
    }
    final RaceSimulation? sim = race.simulation;
    if (sim == null || sim.phase != RacePhase.racing) return;
    for (final RaceCar car in sim.cars) {
      if (car.eliminated) continue;
      _spawnFor(sim, car, dt);
    }
  }

  void _spawnFor(RaceSimulation sim, RaceCar car, double dt) {
    final Vec2 pos = car.state.position;
    final Vec2 back = Vec2.fromAngle(car.state.heading + math.pi);
    final double speed = car.state.speed;

    final SurfaceType surface = sim.geometry.surfaceAt(car.projection.distance / sim.geometry.length);
    final bool loose = !car.projection.onTrack ||
        surface == SurfaceType.sand ||
        surface == SurfaceType.dirt ||
        surface == SurfaceType.ford;
    if (loose && speed > 10) {
      final double t = (_dustTimer[car.index] ?? 0) + dt;
      if (t >= 0.05) {
        _dustTimer[car.index] = 0;
        _spawn(
          ParticleKind.dust,
          pos + back * 1.8,
          back * (speed * 0.2) + Vec2(_rng.nextRange(-1.5, 1.5), _rng.nextRange(-1.5, 1.5)),
          life: 0.7,
          size: 0.5,
          color: surface == SurfaceType.ford
              ? WorldColors.trackFord
              : (surface == SurfaceType.sand ? WorldColors.trackSand : WorldColors.trackDirt),
        );
      } else {
        _dustTimer[car.index] = t;
      }
    }

    final int? contact = car.lastContactTick;
    if (contact != null && contact != _lastContact[car.index] && sim.raceTick - contact <= 2) {
      _lastContact[car.index] = contact;
      for (int k = 0; k < 4; k++) {
        _spawn(
          ParticleKind.spark,
          pos,
          Vec2.fromAngle(_rng.nextRange(0, 2 * math.pi), _rng.nextRange(4, 10)),
          life: 0.25,
          size: 0.18,
          color: WorldColors.lampHalo,
        );
      }
    }

    if (car.boosting) {
      final double t = (_flameTimer[car.index] ?? 0) + dt;
      if (t >= 0.03) {
        _flameTimer[car.index] = 0;
        _spawn(
          ParticleKind.flame,
          pos + back * 2.2,
          back * 6,
          life: 0.3,
          size: 0.45,
          color: WorldColors.playerCar,
        );
      } else {
        _flameTimer[car.index] = t;
      }
    }
  }

  void _spawn(ParticleKind kind, Vec2 at, Vec2 velocity, {required double life, required double size, required Color color}) {
    for (final _Particle p in _pool) {
      if (p.alive) continue;
      p
        ..alive = true
        ..kind = kind
        ..x = at.x
        ..y = at.y
        ..vx = velocity.x
        ..vy = velocity.y
        ..life = life
        ..maxLife = life
        ..size = size
        ..color = color;
      return;
    }
  }

  @override
  void render(Canvas canvas) {
    if (reduceMotion) return;
    for (final _Particle p in _pool) {
      if (!p.alive) continue;
      final double fade = (p.life / p.maxLife).clamp(0, 1).toDouble();
      final double base = p.kind == ParticleKind.dust ? 0.5 : 0.9;
      _paint.color = p.color.withValues(alpha: base * fade);
      canvas.drawCircle(Offset(p.x, p.y), p.size, _paint);
    }
  }
}

/// The abstract dust wall of an Escape Run, rising behind the player. It is a
/// band of haze with a ragged edge: no figures, no combat. It stays on under
/// Reduce Motion (it is game information) but stops rippling.
final class PursuitWall extends Component {
  PursuitWall({required this.race, required this.reduceMotion});

  final RaceProvider race;
  final bool reduceMotion;
  double _time = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (!reduceMotion) _time += dt;
  }

  @override
  void render(Canvas canvas) {
    final RaceSimulation? sim = race.simulation;
    final EscapeRun? escape = race.escape;
    if (sim == null || escape == null) return;
    final RaceCar player = sim.player;
    final Vec2 along = player.projection.tangent;
    final double gap = escape.gap.clamp(0, 400).toDouble();
    canvas.save();
    canvas.translate(player.state.position.x, player.state.position.y);
    canvas.rotate(along.angle);
    // Local x runs along the road; the wall's front edge is at -gap.
    final Path haze = Path()..moveTo(-gap - 400, -90);
    const int steps = 18;
    for (int i = 0; i <= steps; i++) {
      final double y = -90 + 180 * i / steps;
      final double jag = math.sin(i * 1.7 + _time * 2.2) * 6 + (i.isEven ? 3 : -3);
      haze.lineTo(-gap + jag, y);
    }
    haze.lineTo(-gap - 400, 90);
    haze.close();
    canvas.drawPath(haze, Paint()..color = WorldColors.trackSand.withValues(alpha: 0.55));
    canvas.drawPath(
      haze.shift(const Offset(-14, 0)),
      Paint()..color = WorldColors.trackDirt.withValues(alpha: 0.5),
    );
    canvas.restore();
  }
}
