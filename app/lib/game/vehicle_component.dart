import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:ruach/core/logic/race_rules.dart';
import 'package:ruach/core/models/vehicle.dart';
import 'package:ruach/theme/tokens.dart';

/// Draws one vehicle in code, in world metres, with the nose pointing along
/// +x. Every design is chunky and cartoonish, seen from above, with a dark
/// outline, so each one reads at a glance and none looks like a bug: wheels
/// are tucked under the body, and each kind has its own silhouette. All
/// designs are original; there are no brands or licensed shapes.
abstract final class VehicleArt {
  /// Body length and width in metres for each kind.
  static (double, double) sizeOf(VehicleKind kind) => switch (kind) {
        VehicleKind.lightChariot => (4.8, 2.4),
        VehicleKind.heavyChariot => (5.2, 2.9),
        VehicleKind.roadCart => (5.0, 2.5),
        VehicleKind.hatch => (5.0, 2.5),
        VehicleKind.roadster => (5.6, 2.4),
        VehicleKind.utility4x4 => (5.6, 2.8),
      };

  /// The colour a rival's team uses: stable for a team name.
  static Color teamColor(String team) {
    int h = 17;
    for (final int u in team.codeUnits) {
      h = (h * 31 + u) & 0x7FFFFFFF;
    }
    return WorldColors.rivalCars[h % WorldColors.rivalCars.length];
  }

  static bool isChariot(VehicleKind kind) =>
      kind == VehicleKind.lightChariot || kind == VehicleKind.heavyChariot;

  static Color _shade(Color c, double amount) => Color.lerp(c, const Color(0xFF000000), amount)!;
  static Color _tint(Color c, double amount) => Color.lerp(c, const Color(0xFFFFFFFF), amount)!;

  static final Paint _outline = Paint()
    ..color = WorldColors.carOutline
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.2
    ..strokeJoin = StrokeJoin.round;

  /// A filled rounded box with the outline round it.
  static void _box(Canvas c, Rect r, double radius, Color fill) {
    final RRect rr = RRect.fromRectAndRadius(r, Radius.circular(radius));
    c.drawRRect(rr, Paint()..color = fill);
    c.drawRRect(rr, _outline);
  }

  static void _oval(Canvas c, Rect r, Color fill) {
    c.drawOval(r, Paint()..color = fill);
    c.drawOval(r, _outline);
  }

  static void paint(Canvas c, VehicleKind kind, Color body, {bool boosting = false}) {
    final (double length, double width) = sizeOf(kind);
    // Soft contact shadow.
    c.drawOval(
      Rect.fromCenter(center: const Offset(0.2, 0.25), width: length * 1.1, height: width * 1.1),
      Paint()..color = const Color(0x33000000),
    );
    if (boosting) _flames(c, length, width);
    switch (kind) {
      case VehicleKind.lightChariot:
        _chariot(c, length, width, body, heavy: false);
      case VehicleKind.heavyChariot:
        _chariot(c, length, width, body, heavy: true);
      case VehicleKind.roadCart:
        _cart(c, length, width, body);
      case VehicleKind.hatch:
        _hatch(c, length, width, body);
      case VehicleKind.roadster:
        _roadster(c, length, width, body);
      case VehicleKind.utility4x4:
        _utility(c, length, width, body);
    }
  }

  static void _flames(Canvas c, double length, double width) {
    for (final double s in <double>[-1, 1]) {
      final Path flame = Path()
        ..moveTo(-length * 0.5, s * width * 0.2 - 0.35)
        ..lineTo(-length * 0.5 - 2.6, s * width * 0.2)
        ..lineTo(-length * 0.5, s * width * 0.2 + 0.35)
        ..close();
      c.drawPath(flame, Paint()..color = const Color(0xFFFF8A00));
      final Path core = Path()
        ..moveTo(-length * 0.5, s * width * 0.2 - 0.18)
        ..lineTo(-length * 0.5 - 1.4, s * width * 0.2)
        ..lineTo(-length * 0.5, s * width * 0.2 + 0.18)
        ..close();
      c.drawPath(core, Paint()..color = const Color(0xFFFFF1A8));
    }
  }

  /// Four wheels tucked under the body: only their outer edge shows.
  static void _wheels(Canvas c, double frontX, double rearX, double half, {double size = 1.1}) {
    for (final double x in <double>[frontX, rearX]) {
      for (final double s in <double>[-1, 1]) {
        _box(
          c,
          Rect.fromCenter(center: Offset(x, s * (half - 0.2)), width: size, height: 0.7),
          0.25,
          WorldColors.carWheel,
        );
      }
    }
  }

