import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/catalog/rivals.dart';
import 'package:ruach/core/catalog/tracks.dart';
import 'package:ruach/core/catalog/vehicles.dart';
import 'package:ruach/core/logic/catalog_ids.dart';
import 'package:ruach/core/logic/mode_rules.dart';
import 'package:ruach/core/logic/race_rules.dart';
import 'package:ruach/core/models/drive_input.dart';
import 'package:ruach/core/models/progress.dart';
import 'package:ruach/core/models/race_config.dart';
import 'package:ruach/core/models/upgrade.dart';
import 'package:ruach/providers/race_provider.dart';
import 'package:ruach/screens/garage_screen.dart';
import 'package:ruach/screens/home_screen.dart';
import 'package:ruach/screens/race_screen.dart';
import 'package:ruach/screens/result_screen.dart';
import 'package:ruach/screens/routes.dart';
import 'package:ruach/screens/track_intro_screen.dart';

import '../support/scope_host.dart';

RaceConfig _config(RaceMode mode, {int laps = 1}) => ModeRules.build(
      mode: mode,
      track: TrackCatalog.journey.first,
      vehicle: VehicleCatalog.journeyDefault(TrackCatalog.journey.first),
      roster: RivalCatalog.all,
      seed: 7,
      laps: mode == RaceMode.escapeRun ? null : laps,
    );

void _finishWin(RaceProvider race) {
  final RaceSimulation sim = race.simulation!;
  for (int i = 0; i < 200; i++) {
    sim.step(DriveInput.idle);
  }
  sim.player.tracker.forceFinish(sim.elapsedSeconds);
  sim.step(DriveInput.idle);
  race.advance(0.02, DriveInput.idle);
}

