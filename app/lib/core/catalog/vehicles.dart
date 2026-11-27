import 'package:ruach/core/logic/catalog_ids.dart';
import 'package:ruach/core/models/track.dart';
import 'package:ruach/core/models/vehicle.dart';

/// The six vehicles (blueprint section 2). All are original designs. The
/// numbers are tuning starting points that the balance simulation adjusts.
abstract final class VehicleCatalog {
  static const Vehicle lightChariot = Vehicle(
    id: VehicleIds.lightChariot,
    kind: VehicleKind.lightChariot,
    era: Era.chariotAge,
    massKg: 500,
    acceleration: 8.5,
    maxSpeed: 30,
    brakeDeceleration: 12,
    grip: 0.8,
    drag: 0.35,
    steerRate: 1.6,
    canDrift: false,
    boost: BoostProfile(durationSeconds: 1.8, topSpeedMultiplier: 1.4, accelerationMultiplier: 2),
  );

  static const Vehicle heavyChariot = Vehicle(
    id: VehicleIds.heavyChariot,
    kind: VehicleKind.heavyChariot,
    era: Era.chariotAge,
    massKg: 900,
    acceleration: 5.5,
    maxSpeed: 27,
    brakeDeceleration: 11,
    grip: 0.95,
    drag: 0.3,
    steerRate: 1.4,
    canDrift: false,
    boost: BoostProfile(durationSeconds: 3, topSpeedMultiplier: 1.3, accelerationMultiplier: 1.6),
  );

  static const Vehicle roadCart = Vehicle(
    id: VehicleIds.roadCart,
    kind: VehicleKind.roadCart,
    era: Era.gospelRoads,
    massKg: 700,
    acceleration: 7,
    maxSpeed: 31,
    brakeDeceleration: 14,
    grip: 1,
    drag: 0.3,
    steerRate: 1.9,
    canDrift: false,
    boost: BoostProfile(durationSeconds: 2.4, topSpeedMultiplier: 1.35, accelerationMultiplier: 1.8),
  );

  static const Vehicle hatch = Vehicle(
    id: VehicleIds.hatch,
    kind: VehicleKind.hatch,
    era: Era.today,
    massKg: 1100,
    acceleration: 9,
    maxSpeed: 42,
    brakeDeceleration: 18,
    grip: 1.1,
    drag: 0.3,
    steerRate: 2.2,
    canDrift: false,
    boost: BoostProfile(durationSeconds: 2.5, topSpeedMultiplier: 1.35, accelerationMultiplier: 1.9),
  );

  static const Vehicle roadster = Vehicle(
    id: VehicleIds.roadster,
    kind: VehicleKind.roadster,
    era: Era.today,
    massKg: 1000,
    acceleration: 11,
    maxSpeed: 50,
    brakeDeceleration: 20,
    grip: 0.95,
    drag: 0.28,
    steerRate: 2.4,
    canDrift: true,
    boost: BoostProfile(durationSeconds: 2.2, topSpeedMultiplier: 1.4, accelerationMultiplier: 2),
  );

  static const Vehicle utility4x4 = Vehicle(
    id: VehicleIds.utility4x4,
    kind: VehicleKind.utility4x4,
    era: Era.today,
    massKg: 1500,
    acceleration: 8,
    maxSpeed: 38,
    brakeDeceleration: 16,
    grip: 1.05,
    drag: 0.34,
    steerRate: 2,
    canDrift: false,
    boost: BoostProfile(durationSeconds: 3, topSpeedMultiplier: 1.28, accelerationMultiplier: 1.7),
  );

  static const List<Vehicle> all = <Vehicle>[
    lightChariot,
    heavyChariot,
    roadCart,
    hatch,
    roadster,
    utility4x4,
  ];

  /// The vehicle with [id], or null.
  static Vehicle? byId(String id) {
    for (final Vehicle v in all) {
      if (v.id == id) return v;
    }
    return null;
  }

  static Vehicle forKind(VehicleKind kind) => byId(VehicleIds.forKind(kind))!;

  /// The vehicle Journey races use on [track]: chariots on tracks 1 to 8, the
  /// Road Cart on 9 to 12, a hatch on Today tracks and on every Now variant.
  static Vehicle journeyDefault(Track track) {
    if (track.variant == TrackVariant.now || track.number >= 13) return hatch;
    if (track.number >= 9) return roadCart;
    return lightChariot;
  }
}
