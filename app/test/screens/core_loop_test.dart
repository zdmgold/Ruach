import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/logic/catalog_ids.dart';
import 'package:ruach/core/models/progress.dart';
import 'package:ruach/core/models/race_config.dart';
import 'package:ruach/core/models/upgrade.dart';
import 'package:ruach/screens/garage_screen.dart';
import 'package:ruach/screens/home_screen.dart';
import 'package:ruach/screens/routes.dart';

import '../support/scope_host.dart';

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

    testWidgets('the daily card opens that day\'s track in Daily Run mode', (WidgetTester tester) async {
      await _size(tester);
      final TestScope s = TestScope();
      await tester.pumpWidget(s.app(const HomeScreen()));
      await tester.pump();

      await tester.tap(find.text('Daily Run'));
      await tester.pumpAndSettle();

      expect(s.pushed.last.$1, Routes.trackIntro);
      final TrackIntroArgs args = s.pushed.last.$2! as TrackIntroArgs;
      expect(args.mode, RaceMode.dailyRun);
      expect(args.trackId, s.daily.challenge.trackId);
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
}
