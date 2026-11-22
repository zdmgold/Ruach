import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/catalog/rivals.dart';
import 'package:ruach/core/catalog/tracks.dart';
import 'package:ruach/core/catalog/vehicles.dart';
import 'package:ruach/core/logic/ghost.dart';
import 'package:ruach/core/logic/mode_rules.dart';
import 'package:ruach/core/logic/progress_codec.dart';
import 'package:ruach/core/models/drive_input.dart';
import 'package:ruach/core/models/progress.dart';
import 'package:ruach/core/models/race_config.dart';
import 'package:ruach/core/models/vec2.dart';
import 'package:ruach/game/effects.dart';
import 'package:ruach/game/race_game.dart';
import 'package:ruach/providers/progress_provider.dart';
import 'package:ruach/providers/race_provider.dart';

import '../support/fakes.dart';

RaceConfig _config(RaceMode mode) => ModeRules.build(
      mode: mode,
      track: TrackCatalog.journey.first,
      vehicle: VehicleCatalog.journeyDefault(TrackCatalog.journey.first),
      roster: RivalCatalog.all,
      seed: 5,
    );

Future<RaceGame> _run(WidgetTester tester, RaceProvider race, {required bool reduceMotion, int pumps = 80}) async {
  final RaceGame game = RaceGame(
    race: race,
    readInput: (double dt) => const DriveInput(throttle: 1),
    reduceMotion: reduceMotion,
  );
  await tester.pumpWidget(Directionality(
    textDirection: TextDirection.ltr,
    child: SizedBox(width: 360, height: 640, child: GameWidget<RaceGame>(game: game)),
  ));
  await tester.pump();
  await tester.pump();
  race.start(_config(RaceMode.quickRace));
  for (int i = 0; i < pumps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return game;
}

EffectsLayer _effects(RaceGame game) => game.view.children.whereType<EffectsLayer>().single;

void main() {
  testWidgets('cars on a dirt track kick up dust, within the particle cap', (WidgetTester tester) async {
    final RaceProvider race = RaceProvider(ProgressProvider(ProgressRepository(FakeFileStore())));
    final RaceGame game = await _run(tester, race, reduceMotion: false);
    final int alive = _effects(game).aliveCount;
    expect(alive, greaterThan(0));
    expect(alive, lessThanOrEqualTo(EffectsLayer.capacity));
  });

  testWidgets('Reduce Motion switches every particle off', (WidgetTester tester) async {
    final RaceProvider race = RaceProvider(ProgressProvider(ProgressRepository(FakeFileStore())));
    final RaceGame game = await _run(tester, race, reduceMotion: true);
    expect(_effects(game).aliveCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an Escape Run draws the dust wall without error', (WidgetTester tester) async {
    final RaceProvider race = RaceProvider(ProgressProvider(ProgressRepository(FakeFileStore())));
    final RaceGame game = RaceGame(race: race, readInput: (double dt) => const DriveInput(throttle: 1));
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(width: 360, height: 640, child: GameWidget<RaceGame>(game: game)),
    ));
    await tester.pump();
    await tester.pump();
    race.start(_config(RaceMode.escapeRun));
    for (int i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(race.escape, isNotNull);
    expect(tester.takeException(), isNull);
  });

  group('Time Trial ghost loading', () {
    test('a saved ghost is loaded for a Time Trial and not for other modes', () async {
      final ProgressProvider progress = ProgressProvider(ProgressRepository(FakeFileStore()));
      final String id = TrackCatalog.journey.first.id;
      final String text = GhostCodec.encode(GhostLap(
        lapSeconds: 30,
        positions: <Vec2>[for (int i = 0; i < 300; i++) Vec2(i.toDouble(), 0)],
        headings: <double>[for (int i = 0; i < 300; i++) 0.0],
      ));
      await progress.change((Progress p) => p.copyWith(ghosts: <String, String>{id: text}));
      final RaceProvider race = RaceProvider(progress);
      race.start(_config(RaceMode.timeTrial));
      expect(race.ghost, isNotNull);
      expect(race.ghost!.lapSeconds, closeTo(30, 0.001));
      race.start(_config(RaceMode.quickRace));
      expect(race.ghost, isNull);
    });

    test('a damaged saved ghost is ignored, not fatal', () async {
      final ProgressProvider progress = ProgressProvider(ProgressRepository(FakeFileStore()));
      final String id = TrackCatalog.journey.first.id;
      await progress.change((Progress p) => p.copyWith(ghosts: <String, String>{id: 'garbage'}));
      final RaceProvider race = RaceProvider(progress);
      race.start(_config(RaceMode.timeTrial));
      expect(race.ghost, isNull);
    });
  });
}
