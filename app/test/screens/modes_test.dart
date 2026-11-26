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
import 'package:ruach/providers/race_provider.dart';
import 'package:ruach/screens/mode_screen.dart';
import 'package:ruach/screens/result_screen.dart';
import 'package:ruach/screens/routes.dart';
import 'package:ruach/screens/track_intro_screen.dart';

import '../support/scope_host.dart';

RaceConfig _config(RaceMode mode) => ModeRules.build(
      mode: mode,
      track: TrackCatalog.journey.first,
      vehicle: VehicleCatalog.journeyDefault(TrackCatalog.journey.first),
      roster: RivalCatalog.all,
      seed: 7,
      laps: 1,
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

void _size(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('Journey list', () {
    testWidgets('shows every track open, and a Then/Now switch', (WidgetTester tester) async {
      _size(tester);
      final TestScope s = TestScope();
      await tester.pumpWidget(s.app(const ModeScreen(mode: RaceMode.journey)));
      await tester.pump();

      expect(find.text('Banks of the Nile'), findsOneWidget);
      expect(find.text('Red Sea Crossing'), findsOneWidget);
      expect(find.text('Locked'), findsNothing);

      await tester.tap(find.text('Now'));
      await tester.pump();
      expect(find.text('Banks of the Nile (Now)'), findsOneWidget);
      expect(find.text('Banks of the Nile'), findsNothing);
    });

    testWidgets('a track starts a Journey race at once', (WidgetTester tester) async {
      _size(tester);
      final TestScope s = TestScope();
      await tester.pumpWidget(s.app(const ModeScreen(mode: RaceMode.journey)));
      await tester.pump();

      await tester.tap(find.text('Banks of the Nile'));
      await tester.pumpAndSettle();
      expect(s.pushed.last.$1, Routes.play);
      final PlayArgs args = s.pushed.last.$2! as PlayArgs;
      expect(args.mode, RaceMode.journey);
      expect(args.trackId, TrackIds.journey[0]);
    });
  });

  group('Track picker', () {
    testWidgets('lists every track, including the Now variants', (WidgetTester tester) async {
      _size(tester);
      final TestScope s = TestScope();
      await s.progress.awardStars(TrackIds.journey[0], 1);
      await tester.pumpWidget(s.app(const ModeScreen(mode: RaceMode.quickRace)));
      await tester.pump();

      expect(find.text('Banks of the Nile'), findsOneWidget);
      expect(find.text('Red Sea Crossing'), findsOneWidget);
      expect(find.text('Banks of the Nile (Now)'), findsOneWidget);
      expect(find.text('Sinai Wilderness'), findsOneWidget);
      expect(find.text('Locked'), findsNothing);
    });

    testWidgets('Time Trial shows the saved best lap', (WidgetTester tester) async {
      _size(tester);
      final TestScope s = TestScope();
      await s.progress.awardStars(TrackIds.journey[0], 1);
      await s.progress.change(
        (Progress p) => p.copyWith(bestLapMillis: <String, int>{TrackIds.journey[0]: 65000}),
      );
      await tester.pumpWidget(s.app(const ModeScreen(mode: RaceMode.timeTrial)));
      await tester.pump();

      expect(find.textContaining('Best lap'), findsOneWidget);
    });
  });

  group('Weekly Circuit', () {
    testWidgets('opens days up to today and tapping one starts that day', (WidgetTester tester) async {
      _size(tester);
      final TestScope s = TestScope(now: DateTime(2026, 11, 25, 12)); // Wednesday
      await tester.pumpWidget(s.app(const ModeScreen(mode: RaceMode.weeklyCircuit)));
      await tester.pump();

      expect(find.text('Opens later this week'), findsNWidgets(4));
      await tester.tap(find.text('Day 2'));
      await tester.pumpAndSettle();
      final TrackIntroArgs args = s.pushed.last.$2! as TrackIntroArgs;
      expect(args.mode, RaceMode.weeklyCircuit);
      expect(args.weeklyIndex, 1);
      expect(args.trackId, s.daily.week[1].trackId);
    });

    testWidgets('the intro hands the race its week slot and the day\'s fixed setup', (WidgetTester tester) async {
      _size(tester);
      final TestScope s = TestScope(now: DateTime(2026, 11, 25, 12));
      final String track = s.daily.week[2].trackId;
      await tester.pumpWidget(
        s.app(TrackIntroScreen(mode: RaceMode.weeklyCircuit, trackId: track, weeklyIndex: 2)),
      );
      await tester.pump();

      await tester.tap(find.text('Start race'));
      await tester.pumpAndSettle();
      final RaceArgs args = s.pushed.last.$2! as RaceArgs;
      expect(args.weekly!.index, 2);
      expect(args.weekly!.weekId, s.daily.weekId);
      expect(args.config.seed, s.daily.week[2].seed);
    });

    test('a finished race saves its time against its day, and a new week starts clean', () async {
      final TestScope s = TestScope(now: DateTime(2026, 11, 25, 12));
      s.race.start(_config(RaceMode.weeklyCircuit), weekly: WeeklySlot(s.daily.weekId, 1));
      _finishWin(s.race);
      await s.race.commit();

      expect(s.daily.weeklyTime(1), isNotNull);
      expect(s.daily.weeklyTime(0), isNull);
      expect(s.progress.value.weeklyCircuitWeek, s.daily.weekId);

      s.race.start(_config(RaceMode.weeklyCircuit), weekly: const WeeklySlot('2099-W01', 0));
      _finishWin(s.race);
      await s.race.commit();
      expect(s.progress.value.weeklyCircuitWeek, '2099-W01');
      expect(s.progress.value.weeklyCircuitMillis.keys, <String>['0']);
    });
  });

  group('Daily Run result', () {
    testWidgets('finishing a Daily Run completes it and shows the streak', (WidgetTester tester) async {
      _size(tester);
      final TestScope s = TestScope();
      s.race.start(_config(RaceMode.dailyRun));
      _finishWin(s.race);
      await tester.pumpWidget(s.app(const ResultScreen()));
      await tester.pumpAndSettle();

      expect(s.daily.completedToday, isTrue);
      expect(find.text('1 day streak'), findsOneWidget);
    });
  });
}
