import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/models/track.dart';
import 'package:ruach/core/models/vec2.dart';

const List<Vec2> _loop = <Vec2>[
  Vec2(0, 0),
  Vec2(100, 0),
  Vec2(200, 50),
  Vec2(200, 150),
  Vec2(100, 200),
  Vec2(0, 200),
  Vec2(-100, 150),
  Vec2(-100, 50),
];

Track _track({
  String id = 'test_track',
  int number = 1,
  Era era = Era.chariotAge,
  TrackVariant variant = TrackVariant.then,
  List<Vec2> centerline = _loop,
  List<double>? widths,
  List<double> checkpoints = const <double>[0.25, 0.5, 0.75],
  double par = 60,
  List<SurfaceZone> zones = const <SurfaceZone>[],
}) =>
    Track(
      id: id,
      number: number,
      era: era,
      variant: variant,
      centerline: centerline,
      widths: widths ?? List<double>.filled(centerline.length, 12),
      checkpointFractions: checkpoints,
      parLapSeconds: par,
      surfaceZones: zones,
    );

void main() {
  test('a well-formed track has no problems', () {
    expect(_track().validate(), isEmpty);
  });

  test('era follows the track number', () {
    expect(Track.eraForNumber(1), Era.chariotAge);
    expect(Track.eraForNumber(4), Era.chariotAge);
    expect(Track.eraForNumber(5), Era.kingdomAndExile);
    expect(Track.eraForNumber(8), Era.kingdomAndExile);
    expect(Track.eraForNumber(9), Era.gospelRoads);
    expect(Track.eraForNumber(12), Era.gospelRoads);
    expect(Track.eraForNumber(13), Era.today);
    expect(Track.eraForNumber(16), Era.today);
  });

  test('wrong era, number and variant are reported', () {
    expect(_track(number: 5).validate(), isNotEmpty);
    expect(_track(number: 17).validate(), isNotEmpty);
    expect(
      _track(number: 13, era: Era.today, variant: TrackVariant.now).validate(),
      isNotEmpty,
    );
  });

  test('centerline and widths are checked', () {
    expect(_track(centerline: _loop.sublist(0, 4)).validate(), isNotEmpty);
    expect(_track(widths: <double>[12, 12]).validate(), isNotEmpty);
    expect(
      _track(widths: <double>[12, 12, 12, 0, 12, 12, 12, 12]).validate(),
      isNotEmpty,
    );
    final List<Vec2> dup = List<Vec2>.of(_loop)..[1] = _loop[0];
    expect(_track(centerline: dup).validate(), isNotEmpty);
  });

  test('checkpoints must increase strictly inside the lap', () {
    expect(_track(checkpoints: <double>[0.5, 0.25, 0.75]).validate(), isNotEmpty);
    expect(_track(checkpoints: <double>[0, 0.5, 0.75]).validate(), isNotEmpty);
    expect(_track(checkpoints: <double>[0.5, 1]).validate(), isNotEmpty);
  });

  test('surface zones must be ordered and not overlap', () {
    const SurfaceZone a = SurfaceZone(
      startFraction: 0.1,
      endFraction: 0.3,
      surface: SurfaceType.sand,
    );
    const SurfaceZone b = SurfaceZone(
      startFraction: 0.2,
      endFraction: 0.4,
      surface: SurfaceType.ford,
    );
    const SurfaceZone c = SurfaceZone(
      startFraction: 0.5,
      endFraction: 0.4,
      surface: SurfaceType.dirt,
    );
    expect(_track(zones: <SurfaceZone>[a]).validate(), isEmpty);
    expect(_track(zones: <SurfaceZone>[a, b]).validate(), isNotEmpty);
    expect(_track(zones: <SurfaceZone>[c]).validate(), isNotEmpty);
  });

  test('par lap must be positive', () {
    expect(_track(par: 0).validate(), isNotEmpty);
  });

  test('equality is by id', () {
    expect(_track(), _track(number: 2, era: Era.chariotAge));
    expect(_track() == _track(id: 'other'), isFalse);
  });
}
