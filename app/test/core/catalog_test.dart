import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/catalog/rivals.dart';
import 'package:ruach/core/catalog/tracks.dart';
import 'package:ruach/core/catalog/vehicles.dart';
import 'package:ruach/core/catalog/verse_moments.dart';
import 'package:ruach/core/logic/ai_driver.dart';
import 'package:ruach/core/logic/catalog_ids.dart';
import 'package:ruach/core/logic/par_estimator.dart';
import 'package:ruach/core/logic/race_rules.dart';
import 'package:ruach/core/logic/track_geometry.dart';
import 'package:ruach/core/logic/verse_repository.dart';
import 'package:ruach/core/models/race_config.dart';
import 'package:ruach/core/models/rival.dart';
import 'package:ruach/core/models/track.dart';
import 'package:ruach/core/models/upgrade.dart';
import 'package:ruach/core/models/vehicle.dart';
import 'package:ruach/core/models/verse.dart';
import 'package:ruach/core/ports/verse_source.dart';

import 'logic/test_support.dart';

const List<String> _languages = <String>[
  'en', 'es', 'fr', 'de', 'pt_BR', 'ar', 'hi', 'ja', 'ko', 'zh_Hans', 'he',
];

final class _AssetSource implements VerseDataSource {
  @override
  Future<Object?> load(String language) async {
    final File f = File('assets/verses/$language.json.gz');
    if (!f.existsSync()) return null;
    return jsonDecode(utf8.decode(gzip.decode(f.readAsBytesSync())));
  }
}

/// The smallest turning radius along the lap, in metres.
double _minRadius(Track track) {
  final TrackGeometry g = TrackGeometry.of(track);
  const double span = 10;
  double minimum = double.infinity;
  for (double s = 0; s < g.length; s += span) {
    final double turn = g.curvatureAhead(s, span).abs();
    if (turn > 1e-6) minimum = math.min(minimum, span / turn);
  }
  return minimum;
}