  static void _lamps(Canvas c, double noseX, double half) {
    for (final double s in <double>[-1, 1]) {
      c.drawCircle(Offset(noseX - 0.2, s * half * 0.55), 0.3, Paint()..color = WorldColors.lampHalo);
    }
  }

  static void _hatch(Canvas c, double length, double width, Color body) {
    final double half = width / 2;
    _wheels(c, length * 0.3, -length * 0.3, half);
    _box(c, Rect.fromLTRB(-length / 2, -half + 0.15, length / 2, half - 0.15), 1.0, body);
    // Bonnet and boot, a little lighter.
    _box(c, Rect.fromLTRB(length * 0.2, -half + 0.45, length / 2 - 0.3, half - 0.45), 0.5, _tint(body, 0.25));
    // Cabin: tall roof between two windows.
    _box(c, Rect.fromLTRB(-length * 0.34, -half + 0.4, length * 0.2, half - 0.4), 0.7, WorldColors.carGlass);
    _box(c, Rect.fromLTRB(-length * 0.2, -half + 0.6, length * 0.06, half - 0.6), 0.4, _tint(body, 0.15));
    _lamps(c, length / 2, half);
  }

  static void _roadster(Canvas c, double length, double width, Color body) {
    final double half = width / 2;
    _wheels(c, length * 0.32, -length * 0.32, half, size: 1.3);
    // A long, low body that narrows at the nose.
    final Path hull = Path()
      ..moveTo(-length / 2 + 0.6, -half + 0.1)
      ..lineTo(length * 0.2, -half + 0.1)
      ..quadraticBezierTo(length / 2, -half * 0.8, length / 2, 0)
      ..quadraticBezierTo(length / 2, half * 0.8, length * 0.2, half - 0.1)
      ..lineTo(-length / 2 + 0.6, half - 0.1)
      ..quadraticBezierTo(-length / 2, half - 0.1, -length / 2, half - 0.7)
      ..lineTo(-length / 2, -half + 0.7)
      ..quadraticBezierTo(-length / 2, -half + 0.1, -length / 2 + 0.6, -half + 0.1)
      ..close();
    c.drawPath(hull, Paint()..color = body);
    c.drawPath(hull, _outline);
    // Two racing stripes down the bonnet.
    for (final double s in <double>[-0.3, 0.3]) {
      c.drawRect(
        Rect.fromLTRB(length * 0.02, s - 0.12, length / 2 - 0.2, s + 0.12),
        Paint()..color = const Color(0xCCFFFFFF),
      );
    }
    // Small cabin set back, and a rear wing.
    _box(c, Rect.fromLTRB(-length * 0.22, -half + 0.55, length * 0.0, half - 0.55), 0.5, WorldColors.carGlass);
    _box(c, Rect.fromLTRB(-length / 2 - 0.1, -half + 0.2, -length / 2 + 0.5, half - 0.2), 0.15, _shade(body, 0.35));
    _lamps(c, length / 2, half);
  }

  static void _utility(Canvas c, double length, double width, Color body) {
    final double half = width / 2;
    _wheels(c, length * 0.3, -length * 0.3, half, size: 1.5);
    _box(c, Rect.fromLTRB(-length / 2, -half + 0.1, length / 2, half - 0.1), 0.5, body);
    // Tall boxy cabin with a roof rack.
    _box(c, Rect.fromLTRB(-length * 0.36, -half + 0.4, length * 0.16, half - 0.4), 0.35, WorldColors.carGlass);
    _box(c, Rect.fromLTRB(-length * 0.3, -half + 0.6, length * 0.08, half - 0.6), 0.2, _tint(body, 0.2));
    for (final double x in <double>[-0.2, -0.9, 0.5]) {
      c.drawLine(Offset(x - length * 0.05, -half + 0.7), Offset(x - length * 0.05, half - 0.7), Paint()
        ..color = _shade(body, 0.45)
        ..strokeWidth = 0.18);
    }
    // Bull bar and a spare wheel on the back.
    c.drawLine(Offset(length / 2 + 0.1, -half + 0.4), Offset(length / 2 + 0.1, half - 0.4), Paint()
      ..color = WorldColors.carOutline
      ..strokeWidth = 0.35
      ..strokeCap = StrokeCap.round);
    _box(c, Rect.fromCenter(center: Offset(-length / 2 - 0.1, 0), width: 0.5, height: 1.2), 0.2, WorldColors.carWheel);
    _lamps(c, length / 2, half);
  }