Future<void> _size(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('HomeScreen', () {
    testWidgets('shows the daily run, journey and garage, with later modes locked', (WidgetTester tester) async {
      await _size(tester);
      final TestScope s = TestScope();
      await tester.pumpWidget(s.app(const HomeScreen()));
      await tester.pump();

      expect(find.text('Daily Run'), findsOneWidget);
      expect(find.text('No streak yet'), findsOneWidget);
      expect(find.text('0 of 48 stars'), findsOneWidget);
      expect(find.text('Locked'), findsWidgets);
      expect(find.text('Time Trial'), findsOneWidget);
      expect(find.text('Escape Run'), findsOneWidget);
    });

    testWidgets('the daily card opens the Daily Run screen', (WidgetTester tester) async {
      await _size(tester);
      final TestScope s = TestScope();
      await tester.pumpWidget(s.app(const HomeScreen()));
      await tester.pump();

      await tester.tap(find.text('Daily Run'));
      await tester.pumpAndSettle();

      expect(s.pushed.last.$1, Routes.dailyRun);
    });

    testWidgets('a locked mode does nothing; clearing track 1 opens Quick Race', (WidgetTester tester) async {
      await _size(tester);
      final TestScope s = TestScope();
      await tester.pumpWidget(s.app(const HomeScreen()));
      await tester.pump();

      await tester.tap(find.text('Time Trial'));
      await tester.pump();
      expect(s.pushed, isEmpty);

      await s.progress.awardStars(TrackIds.journey[0], 2);
      await tester.pump();
      await tester.tap(find.text('Pick any unlocked track'));
      await tester.pumpAndSettle();
      expect((s.pushed.last.$2! as ModeArgs).mode, RaceMode.quickRace);
    });

    testWidgets('the banner shows only while the ad rules allow one', (WidgetTester tester) async {
      await _size(tester);
      final TestScope s = TestScope();
      const Key banner = Key('banner');
      await tester.pumpWidget(s.app(const HomeScreen(banner: SizedBox(key: banner, width: 320, height: 50))));
      await tester.pump();
      expect(find.byKey(banner), s.ads.bannersAllowed ? findsOneWidget : findsNothing);
    });
  });

  group('GarageScreen', () {
    testWidgets('lists vehicles and the six upgrades, with later vehicles locked', (WidgetTester tester) async {
      await _size(tester);
      final TestScope s = TestScope();
      await tester.pumpWidget(s.app(const GarageScreen()));
      await tester.pump();

      expect(find.text('Light Chariot'), findsOneWidget);
      expect(find.text('In use'), findsOneWidget);
      expect(find.text('Opens with track 9'), findsWidgets);
      expect(find.text('Wisdom'), findsOneWidget);
      expect(find.text('Fear of the LORD'), findsOneWidget);
    });

    testWidgets('choosing another vehicle moves "In use"', (WidgetTester tester) async {
      await _size(tester);
      final TestScope s = TestScope();
      await tester.pumpWidget(s.app(const GarageScreen()));
      await tester.pump();

      await tester.tap(find.text('Heavy Chariot'));
      await tester.pump();
      expect(s.garage.selected.id, VehicleIds.heavyChariot);
    });

    testWidgets('an upgrade can be bought with Gifts and not without', (WidgetTester tester) async {
      await _size(tester);
      final TestScope s = TestScope();
      await tester.pumpWidget(s.app(const GarageScreen()));
      await tester.pump();

      final int cost = s.garage.nextCost(UpgradeKind.wisdom)!;
      expect(find.text('Needs $cost Gifts'), findsWidgets);

      await s.progress.change((Progress p) => p.copyWith(giftsEarned: cost + 5));
      await tester.pump();
      await tester.tap(find.text('Upgrade for $cost').first);
      await tester.pump();

      expect(s.garage.levelOf(UpgradeKind.wisdom), 1);
      expect(s.garage.gifts, 5);
    });
  });

  group('TrackIntroScreen', () {
    testWidgets('shows the track and starts the race with a config for it', (WidgetTester tester) async {
      await _size(tester);
      final TestScope s = TestScope();
      await tester.pumpWidget(
        s.app(TrackIntroScreen(mode: RaceMode.quickRace, trackId: TrackIds.journey[0])),
      );
      await tester.pump();

      expect(find.text('Banks of the Nile'), findsOneWidget);
      expect(find.text('Chariot Age'), findsOneWidget);
      await tester.tap(find.text('Start race'));
      await tester.pumpAndSettle();

      expect(s.pushed.last.$1, Routes.race);
      final RaceArgs args = s.pushed.last.$2! as RaceArgs;
      expect(args.config.track.id, TrackIds.journey[0]);
      expect(args.config.mode, RaceMode.quickRace);
    });

    testWidgets('a second Daily attempt asks for a video, and stays put without one', (WidgetTester tester) async {
      await _size(tester);
      final TestScope s = TestScope();
      await s.daily.startAttempt();
      await tester.pumpWidget(
        s.app(TrackIntroScreen(mode: RaceMode.dailyRun, trackId: s.daily.challenge.trackId)),
      );
      await tester.pump();

      expect(find.text('Watch a short video for another try'), findsOneWidget);
      await tester.tap(find.text('Watch a short video for another try'));
      await tester.pumpAndSettle();
      expect(find.text('No video is available right now. Try again later.'), findsOneWidget);
      expect(s.pushed, isEmpty);
    });
  });

  group('RaceScreen', () {
    testWidgets('pauses to a menu, resumes, and quits after a confirmation', (WidgetTester tester) async {
      await _size(tester);
      final TestScope s = TestScope();
      await tester.pumpWidget(s.app(RaceScreen(args: RaceArgs(config: _config(RaceMode.quickRace)))));
      await tester.pump();
      expect(s.race.stage, RaceStage.running);

      s.race.pause();
      await tester.pump();
      expect(find.text('Paused'), findsOneWidget);

      await tester.tap(find.text('Resume'));
      await tester.pump();
      expect(s.race.stage, RaceStage.running);
      expect(find.text('Paused'), findsNothing);

      s.race.pause();
      await tester.pump();
      await tester.tap(find.text('Quit race'));
      await tester.pump();
      expect(find.text('Quit this race? Your progress in it will be lost.'), findsOneWidget);
      await tester.tap(find.text('Quit race'));
      await tester.pump();
      expect(s.race.stage, RaceStage.idle);
    });

    testWidgets('moves to the result when the race finishes', (WidgetTester tester) async {
      await _size(tester);
      final TestScope s = TestScope();
      await tester.pumpWidget(s.app(RaceScreen(args: RaceArgs(config: _config(RaceMode.quickRace)))));
      await tester.pump();

      _finishWin(s.race);
      await tester.pumpAndSettle();

      expect(s.pushed.last.$1, Routes.result);
    });
  });

  group('ResultScreen', () {
    testWidgets('saves the result once and shows stars, a verse and the next steps', (WidgetTester tester) async {
      await _size(tester);
      final TestScope s = TestScope();
      s.race.start(_config(RaceMode.journey));
      _finishWin(s.race);
      await tester.pumpWidget(s.app(const ResultScreen()));
      await tester.pumpAndSettle();

      expect(find.text('You won'), findsOneWidget);
      expect(s.progress.value.giftsEarned, 3);
      expect(s.progress.value.starsOn(TrackIds.journey[0]), 3);
      expect(find.text('The LORD is my shepherd.'), findsOneWidget);
      expect(find.text('Next track'), findsOneWidget);
      expect(find.text('Race again'), findsOneWidget);

      await tester.tap(find.text('Next track'));
      await tester.pumpAndSettle();
      final TrackIntroArgs args = s.pushed.last.$2! as TrackIntroArgs;
      expect(args.trackId, TrackIds.journey[1]);
      expect(args.mode, RaceMode.journey);
    });

    testWidgets('Race again returns to the track intro in the same mode', (WidgetTester tester) async {
      await _size(tester);
      final TestScope s = TestScope();
      s.race.start(_config(RaceMode.quickRace));
      _finishWin(s.race);
      await tester.pumpWidget(s.app(const ResultScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Next track'), findsNothing);
      await tester.tap(find.text('Race again'));
      await tester.pumpAndSettle();
      final TrackIntroArgs args = s.pushed.last.$2! as TrackIntroArgs;
      expect(args.mode, RaceMode.quickRace);
      expect(args.trackId, TrackIds.journey[0]);
    });
  });
}
