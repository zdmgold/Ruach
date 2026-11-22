import 'dart:ui';

import 'package:flame/components.dart';
import 'package:ruach/core/logic/race_rules.dart';
import 'package:ruach/core/models/vehicle.dart';
import 'package:ruach/theme/tokens.dart';

/// Draws one vehicle in code, in world metres, with the nose pointing along
/// +x. All designs are original; there are no brands or licensed shapes.
abstract final class VehicleArt {
  /// Body length and width in metres for each kind.
  static (double, double) sizeOf(VehicleKind kind) => switch (kind) {
        VehicleKind.lightChariot => (3.4, 1.8),
        VehicleKind.heavyChariot => (3.8, 2.2),
        VehicleKind.roadCart => (3.8, 1.9),
        VehicleKind.hatch => (4.0, 1.8),
        VehicleKind.roadster => (4.3, 1.8),
        VehicleKind.utility4x4 => (4.4, 2.0),
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

  static void paint(Canvas c, VehicleKind kind, Color body, {bool boosting = false}) {
    final (double length, double width) = sizeOf(kind);
    final Paint wheel = Paint()..color = WorldColors.carWheel;
    final Paint main = Paint()..color = body;
    final Paint glass = Paint()..color = WorldColors.carGlass;
    // Soft contact shadow.
    c.drawOval(
      Rect.fromCenter(center: Offset.zero, width: length * 1.1, height: width * 1.15),
      Paint()..color = const Color(0x33000000),
    );
    if (boosting) {
      c.drawRect(
        Rect.fromLTWH(-length * 0.5 - 1.6, -width * 0.25, 1.6, width * 0.5),
        Paint()..color = WorldColors.lampHalo.withValues(alpha: 0.7),
      );
    }
    if (isChariot(kind)) {
      _chariot(c, kind, length, width, main, wheel);
    } else {
      _car(c, kind, length, width, main, glass, wheel);
    }
  }

  static void _chariot(Canvas c, VehicleKind kind, double length, double width, Paint main, Paint wheel) {
    final bool heavy = kind == VehicleKind.heavyChariot;
    final Paint wood = Paint()..color = WorldColors.carWood;
    // Wheels at the sides.
    final double wheelLength = heavy ? 1.1 : 0.9;
    for (final double side in <double>[-1, 1]) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(-length * 0.12, side * width * 0.5), width: wheelLength, height: 0.35),
          const Radius.circular(0.15),
        ),
        wheel,
      );
    }
    // Platform.
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(-length * 0.12, 0), width: length * 0.42, height: width * 0.8),
        const Radius.circular(0.3),
      ),
      main,
    );
    // Pole and two animals, drawn as plain ovals.
    c.drawRect(Rect.fromLTRB(-length * 0.12, -0.08, length * 0.5, 0.08), wood);
    for (final double side in <double>[-1, 1]) {
      c.drawOval(
        Rect.fromCenter(center: Offset(length * 0.3, side * width * 0.24), width: length * 0.3, height: width * 0.32),
        Paint()..color = WorldColors.carWood.withValues(alpha: 0.9),
      );
    }
    c.drawCircle(Offset(-length * 0.12, 0), width * 0.14, wood);
  }

  static void _car(Canvas c, VehicleKind kind, double length, double width, Paint main, Paint glass, Paint wheel) {
    final double half = width / 2;
    // Wheels poke out slightly at the corners.
    for (final double sx in <double>[-1, 1]) {
      for (final double sy in <double>[-1, 1]) {
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(sx * length * 0.3, sy * half), width: 0.9, height: 0.4),
            const Radius.circular(0.15),
          ),
          wheel,
        );
      }
    }
    final double noseTaper = kind == VehicleKind.roadster ? 0.6 : 0.8;
    final Path body = Path()
      ..moveTo(-length / 2, -half * 0.92)
      ..lineTo(length * 0.2, -half * 0.92)
      ..lineTo(length / 2, -half * noseTaper * 0.7)
      ..lineTo(length / 2, half * noseTaper * 0.7)
      ..lineTo(length * 0.2, half * 0.92)
      ..lineTo(-length / 2, half * 0.92)
      ..close();
    c.drawPath(body, main);
    // Cabin: bigger on the hatch and 4x4, tiny on the roadster.
    final double cabinLength = switch (kind) {
      VehicleKind.roadster => length * 0.22,
      VehicleKind.utility4x4 => length * 0.46,
      VehicleKind.roadCart => length * 0.4,
      _ => length * 0.42,
    };
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(-length * 0.04, 0), width: cabinLength, height: width * 0.62),
        const Radius.circular(0.3),
      ),
      glass,
    );
    // A stripe on the bonnet for the roadster, a roof rack line on the 4x4.
    if (kind == VehicleKind.roadster) {
      c.drawRect(
        Rect.fromLTRB(length * 0.05, -0.12, length * 0.5, 0.12),
        Paint()..color = const Color(0x55FFFFFF),
      );
    }
    if (kind == VehicleKind.utility4x4) {
      c.drawRect(
        Rect.fromCenter(center: Offset(-length * 0.04, 0), width: cabinLength * 0.8, height: 0.12),
        Paint()..color = const Color(0x88FFFFFF),
      );
    }
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
    VehicleArt.paint(canvas, car.vehicle.kind, color, boosting: car.boosting);
    canvas.restore();
  }
}
