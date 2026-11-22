import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/catalog/rivals.dart';
import 'package:ruach/core/catalog/tracks.dart';
import 'package:ruach/core/catalog/vehicles.dart';
import 'package:ruach/core/logic/mode_rules.dart';
import 'package:ruach/core/logic/progress_codec.dart';
import 'package:ruach/core/models/drive_input.dart';
import 'package:ruach/core/models/race_config.dart';
import 'package:ruach/game/race_game.dart';
import 'package:ruach/game/vehicle_component.dart';
import 'package:ruach/providers/progress_provider.dart';
import 'package:ruach/providers/race_provider.dart';

import '../support/fakes.dart';

RaceConfig _config(int index) => ModeRules.build(
      mode: RaceMode.quickRace,
      track: TrackCatalog.journey[index],
      vehicle: VehicleCatalog.journeyDefault(TrackCatalog.journey[index]),
      roster: RivalCatalog.all,
      seed: 11,
    );

void main() {
  testWidgets('the game draws a started race and follows the player', (WidgetTester tester) async {
    final RaceProvider race = RaceProvider(ProgressProvider(ProgressRepository(FakeFileStore())));
    int reads = 0;
    final RaceGame game = RaceGame(
      race: race,
      readInput: (double dt) {
        reads++;
        return const DriveInput(throttle: 1);
      },
    );
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(width: 360, height: 640, child: GameWidget<RaceGame>(game: game)),
    ));
    await tester.pump();
    await tester.pump();
    race.start(_config(0));
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(reads, greaterThan(0));
    expect(game.view.vehicleCount, 6);
    expect(game.view.renderer, isNotNull);
    expect(race.simulation!.raceTick, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('starting another race rebuilds the world for the new track', (WidgetTester tester) async {
    final RaceProvider race = RaceProvider(ProgressProvider(ProgressRepository(FakeFileStore())));
    final RaceGame game = RaceGame(race: race, readInput: (double dt) => DriveInput.idle);
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(width: 360, height: 640, child: GameWidget<RaceGame>(game: game)),
    ));
    await tester.pump();
    await tester.pump();
    race.start(_config(0));
    await tester.pump(const Duration(milliseconds: 50));
    final Object? first = game.view.renderer;
    race.start(_config(3));
    await tester.pump(const Duration(milliseconds: 50));
    expect(identical(first, game.view.renderer), isFalse);
    expect(game.view.vehicleCount, 6);
  });

  testWidgets('a paused race is not advanced', (WidgetTester tester) async {
    final RaceProvider race = RaceProvider(ProgressProvider(ProgressRepository(FakeFileStore())));
    int reads = 0;
    final RaceGame game = RaceGame(race: race, readInput: (double dt) {
      reads++;
      return DriveInput.idle;
    });
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(width: 360, height: 640, child: GameWidget<RaceGame>(game: game)),
    ));
    await tester.pump();
    await tester.pump();
    race.start(_config(0));
    race.pause();
    await tester.pump(const Duration(milliseconds: 200));
    expect(reads, 0);
  });

  test('team colours are stable and every vehicle kind has a size', () {
    expect(VehicleArt.teamColor('Team A'), VehicleArt.teamColor('Team A'));
    for (final kind in VehicleCatalog.all.map((v) => v.kind)) {
      final (double l, double w) = VehicleArt.sizeOf(kind);
      expect(l, greaterThan(w));
    }
  });
}