void main() {
  final List<Track> tracks = TrackCatalog.all;

  group('tracks', () {
    test('there are 16 tracks and 12 Now variants with the expected ids', () {
      expect(tracks.map((Track t) => t.id).toList(), TrackIds.all);
      expect(tracks.map((Track t) => t.id).toSet().length, 28);
      expect(tracks.where((Track t) => t.variant == TrackVariant.now).length, 12);
    });

    test('every track passes its own validation', () {
      for (final Track t in tracks) {
        expect(t.validate(), isEmpty, reason: t.id);
      }
    });

    test('numbers, eras and pursuit tracks match the design', () {
      for (final Track t in tracks) {
        expect(t.number, TrackIds.numberOf(t.id), reason: t.id);
        expect(t.era, Track.eraForNumber(t.number), reason: t.id);
      }
      expect(
        tracks.where((Track t) => t.pursuit).map((Track t) => t.id).toList(),
        <String>['red_sea_crossing', 'babylon_gates'],
      );
    });

    test('a Now variant keeps its Then geometry on tarmac', () {
      for (final Track then in tracks.take(12)) {
        final Track now = TrackCatalog.byId(TrackIds.nowVariantOf(then.id))!;
        expect(now.centerline, then.centerline, reason: then.id);
        expect(now.baseSurface.name, 'asphalt');
        expect(now.surfaceZones, isEmpty);
        expect(now.pursuit, isFalse);
      }
    });

    test('lengths, widths and corners are drivable', () {
      for (final Track t in tracks) {
        final TrackGeometry g = TrackGeometry.of(t);
        expect(g.length, inInclusiveRange(900, 2200), reason: t.id);
        expect(t.widths.reduce(math.min), greaterThanOrEqualTo(10), reason: t.id);
        expect(_minRadius(t), greaterThanOrEqualTo(36), reason: t.id);
      }
    });

    test('the Journey gets harder: later tracks are longer on average', () {
      final List<Track> j = TrackCatalog.journey;
      double mean(List<Track> ts) =>
          ts.map((Track t) => TrackGeometry.of(t).length).reduce((double a, double b) => a + b) / ts.length;
      expect(mean(j.sublist(12)), greaterThan(mean(j.sublist(0, 4))));
    });

    test('par lap times are sensible and stable', () {
      for (final Track t in tracks) {
        expect(t.parLapSeconds, inInclusiveRange(30, 110), reason: t.id);
        expect(
          t.parLapSeconds,
          closeTo(ParEstimator.lapSeconds(t, VehicleCatalog.journeyDefault(t)), 0.06),
          reason: t.id,
        );
      }
    });

    test('lookups work', () {
      expect(TrackCatalog.byId('appian_way')!.number, 12);
      expect(TrackCatalog.byId('nope'), isNull);
      expect(TrackCatalog.journey.length, 16);
    });
  });

  group('vehicles', () {
    test('six vehicles with matching ids and unique kinds', () {
      expect(VehicleCatalog.all.map((Vehicle v) => v.id).toList(), VehicleIds.all);
      expect(VehicleCatalog.all.map((Vehicle v) => v.kind).toSet().length, 6);
      for (final VehicleKind k in VehicleKind.values) {
        expect(VehicleCatalog.forKind(k).kind, k);
      }
    });

    test('handling follows the design', () {
      expect(VehicleCatalog.lightChariot.acceleration, greaterThan(VehicleCatalog.heavyChariot.acceleration));
      expect(VehicleCatalog.heavyChariot.massKg, greaterThan(VehicleCatalog.lightChariot.massKg));
      expect(VehicleCatalog.heavyChariot.boost.durationSeconds, greaterThan(VehicleCatalog.lightChariot.boost.durationSeconds));
      expect(VehicleCatalog.heavyChariot.boost.topSpeedMultiplier, lessThan(VehicleCatalog.lightChariot.boost.topSpeedMultiplier));
      expect(VehicleCatalog.roadster.maxSpeed, greaterThan(VehicleCatalog.hatch.maxSpeed));
      expect(VehicleCatalog.hatch.grip, greaterThan(VehicleCatalog.roadster.grip));
      expect(VehicleCatalog.hatch.grip, greaterThan(VehicleCatalog.lightChariot.grip));
      expect(VehicleCatalog.all.where((Vehicle v) => v.canDrift).map((Vehicle v) => v.kind).toList(), <VehicleKind>[VehicleKind.roadster]);
      expect(VehicleCatalog.utility4x4.grip, greaterThan(1));
    });

    test('the Journey default suits the track', () {
      expect(VehicleCatalog.journeyDefault(TrackCatalog.byId('nile_banks')!).id, VehicleIds.lightChariot);
      expect(VehicleCatalog.journeyDefault(TrackCatalog.byId('galilee_shore')!).id, VehicleIds.roadCart);
      expect(VehicleCatalog.journeyDefault(TrackCatalog.byId('coast_highway')!).id, VehicleIds.hatch);
      expect(VehicleCatalog.journeyDefault(TrackCatalog.byId('nile_banks_now')!).id, VehicleIds.hatch);
    });
  });

  group('rivals', () {
    test('at least ten distinct fictional drivers', () {
      expect(RivalCatalog.all.length, greaterThanOrEqualTo(10));
      expect(RivalCatalog.all.map((Rival r) => r.id).toSet().length, RivalCatalog.all.length);
      expect(RivalCatalog.all.map((Rival r) => r.name).toSet().length, RivalCatalog.all.length);
      expect(RivalCatalog.all.map((Rival r) => r.skill).reduce(math.min), lessThan(0.45));
      expect(RivalCatalog.all.map((Rival r) => r.skill).reduce(math.max), greaterThan(0.75));
    });
  });

  group('verse moments', () {
    final VerseRepository repo = VerseRepository(_AssetSource());

    test('every track and upgrade verse exists in all 11 languages with the right tag', () async {
      for (final String l in _languages) {
        final VerseBundle b = await repo.bundle(l);
        for (final VerseRef ref in VerseMoments.allTrackIntro) {
          final Verse? v = b.byRef(ref);
          expect(v, isNotNull, reason: '$l ${ref.key}');
          expect(v!.moments.contains(VerseMoment.trackIntro), isTrue, reason: '$l ${ref.key}');
        }
        for (final VerseRef ref in VerseMoments.allUpgrade) {
          final Verse? v = b.byRef(ref);
          expect(v, isNotNull, reason: '$l ${ref.key}');
          expect(v!.moments.contains(VerseMoment.upgrade), isTrue, reason: '$l ${ref.key}');
        }
      }
    });

    test('track intro verses are all different and a Now track shares its Then verse', () {
      expect(VerseMoments.allTrackIntro.map((VerseRef r) => r.key).toSet().length, 16);
      expect(VerseMoments.trackIntro('appian_way_now'), VerseMoments.trackIntro('appian_way'));
      expect(VerseMoments.trackIntro('nonsense'), isNull);
      expect(VerseMoments.allUpgrade.length, UpgradeKind.values.length);
    });
  });

  group('every track can be finished', () {
    for (final Track track in tracks) {
      test(track.id, () {
        final Vehicle vehicle = VehicleCatalog.journeyDefault(track);
        final RaceConfig config = RaceConfig(
          track: track,
          vehicle: vehicle,
          mode: RaceMode.quickRace,
          laps: 1,
          difficulty: Difficulty.normal,
          seed: 7,
          rivals: RivalCatalog.all.take(5).toList(),
        );
        final RaceSimulation sim = RaceSimulation(config: config, controllers: AiDriver.forRace(config));
        int guard = 0;
        while (sim.phase != RacePhase.finished && guard < 60 * 400) {
          sim.step(follow(sim, sim.player));
          guard++;
        }
        expect(sim.phase, RacePhase.finished);
        final double? time = sim.player.tracker.finishSeconds;
        expect(time, isNotNull, reason: 'the player must finish');
        expect(time!, lessThan(track.parLapSeconds * 2.2), reason: 'player ${time.toStringAsFixed(1)} s, par ${track.parLapSeconds}');
        // The race ends when the player finishes, so rivals are only checked
        // for being on the move: none may be stuck far behind.
        final double lap = TrackGeometry.of(track).length;
        for (final RaceCar car in sim.cars.where((RaceCar c) => !c.isPlayer)) {
          expect(car.progress, greaterThan(lap * 0.5), reason: '${car.rival?.id} got stuck on ${track.id}');
        }
      });
    }
  });
}
