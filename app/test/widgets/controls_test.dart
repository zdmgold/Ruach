import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/logic/input_strategy.dart';
import 'package:ruach/theme/app_theme.dart';
import 'package:ruach/utils/formatters.dart';
import 'package:ruach/widgets/app_segmented.dart';
import 'package:ruach/widgets/app_slider.dart';
import 'package:ruach/widgets/app_switch.dart';

Widget _host(Widget child, {TextDirection dir = TextDirection.ltr}) => Directionality(
      textDirection: dir,
      child: AppTheme(
        data: AppThemeData.light(),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 300, child: child),
        ),
      ),
    );

void main() {
  testWidgets('a switch reports the opposite value when tapped and is spoken as toggled', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    bool? changed;
    await tester.pumpWidget(
      _host(AppSwitch(value: false, onChanged: (bool v) => changed = v, semanticLabel: 'Music')),
    );

    expect(find.bySemanticsLabel('Music'), findsOneWidget);
    await tester.tap(find.byType(AppSwitch));
    expect(changed, isTrue);
    handle.dispose();
  });

  testWidgets('a switch with no handler does nothing', (WidgetTester tester) async {
    await tester.pumpWidget(_host(const AppSwitch(value: true, onChanged: null, semanticLabel: 'x')));
    await tester.tap(find.byType(AppSwitch));
    // No exception and nothing to observe: the control is inert.
    expect(find.byType(AppSwitch), findsOneWidget);
  });

  testWidgets('a slider snaps to its steps when tapped or dragged', (WidgetTester tester) async {
    double value = 0;
    await tester.pumpWidget(
      _host(
        AppSlider(
          value: value,
          divisions: 4,
          onChanged: (double v) => value = v,
          semanticLabel: 'Volume',
          valueLabel: '0%',
        ),
      ),
    );
    final Rect box = tester.getRect(find.byType(AppSlider));

    await tester.tapAt(Offset(box.right - 1, box.center.dy));
    expect(value, 1);
    await tester.tapAt(Offset(box.center.dx, box.center.dy));
    expect(value, 0.5);
    await tester.tapAt(Offset(box.left + 1, box.center.dy));
    expect(value, 0);
  });

  testWidgets('in right-to-left the slider runs the other way', (WidgetTester tester) async {
    double value = 0.5;
    await tester.pumpWidget(
      _host(
        AppSlider(
          value: value,
          onChanged: (double v) => value = v,
          semanticLabel: 'Volume',
          valueLabel: '50%',
        ),
        dir: TextDirection.rtl,
      ),
    );
    final Rect box = tester.getRect(find.byType(AppSlider));
    await tester.tapAt(Offset(box.left + 1, box.center.dy));
    expect(value, closeTo(1, 0.001));
  });

  testWidgets('the segmented control marks the chosen option and reports a tap', (WidgetTester tester) async {
    String selected = 'a';
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) => AppSegmented<String>(
            selected: selected,
            onChanged: (String v) => setState(() => selected = v),
            options: const <SegmentOption<String>>[
              SegmentOption<String>(value: 'a', label: 'Alpha'),
              SegmentOption<String>(value: 'b', label: 'Beta'),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Beta'));
    await tester.pump();
    expect(selected, 'b');
  });

  test('clock times are padded and tilt steering has a dead zone and a limit', () {
    expect(formatClock(7, 5), '07:05');
    expect(formatClock(18, 0), '18:00');
    expect(TiltStrategy.steerFor(0.01, 0, 1), 0);
    expect(TiltStrategy.steerFor(2, 0, 1), 1);
    expect(TiltStrategy.steerFor(-2, 0, 1), -1);
    expect(TiltStrategy.steerFor(0.5, 0.5, 1), 0);
    expect(TiltStrategy.steerFor(0.3, 0, 2), greaterThan(TiltStrategy.steerFor(0.3, 0, 1)));
  });
}
