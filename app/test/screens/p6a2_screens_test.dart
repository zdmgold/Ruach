import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/catalog/rivals.dart';
import 'package:ruach/core/catalog/tracks.dart';
import 'package:ruach/core/catalog/vehicles.dart';
import 'package:ruach/core/logic/catalog_ids.dart';
import 'package:ruach/core/logic/milestone_rules.dart';
import 'package:ruach/core/logic/mode_rules.dart';
import 'package:ruach/core/logic/race_rules.dart';
import 'package:ruach/core/models/drive_input.dart';
import 'package:ruach/core/models/progress.dart';
import 'package:ruach/core/models/race_config.dart';
import 'package:ruach/core/models/settings.dart';
import 'package:ruach/core/models/vehicle.dart';
import 'package:ruach/providers/race_provider.dart';
import 'package:ruach/screens/daily_run_screen.dart';
import 'package:ruach/screens/garage_screen.dart';
import 'package:ruach/screens/home_screen.dart';
import 'package:ruach/screens/result_screen.dart';
import 'package:ruach/screens/routes.dart';
import 'package:ruach/screens/track_intro_screen.dart';
import 'package:ruach/screens/track_list_screen.dart';
import 'package:ruach/widgets/app_switch.dart';
import 'package:ruach/widgets/vehicle_picker.dart';

