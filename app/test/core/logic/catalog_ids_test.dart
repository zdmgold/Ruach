import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/logic/catalog_ids.dart';
import 'package:ruach/core/models/vehicle.dart';

void main() {
  test('16 tracks and 28 raceable ids, all unique', () {
    expect(TrackIds.journey.length, 16);
    expect(TrackIds.all.length, 28);
    expect(TrackIds.all.toSet().length, 28);
  });

  test('numbers and Now variants', () {
    expect(TrackIds.numberOf('nile_banks'), 1);
    expect(TrackIds.numberOf('highland_switchbacks'), 16);
    expect(TrackIds.numberOf('appian_way_now'), 12);
    expect(TrackIds.numberOf('unknown'), 0);
    expect(TrackIds.isNowVariant('appian_way_now'), isTrue);
    expect(TrackIds.baseOf('appian_way_now'), 'appian_way');
    expect(TrackIds.hasNowVariant('appian_way'), isTrue);
    expect(TrackIds.hasNowVariant('desert_pass'), isFalse);
    expect(TrackIds.hasNowVariant('appian_way_now'), isFalse);
  });

  test('every vehicle kind has an id', () {
    expect(<String>{for (final VehicleKind k in VehicleKind.values) VehicleIds.forKind(k)}, VehicleIds.all.toSet());
  });
}
