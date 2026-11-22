import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/catalog/rivals.dart';
import 'package:ruach/core/catalog/tracks.dart';
import 'package:ruach/core/catalog/vehicles.dart';
import 'package:ruach/core/logic/input_strategy.dart';
import 'package:ruach/core/logic/mode_rules.dart';
import 'package:ruach/core/logic/progress_codec.dart';
import 'package:ruach/core/models/drive_input.dart';
import 'package:ruach/core/models/race_config.dart';
import 'package:ruach/core/models/settings.dart';
import 'package:ruach/game/hud_layer.dart';
import 'package:ruach/game/input_layer.dart';
import 'package:ruach/providers/progress_provider.dart';
import 'package:ruach/providers/race_provider.dart';
import 'package:ruach/theme/app_theme.dart';
import 'package:ruach/theme/icons.dart';

import '../support/fakes.dart';

HudLabels get _labels => HudLabels(
      position: (int p, int f) => '$p/$f',
      lap: (int l, int n) => 'L$l/$n',
      boost: 'Ruach',
      boostValue: (int s, int t) => '$s of $t segments',
      go: 'Go',
      escapeDistance: (int m) => '$m m',
      pause: 'Pause',
      minimap: 'Track map',
      positionSemantic: (int p, int f) => 'Position $p of $f',
      lapSemantic: (int l, int n) => 'Lap $l of $n',
      timeSemantic: (String t) => 'Time $t',
    );

const InputLabels _inputLabels = InputLabels(
  steerLeft: 'Steer left',
  steerRight: 'Steer right',
  brake: 'Brake',
  boost: 'Boost',
  tiltFallback: 'No tilt sensor, using buttons',
);

Widget _host(Widget child, {TextDirection dir = TextDirection.ltr, double scale = 1}) => Directionality(
      textDirection: dir,
      child: MediaQuery(
        data: MediaQueryData(size: const Size(360, 640), textScaler: TextScaler.linear(scale)),
        child: AppTheme(
          data: AppThemeData.light(),
          child: SizedBox(width: 360, height: 640, child: child),
        ),
      ),
    );

RaceProvider _race() => RaceProvider(ProgressProvider(ProgressRepository(FakeFileStore())));

void _start(RaceProvider race, RaceMode mode, {int track = 0}) {
  race.start(ModeRules.build(
    mode: mode,
    track: TrackCatalog.journey[track],
    vehicle: VehicleCatalog.journeyDefault(TrackCatalog.journey[track]),
    roster: RivalCatalog.all,
    seed: 3,
  ));
}

