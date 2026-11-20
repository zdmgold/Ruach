import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/logic/surface_model.dart';
import 'package:ruach/core/models/track.dart';
import 'package:ruach/core/models/vehicle.dart';

void main() {
  test('asphalt is the reference surface', () {
    final SurfaceEffect e = SurfaceModel.effect(SurfaceType.asphalt, VehicleKind.hatch);
    expect(e.gripFactor, 1);
    expect(e.speedFactor, 1);
  });

  test('every other surface is no better than asphalt', () {
    for (final SurfaceType s in SurfaceType.values) {
      final SurfaceEffect e = SurfaceModel.base(s);
      expect(e.gripFactor, lessThanOrEqualTo(1), reason: s.name);
      expect(e.speedFactor, lessThanOrEqualTo(1), reason: s.name);
      expect(e.gripFactor, greaterThan(0), reason: s.name);
      expect(e.speedFactor, greaterThan(0), reason: s.name);
    }
  });

  test('fords slow every vehicle', () {
    for (final VehicleKind k in VehicleKind.values) {
      expect(SurfaceModel.effect(SurfaceType.ford, k).speedFactor, lessThan(0.9), reason: k.name);
    }
  });

  test('the utility 4x4 copes best on sand and the hatch worst', () {
    final SurfaceEffect utility = SurfaceModel.effect(SurfaceType.sand, VehicleKind.utility4x4);
    final SurfaceEffect cart = SurfaceModel.effect(SurfaceType.sand, VehicleKind.roadCart);
    final SurfaceEffect hatch = SurfaceModel.effect(SurfaceType.sand, VehicleKind.hatch);
    expect(utility.speedFactor, greaterThan(cart.speedFactor));
    expect(cart.speedFactor, greaterThan(hatch.speedFactor));
    expect(utility.gripFactor, greaterThan(hatch.gripFactor));
  });

  test('steadiness reduces the penalty and is capped at no penalty', () {
    final SurfaceEffect plain = SurfaceModel.effect(SurfaceType.grass, VehicleKind.hatch);
    final SurfaceEffect steady = SurfaceModel.effect(SurfaceType.grass, VehicleKind.hatch, steadiness: 0.5);
    final SurfaceEffect full = SurfaceModel.effect(SurfaceType.grass, VehicleKind.hatch, steadiness: 5);
    expect(steady.speedFactor, greaterThan(plain.speedFactor));
    expect(full.speedFactor, closeTo(1, 1e-9));
    expect(full.gripFactor, closeTo(1, 1e-9));
  });

  test('the off-track surface is grass', () {
    expect(SurfaceModel.offTrack, SurfaceType.grass);
  });
}