import '../support/fakes.dart';
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
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('Daily Run screen', () {
    testWidgets('shows the setup, the verse of the day, and Start opens the track intro', (WidgetTester tester) async {
      _size(tester);
      final TestScope s = TestScope();
      await tester.pumpWidget(s.app(const DailyRunScreen()));
      await tester.pumpAndSettle();

      expect(find.text("TODAY'S SETUP"), findsOneWidget);
      expect(find.text('No tries yet today'), findsOneWidget);
      expect(find.text('The LORD is my shepherd.'), findsOneWidget);

      await tester.tap(find.text("Start today's run"));
      await tester.pumpAndSettle();
      expect(s.pushed.last.$1, Routes.trackIntro);
      final TrackIntroArgs args = s.pushed.last.$2! as TrackIntroArgs;
      expect(args.mode, RaceMode.dailyRun);
      expect(args.trackId, s.daily.challenge.trackId);
    });

    testWidgets('after a try it counts it and offers another', (WidgetTester tester) async {
      _size(tester);
      final TestScope s = TestScope();
      await s.daily.startAttempt();
      await tester.pumpWidget(s.app(const DailyRunScreen()));
      await tester.pumpAndSettle();

      expect(find.text('1 try today'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('the reminder switch turns the reminder on', (WidgetTester tester) async {
      _size(tester);
      final TestScope s = TestScope();
      await tester.pumpWidget(s.app(const DailyRunScreen()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byType(AppSwitch));
      await tester.tap(find.byType(AppSwitch));
      await tester.pumpAndSettle();
      expect(s.settings.value.remindersEnabled, isTrue);
      expect(s.notifications.calls, contains('schedule 18:0'));
    });

    testWidgets('a refused permission leaves the reminder off and says why', (WidgetTester tester) async {
      _size(tester);
      final TestScope s = TestScope()..notifications.permitted = false;
      await tester.pumpWidget(s.app(const DailyRunScreen()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byType(AppSwitch));
      await tester.tap(find.byType(AppSwitch));
      await tester.pumpAndSettle();
      expect(s.settings.value.remindersEnabled, isFalse);
      expect(find.textContaining('Notifications are off'), findsOneWidget);
    });
  });

  group('Welcome back', () {
    testWidgets('shows once on Home after missed days, then not again that day', (WidgetTester tester) async {
      _size(tester);
      final TestScope s = TestScope();
      await s.progress.change((Progress p) => p.copyWith(lastDailyDate: '2026-11-18', currentStreak: 4));
      await tester.pumpWidget(s.app(const HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('The LORD is my shepherd.'), findsOneWidget);
      expect(s.progress.value.welcomeBackShownOn, '2026-11-23');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(s.app(const HomeScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Welcome back'), findsNothing);
    });

    testWidgets('does not show when no day was missed', (WidgetTester tester) async {
      _size(tester);
      final TestScope s = TestScope();
      await s.progress.change((Progress p) => p.copyWith(lastDailyDate: '2026-11-22', currentStreak: 4));
      await tester.pumpWidget(s.app(const HomeScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Welcome back'), findsNothing);
    });
  });

  group('Milestone cards', () {
    testWidgets('the Garage shows the first-Gift card once and remembers it', (WidgetTester tester) async {
      _size(tester);
      final TestScope s = TestScope();
      await s.progress.change((Progress p) => p.copyWith(giftsSpent: 1));
      await tester.pumpWidget(s.app(const GarageScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Your first Gift is spent'), findsOneWidget);
      expect(s.progress.value.milestonesSeen, contains(Milestones.firstGiftSpent));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(s.app(const GarageScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Your first Gift is spent'), findsNothing);
    });

    testWidgets('the result screen shows a milestone only after the race is saved', (WidgetTester tester) async {
      _size(tester);
      final TestScope s = TestScope();
      await s.progress.change((Progress p) => p.copyWith(giftsSpent: 1));
      s.race.start(_config(RaceMode.quickRace));
      _finishWin(s.race);
      await tester.pumpWidget(s.app(const ResultScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Your first Gift is spent'), findsOneWidget);
    });
  });

  group('Rating prompt', () {
    Future<FakeReview> finish(WidgetTester tester, TestScope s, {required int racesBefore, bool win = true}) async {
      final FakeReview review = FakeReview();
      await s.progress.change((Progress p) => p.copyWith(racesFinished: racesBefore));
      s.race.start(_config(RaceMode.quickRace));
      if (win) {
        _finishWin(s.race);
      } else {
        // Nothing finishes: the player is not on the podium.
        final RaceSimulation sim = s.race.simulation!;
        for (int i = 0; i < 20; i++) {
          sim.step(DriveInput.idle);
        }
        s.race.advance(0.02, DriveInput.idle);
      }
      await tester.pumpWidget(s.app(ResultScreen(onRequestReview: review.requestReview)));
      for (int i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 800));
      }
      return review;
    }

    testWidgets('asks once after a podium finish with enough races', (WidgetTester tester) async {
      _size(tester);
      final TestScope s = TestScope();
      final FakeReview review = await finish(tester, s, racesBefore: 2);
      expect(review.requests, 1);
      expect(s.progress.value.reviewAsked, isTrue);
    });

    testWidgets('does not ask too early', (WidgetTester tester) async {
      _size(tester);
      final TestScope s = TestScope();
      final FakeReview review = await finish(tester, s, racesBefore: 0);
      expect(review.requests, 0);
      expect(s.progress.value.reviewAsked, isFalse);
    });
  });

  group('Time Trial ghost toggle', () {
    testWidgets('is shown on the Time Trial list and changes the setting', (WidgetTester tester) async {
      _size(tester);
      final TestScope s = TestScope();
      await s.progress.change((Progress p) => p.copyWith(stars: <String, int>{TrackIds.journey.first: 1}));
      await tester.pumpWidget(s.app(const TrackListScreen(mode: RaceMode.timeTrial)));
      await tester.pumpAndSettle();

      expect(find.text('Show my best-lap ghost'), findsWidgets);
      expect(s.settings.value.ghostEnabled, isTrue);
      await tester.tap(find.byType(AppSwitch));
      await tester.pumpAndSettle();
      expect(s.settings.value.ghostEnabled, isFalse);
    });

    testWidgets('is not on the Quick Race list', (WidgetTester tester) async {
      _size(tester);
      final TestScope s = TestScope();
      await s.progress.change((Progress p) => p.copyWith(stars: <String, int>{TrackIds.journey.first: 1}));
      await tester.pumpWidget(s.app(const TrackListScreen(mode: RaceMode.quickRace)));
      await tester.pumpAndSettle();
      expect(find.byType(AppSwitch), findsNothing);
    });
  });

  group('Vehicle picker on the track intro', () {
    testWidgets('picks an owned vehicle for a free race', (WidgetTester tester) async {
      _size(tester);
      final TestScope s = TestScope();
      await tester.pumpWidget(
        s.app(TrackIntroScreen(mode: RaceMode.quickRace, trackId: TrackIds.journey[0])),
      );
      await tester.pump();

      expect(find.byType(VehiclePicker), findsOneWidget);
      expect(s.garage.selected.kind, VehicleKind.lightChariot);
      await tester.tap(find.text('Heavy Chariot'));
      await tester.pumpAndSettle();
      expect(s.garage.selected.kind, VehicleKind.heavyChariot);
    });

    testWidgets('is not offered in the Daily Run, whose setup is fixed', (WidgetTester tester) async {
      _size(tester);
      final TestScope s = TestScope();
      await tester.pumpWidget(
        s.app(TrackIntroScreen(mode: RaceMode.dailyRun, trackId: s.daily.challenge.trackId)),
      );
      await tester.pump();
      expect(find.byType(VehiclePicker), findsNothing);
    });
  });

  test('the settings default shows the ghost', () {
    expect(const Settings().ghostEnabled, isTrue);
  });
}
