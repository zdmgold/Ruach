import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/logic/catalog_ids.dart';
import 'package:ruach/core/logic/quick_start.dart';
import 'package:ruach/core/models/progress.dart';

void main() {
  test('a new player starts on the first Journey track', () {
    expect(QuickStart.nextTrack(Progress()), TrackIds.journey.first);
  });

  test('each launch carries on at the first track without a star', () {
    final Progress p = Progress(stars: <String, int>{
      TrackIds.journey[0]: 3,
      TrackIds.journey[1]: 1,
    });
    expect(QuickStart.nextTrack(p), TrackIds.journey[2]);
  });

  test('once every track is cleared the tracks come round in turn', () {
    final Progress p = Progress(
      stars: <String, int>{for (final String id in TrackIds.journey) id: 1},
      racesFinished: 18,
    );
    expect(QuickStart.nextTrack(p), TrackIds.journey[18 % TrackIds.journey.length]);
  });
}