void main() {
  group('HudLayer', () {
    testWidgets('shows the countdown, then position, lap and time', (WidgetTester tester) async {
      final RaceProvider race = _race();
      _start(race, RaceMode.quickRace);
      await tester.pumpWidget(_host(HudLayer(race: race, labels: _labels, onPause: () {})));
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Ruach'), findsOneWidget);
      race.advance(3.2, DriveInput.idle);
      await tester.pump();
      expect(find.text('Go'), findsOneWidget);
      expect(find.textContaining('/6'), findsOneWidget);
      expect(find.text('L1/3'), findsOneWidget);
      expect(find.textContaining(':'), findsOneWidget);
    });

    testWidgets('the pause button calls back and has a spoken label', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final RaceProvider race = _race();
      _start(race, RaceMode.quickRace);
      int pauses = 0;
      await tester.pumpWidget(_host(HudLayer(race: race, labels: _labels, onPause: () => pauses++)));
      await tester.tap(find.byIcon(AppIcons.pause));
      expect(pauses, 1);
      expect(find.bySemanticsLabel('Pause'), findsOneWidget);
      expect(find.bySemanticsLabel('Track map'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('an Escape Run shows the distance and the danger bar', (WidgetTester tester) async {
      final RaceProvider race = _race();
      _start(race, RaceMode.escapeRun);
      await tester.pumpWidget(_host(HudLayer(race: race, labels: _labels, onPause: () {})));
      race.advance(3.2, DriveInput.idle);
      await tester.pump();
      expect(find.text('0 m'), findsOneWidget);
    });

    testWidgets('large text is capped so the HUD stays small, and it survives', (WidgetTester tester) async {
      final RaceProvider race = _race();
      _start(race, RaceMode.quickRace);
      race.advance(3.2, DriveInput.idle);
      await tester.pumpWidget(_host(HudLayer(race: race, labels: _labels, onPause: () {}), scale: 3));
      expect(tester.takeException(), isNull);
      final Text lap = tester.widget(find.text('L1/3'));
      final double rendered = tester.getSize(find.text('L1/3')).height;
      expect(rendered, lessThan((lap.style!.fontSize ?? 16) * 1.2 * 1.6));
    });

    testWidgets('right-to-left puts the position on the right and does not flip the minimap points', (WidgetTester tester) async {
      final RaceProvider race = _race();
      _start(race, RaceMode.quickRace);
      race.advance(3.2, DriveInput.idle);
      await tester.pumpWidget(_host(HudLayer(race: race, labels: _labels, onPause: () {}), dir: TextDirection.rtl));
      expect(tester.getCenter(find.text('L1/3')).dx, greaterThan(180));
      expect(tester.takeException(), isNull);
    });

    test('the minimap fits every track inside its square', () {
      for (final track in TrackCatalog.all) {
        final MinimapData d = MinimapData.of(track);
        for (final Offset o in d.outline) {
          expect(o.dx, inInclusiveRange(0, MinimapData.side), reason: track.id);
          expect(o.dy, inInclusiveRange(0, MinimapData.side), reason: track.id);
        }
      }
    });
  });

  group('InputLayer', () {
    InputController controller() => InputController(ButtonsStrategy());

    Future<void> pumpInput(
      WidgetTester tester,
      InputController c, {
      Settings settings = const Settings(),
      TextDirection dir = TextDirection.ltr,
      Stream<double>? tilt,
      bool tiltAvailable = true,
    }) {
      return tester.pumpWidget(_host(
        InputLayer(controller: c, settings: settings, labels: _inputLabels, tilt: tilt, tiltAvailable: tiltAvailable),
        dir: dir,
      ));
    }

    testWidgets('a button reacts when touched and releases when lifted', (WidgetTester tester) async {
      final InputController c = controller();
      await pumpInput(tester, c);
      final TestGesture g = await tester.startGesture(tester.getCenter(find.bySemanticsLabel('Steer left')));
      expect(c.left, isTrue);
      await g.up();
      expect(c.left, isFalse);
    });

    testWidgets('two fingers can steer and boost at once', (WidgetTester tester) async {
      final InputController c = controller();
      await pumpInput(tester, c);
      final TestGesture a = await tester.startGesture(tester.getCenter(find.bySemanticsLabel('Steer right')));
      final TestGesture b = await tester.startGesture(tester.getCenter(find.bySemanticsLabel('Boost')));
      expect(c.right && c.boost, isTrue);
      await a.up();
      expect(c.right, isFalse);
      expect(c.boost, isTrue);
      await b.up();
      expect(c.boost, isFalse);
    });

    testWidgets('every control is at least 72 square with 24 between them', (WidgetTester tester) async {
      await pumpInput(tester, controller());
      final Rect left = tester.getRect(find.bySemanticsLabel('Steer left'));
      final Rect right = tester.getRect(find.bySemanticsLabel('Steer right'));
      expect(left.width, greaterThanOrEqualTo(72));
      expect(left.height, greaterThanOrEqualTo(72));
      expect(right.left - left.right, 24);
    });

    testWidgets('left is on the left in right-to-left too', (WidgetTester tester) async {
      await pumpInput(tester, controller(), dir: TextDirection.rtl);
      expect(
        tester.getCenter(find.bySemanticsLabel('Steer left')).dx,
        lessThan(tester.getCenter(find.bySemanticsLabel('Steer right')).dx),
      );
    });

    testWidgets('right-handed play puts steering on the left and pedals on the right; left-handed mirrors it', (WidgetTester tester) async {
      await pumpInput(tester, controller());
      expect(tester.getCenter(find.bySemanticsLabel('Steer left')).dx, lessThan(180));
      expect(tester.getCenter(find.bySemanticsLabel('Boost')).dx, greaterThan(180));
      await pumpInput(tester, controller(), settings: const Settings(handedness: Handedness.left));
      expect(tester.getCenter(find.bySemanticsLabel('Steer left')).dx, greaterThan(180));
      expect(tester.getCenter(find.bySemanticsLabel('Boost')).dx, lessThan(180));
    });

    testWidgets('the one-handed layout stacks pedals above steering on one side', (WidgetTester tester) async {
      await pumpInput(tester, controller(), settings: const Settings(oneHandedLayout: true));
      final Offset boost = tester.getCenter(find.bySemanticsLabel('Boost'));
      final Offset steer = tester.getCenter(find.bySemanticsLabel('Steer right'));
      expect(boost.dy, lessThan(steer.dy));
      expect(boost.dx, greaterThan(180));
      expect(steer.dx, greaterThan(180));
    });

    testWidgets('drag-steer shows no steer buttons and follows the finger', (WidgetTester tester) async {
      final InputController c = InputController(DragSteerStrategy());
      await pumpInput(tester, c, settings: const Settings(controlScheme: ControlScheme.dragSteer));
      expect(find.bySemanticsLabel('Steer left'), findsNothing);
      final TestGesture g = await tester.startGesture(const Offset(300, 400));
      await g.moveBy(const Offset(10, 0));
      expect(c.dragSteer, greaterThan(0.5));
      await g.moveTo(const Offset(40, 400));
      expect(c.dragSteer, lessThan(-0.5));
      await g.up();
      expect(c.dragSteer, 0);
    });

    testWidgets('tilt feeds the controller; with no sensor it falls back to buttons with a notice', (WidgetTester tester) async {
      final StreamController<double> roll = StreamController<double>();
      final InputController c = InputController(ButtonsStrategy());
      await pumpInput(tester, c, settings: const Settings(controlScheme: ControlScheme.tilt), tilt: roll.stream);
      roll.add(0.4);
      await tester.pump();
      expect(c.tiltRadians, 0.4);
      expect(find.bySemanticsLabel('Steer left'), findsNothing);
      await pumpInput(tester, c, settings: const Settings(controlScheme: ControlScheme.tilt), tiltAvailable: false);
      expect(find.bySemanticsLabel('Steer left'), findsOneWidget);
      expect(find.text('No tilt sensor, using buttons'), findsOneWidget);
      await roll.close();
    });

    testWidgets('leaving the screen releases every control', (WidgetTester tester) async {
      final InputController c = controller();
      await pumpInput(tester, c);
      await tester.startGesture(tester.getCenter(find.bySemanticsLabel('Boost')));
      expect(c.boost, isTrue);
      await tester.pumpWidget(const SizedBox());
      expect(c.boost, isFalse);
    });

    test('the controller turns the snapshot into one DriveInput through its strategy', () {
      final InputController c = controller()..right = true;
      DriveInput last = DriveInput.idle;
      for (int i = 0; i < 30; i++) {
        last = c.read(1 / 60);
      }
      expect(last.steer, greaterThan(0));
      c.reset();
      expect(c.read(1 / 60).steer, 0);
    });
  });
}