  static void _horse(Canvas c, double x, double y, double size, Color coat) {
    final Color mane = _shade(coat, 0.45);
    // Body, neck and head all point forward (+x).
    _oval(c, Rect.fromCenter(center: Offset(x, y), width: size * 1.7, height: size * 0.8), coat);
    _oval(c, Rect.fromCenter(center: Offset(x + size * 0.95, y), width: size * 0.9, height: size * 0.55), coat);
    c.drawLine(Offset(x - size * 0.5, y), Offset(x + size * 0.75, y), Paint()
      ..color = mane
      ..strokeWidth = 0.22
      ..strokeCap = StrokeCap.round);
    // Tail.
    c.drawLine(Offset(x - size * 0.85, y), Offset(x - size * 1.25, y + size * 0.15), Paint()
      ..color = mane
      ..strokeWidth = 0.25
      ..strokeCap = StrokeCap.round);
  }

  static void _chariot(Canvas c, double length, double width, Color body, {required bool heavy}) {
    final double half = width / 2;
    final Color wood = heavy ? _shade(WorldColors.carWood, 0.25) : WorldColors.carWood;
    final Color coat = heavy ? const Color(0xFF5A3A22) : const Color(0xFFF4ECD8);
    final double carX = -length * 0.22;
    final double carLength = length * 0.46;
    // Wheels at the sides of the carriage.
    for (final double s in <double>[-1, 1]) {
      _box(c, Rect.fromCenter(center: Offset(carX - 0.1, s * (half - 0.25)), width: heavy ? 1.8 : 1.5, height: 0.6), 0.25, WorldColors.carWheel);
    }
    // Pole, then the horses, then the carriage on top.
    c.drawLine(Offset(carX, 0), Offset(length * 0.46, 0), Paint()
      ..color = wood
      ..strokeWidth = 0.3);
    final double spread = half * 0.5;
    for (final double s in <double>[-1, 1]) {
      _horse(c, length * 0.2, s * spread, heavy ? 1.7 : 1.5, coat);
    }
    _box(c, Rect.fromLTRB(carX - carLength / 2, -half + 0.35, carX + carLength / 2, half - 0.35), 0.5, wood);
    _box(c, Rect.fromLTRB(carX - carLength / 2 + 0.3, -half + 0.7, carX + carLength / 2 - 0.3, half - 0.7), 0.35, body);
    if (heavy) {
      // Shields along the sides of the heavy chariot.
      for (final double s in <double>[-1, 1]) {
        c.drawCircle(Offset(carX, s * (half - 0.35)), 0.45, Paint()..color = _tint(body, 0.35));
      }
    }
  }

  static void _cart(Canvas c, double length, double width, Color body) {
    final double half = width / 2;
    final double cartX = -length * 0.18;
    final double cartLength = length * 0.5;
    for (final double s in <double>[-1, 1]) {
      _box(c, Rect.fromCenter(center: Offset(cartX, s * (half - 0.2)), width: 1.6, height: 0.6), 0.25, WorldColors.carWheel);
    }
    c.drawLine(Offset(cartX, 0), Offset(length * 0.45, 0), Paint()
      ..color = WorldColors.carWood
      ..strokeWidth = 0.3);
    // A donkey pulls the cart.
    _horse(c, length * 0.3, 0, 1.4, const Color(0xFF9A8B7A));
    _box(c, Rect.fromLTRB(cartX - cartLength / 2, -half + 0.3, cartX + cartLength / 2, half - 0.3), 0.4, WorldColors.carWood);
    // A canvas cover in the team colour.
    _box(c, Rect.fromLTRB(cartX - cartLength / 2 + 0.2, -half + 0.6, cartX + cartLength / 2 - 0.2, half - 0.6), 0.9, body);
    c.drawLine(Offset(cartX, -half + 0.8), Offset(cartX, half - 0.8), Paint()
      ..color = _shade(body, 0.3)
      ..strokeWidth = 0.15);
  }
}

/// A car on the track. It reads the race car's state every frame and draws it
/// at its position and heading; it holds no state of its own.
final class VehicleComponent extends Component {
  VehicleComponent({required this.car, required this.color});

  final RaceCar car;
  final Color color;

  @override
  void render(Canvas canvas) {
    if (car.eliminated) return;
    canvas.save();
    canvas.translate(car.state.position.x, car.state.position.y);
    canvas.rotate(car.state.heading);
    if (car.isPlayer) _marker(canvas, car.vehicle.kind);
    VehicleArt.paint(canvas, car.vehicle.kind, color, boosting: car.boosting);
    canvas.restore();
  }

  /// A white ring under the player's vehicle that pulses gently, so "which one
  /// am I" is never in doubt.
  void _marker(Canvas canvas, VehicleKind kind) {
    final (double length, double width) = VehicleArt.sizeOf(kind);
    final double r = length * 0.78 + 0.25 * math.sin(_t * 6);
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()..color = const Color(0x55FFFFFF),
    );
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.3,
    );
  }

  double _t = 0;

  @override
  void update(double dt) {
    _t += dt;
  }
}
