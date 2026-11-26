import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/catalog/rivals.dart';
import 'package:ruach/core/catalog/tracks.dart';
import 'package:ruach/core/catalog/vehicles.dart';
import 'package:ruach/core/logic/mode_rules.dart';
import 'package:ruach/core/logic/race_rules.dart';
import 'package:ruach/core/models/drive_input.dart';
import 'package:ruach/core/models/race_config.dart';
import 'package:ruach/core/ports/device_ports.dart';
import 'package:ruach/providers/feedback_provider.dart';
import 'package:ruach/screens/home_screen.dart';
import 'package:ruach/screens/result_screen.dart';
import 'package:ruach/widgets/gift_badge.dart';
import 'package:ruach/widgets/star_badge.dart';

import '../core/logic/test_support.dart' show follow;
import '../support/fakes.dart';
import '../support/scope_host.dart';

RaceConfig _config() => ModeRules.build(
      mode: RaceMode.journey,
      track: TrackCatalog.journey.first,
      vehicle: VehicleCatalog.journeyDefault(TrackCatalog.journey.first),
      roster: RivalCatalog.all,
      seed: 7,
      laps: 1,
    );

void _finishWin(TestScope s) {
  s.race.start(_config());
  final RaceSimulation sim = s.race.simulation!;
  for (int i = 0; i < 200; i++) {
    sim.step(DriveInput.idle);
  }
  sim.player.tracker.forceFinish(sim.elapsedSeconds);
  sim.step(DriveInput.idle);
  s.race.advance(0.02, DriveInput.idle);
}

Future<void> _size(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

int _stars(WidgetTester tester) => tester.widget<StarBadge>(find.byType(StarBadge)).stars;

int _gifts(WidgetTester tester) => tester.widget<GiftBadge>(find.byType(GiftBadge)).count;

void main() {
  group('Result celebration', () {
    testWidgets('stars appear one by one with a sound and a touch, then Gifts count up', (WidgetTester tester) async {
      await _size(tester);
      final TestScope s = TestScope();
      final FakeAudio audio = FakeAudio();
      final FakeHaptics haptics = FakeHaptics();
      _finishWin(s);
      await tester.pumpWidget(
        s.app(ResultScreen(feedback: FeedbackProvider(s.settings, audio: audio, haptics: haptics))),
      );
      await tester.pump();
      await tester.pump();
      expect(_stars(tester), 0);

      await tester.pump(ResultScreen.starStep);
      expect(_stars(tester), 1);
      await tester.pump(ResultScreen.starStep);
      expect(_stars(tester), 2);
      await tester.pump(ResultScreen.starStep);
      expect(_stars(tester), 3);
      expect(audio.played.where((SoundEffect e) => e == SoundEffect.star).length, 3);
      expect(haptics.played.where((HapticKind k) => k == HapticKind.light).length, 3);

      await tester.pump(ResultScreen.starStep);
      await tester.pump(ResultScreen.giftStep * 5);
      expect(_gifts(tester), 3);
      expect(audio.played, contains(SoundEffect.gift));
    });

    testWidgets('spoken labels carry the final values from the start', (WidgetTester tester) async {
      await _size(tester);
      final TestScope s = TestScope();
      _finishWin(s);
      await tester.pumpWidget(s.app(const ResultScreen()));
      await tester.pump();
      await tester.pump();
      expect(tester.widget<StarBadge>(find.byType(StarBadge)).semanticLabel, '3 of 3 stars');
      await tester.pump(ResultScreen.starStep * 6);
    });

    testWidgets('Reduce Motion shows the final result at once', (WidgetTester tester) async {
      await _size(tester);
      final TestScope s = TestScope();
      _finishWin(s);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 1400), disableAnimations: true),
          child: s.app(const ResultScreen()),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(_stars(tester), 3);
      expect(_gifts(tester), 3);
    });

    testWidgets('a quicker lap than the saved best is called out', (WidgetTester tester) async {
      await _size(tester);
      final TestScope s = TestScope();
      await s.progress.change(
        (p) => p.copyWith(bestLapMillis: <String, int>{TrackCatalog.journey.first.id: 999999}),
      );
      s.race.start(_config());
      final RaceSimulation sim = s.race.simulation!;
      for (int i = 0; i < 100000 && sim.phase != RacePhase.finished; i++) {
        sim.step(follow(sim, sim.player));
      }
      s.race.advance(0.02, DriveInput.idle);
      await tester.pumpWidget(s.app(const ResultScreen()));
      await tester.pump();
      await tester.pump();
      expect(find.text('New best lap'), findsOneWidget);
      await tester.pump(ResultScreen.starStep * 6);
    });
  });

  group('Remove ads link', () {
    testWidgets('shows only with a banner the ad rules allow', (WidgetTester tester) async {
      await _size(tester);
      final TestScope s = TestScope();
      await tester.pumpWidget(s.app(HomeScreen(banner: const SizedBox(width: 320, height: 50))));
      await tester.pump();
      expect(find.text('Remove ads'), s.ads.bannersAllowed ? findsOneWidget : findsNothing);
    });

    testWidgets('is absent when ads are removed', (WidgetTester tester) async {
      await _size(tester);
      final TestScope s = TestScope();
      s.billing.owns = true;
      await s.entitlement.refresh();
      await tester.pumpWidget(s.app(HomeScreen(banner: const SizedBox(width: 320, height: 50))));
      await tester.pump();
      expect(find.text('Remove ads'), findsNothing);
    });
  });
}
