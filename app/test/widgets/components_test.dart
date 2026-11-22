import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/theme/app_theme.dart';
import 'package:ruach/theme/icons.dart';
import 'package:ruach/widgets/app_card.dart';
import 'package:ruach/widgets/app_chip.dart';
import 'package:ruach/widgets/app_row.dart';
import 'package:ruach/widgets/empty_state.dart';
import 'package:ruach/widgets/nav_bar.dart';
import 'package:ruach/widgets/primary_button.dart';
import 'package:ruach/widgets/section_header.dart';

Widget _host(
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  double textScale = 1,
  bool reduceMotion = false,
  double width = 360,
}) {
  return Directionality(
    textDirection: direction,
    child: MediaQuery(
      data: MediaQueryData(
        size: Size(width, 640),
        textScaler: TextScaler.linear(textScale),
        disableAnimations: reduceMotion,
      ),
      child: AppTheme(
        data: AppThemeData.light(),
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  );
}

void main() {
  group('PrimaryButton', () {
    testWidgets('is 48 high and calls back on tap', (WidgetTester tester) async {
      int taps = 0;
      await tester.pumpWidget(_host(PrimaryButton(label: 'Start', onPressed: () => taps++)));
      expect(tester.getSize(find.byType(PrimaryButton)).height, 48);
      await tester.tap(find.text('Start'));
      expect(taps, 1);
    });

    testWidgets('does nothing when disabled and is drawn at 40% opacity', (WidgetTester tester) async {
      await tester.pumpWidget(_host(const PrimaryButton(label: 'Start', onPressed: null)));
      final AnimatedOpacity o = tester.widget(find.descendant(
        of: find.byType(PrimaryButton),
        matching: find.byType(AnimatedOpacity),
      ));
      expect(o.opacity, 0.4);
    });

    testWidgets('fades while pressed and restores on release', (WidgetTester tester) async {
      await tester.pumpWidget(_host(PrimaryButton(label: 'Start', onPressed: () {})));
      final TestGesture g = await tester.startGesture(tester.getCenter(find.text('Start')));
      await tester.pump();
      AnimatedOpacity o = tester.widget(find.descendant(
        of: find.byType(PrimaryButton),
        matching: find.byType(AnimatedOpacity),
      ));
      expect(o.opacity, 0.7);
      await g.up();
      await tester.pump();
      o = tester.widget(find.descendant(
        of: find.byType(PrimaryButton),
        matching: find.byType(AnimatedOpacity),
      ));
      expect(o.opacity, 1);
    });

    testWidgets('Reduce Motion makes the press instant', (WidgetTester tester) async {
      await tester.pumpWidget(_host(PrimaryButton(label: 'Start', onPressed: () {}), reduceMotion: true));
      final AnimatedOpacity o = tester.widget(find.descendant(
        of: find.byType(PrimaryButton),
        matching: find.byType(AnimatedOpacity),
      ));
      expect(o.duration, Duration.zero);
    });

    testWidgets('survives 200% text and a long German label', (WidgetTester tester) async {
      await tester.pumpWidget(_host(
        PrimaryButton(label: 'Geschwindigkeitsbegrenzung aufheben und weiterfahren', onPressed: () {}),
        textScale: 2,
        width: 320,
      ));
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(PrimaryButton)).height, greaterThanOrEqualTo(48));
    });
  });

  group('AppCard', () {
    testWidgets('shows label, value and a chevron only when tappable', (WidgetTester tester) async {
      await tester.pumpWidget(_host(const AppCard(label: 'Garage', value: '3 Gifts')));
      expect(find.text('Garage'), findsOneWidget);
      expect(find.text('3 Gifts'), findsOneWidget);
      expect(find.byIcon(AppIcons.forward), findsNothing);
      await tester.pumpWidget(_host(AppCard(label: 'Garage', onTap: () {})));
      expect(find.byIcon(AppIcons.forward), findsOneWidget);
    });

    testWidgets('taps are at least 48 square even for a short card', (WidgetTester tester) async {
      int taps = 0;
      await tester.pumpWidget(_host(AppCard(label: 'A', onTap: () => taps++)));
      final Size size = tester.getSize(find.byType(AppCard));
      expect(size.height, greaterThanOrEqualTo(48));
      await tester.tapAt(tester.getTopLeft(find.byType(AppCard)) + const Offset(4, 4));
      expect(taps, 1);
    });

    testWidgets('in right-to-left the icon is on the right and the chevron on the left', (WidgetTester tester) async {
      await tester.pumpWidget(_host(
        AppCard(label: 'مرآب', icon: AppIcons.garage, onTap: () {}),
        direction: TextDirection.rtl,
      ));
      final double iconX = tester.getCenter(find.byIcon(AppIcons.garage)).dx;
      final double chevronX = tester.getCenter(find.byIcon(AppIcons.forward)).dx;
      expect(iconX, greaterThan(chevronX));
    });

    testWidgets('survives 200% text', (WidgetTester tester) async {
      await tester.pumpWidget(_host(
        AppCard(label: 'Bestzeit und Rundenübersicht', value: 'Dreißig Sekunden', icon: AppIcons.timeTrial, onTap: () {}),
        textScale: 2,
        width: 320,
      ));
      expect(tester.takeException(), isNull);
    });
  });

  group('AppRow', () {
    testWidgets('is at least 48 high, fills the width and taps', (WidgetTester tester) async {
      int taps = 0;
      await tester.pumpWidget(_host(AppRow(label: 'Language', onTap: () => taps++)));
      final Size size = tester.getSize(find.byType(AppRow));
      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.width, 360);
      await tester.tap(find.text('Language'));
      expect(taps, 1);
    });

    testWidgets('a trailing widget replaces the chevron', (WidgetTester tester) async {
      await tester.pumpWidget(_host(
        AppRow(label: 'Sound', trailing: const Text('On'), onTap: () {}),
      ));
      expect(find.text('On'), findsOneWidget);
      expect(find.byIcon(AppIcons.forward), findsNothing);
    });

    testWidgets('a plain row has no chevron and does not react', (WidgetTester tester) async {
      await tester.pumpWidget(_host(const AppRow(label: 'Version')));
      expect(find.byIcon(AppIcons.forward), findsNothing);
    });
  });

  group('AppChip', () {
    testWidgets('a tappable chip has a hit area of at least 48 square', (WidgetTester tester) async {
      int taps = 0;
      await tester.pumpWidget(_host(AppChip(label: '12', icon: AppIcons.gift, onTap: () => taps++)));
      final Size hit = tester.getSize(find.byType(AppChip));
      expect(hit.width, greaterThanOrEqualTo(48));
      expect(hit.height, greaterThanOrEqualTo(48));
      await tester.tap(find.text('12'));
      expect(taps, 1);
    });

    testWidgets('a plain chip is small', (WidgetTester tester) async {
      await tester.pumpWidget(_host(const AppChip(label: 'Chariot Age')));
      expect(tester.getSize(find.byType(AppChip)).height, lessThan(48));
    });
  });

  group('SectionHeader and EmptyState', () {
    testWidgets('the section header is uppercase and a semantic header', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const SectionHeader('Modes')));
      expect(find.text('MODES'), findsOneWidget);
      expect(tester.getSemantics(find.text('MODES')).hasFlag(SemanticsFlag.isHeader), isTrue);
      handle.dispose();
    });

    testWidgets('the empty state centres its title, subtitle and action', (WidgetTester tester) async {
      await tester.pumpWidget(_host(
        SizedBox(
          height: 400,
          child: EmptyState(
            icon: AppIcons.verse,
            title: 'No verses yet',
            subtitle: 'Finish a race to see one.',
            action: PrimaryButton(label: 'Race', onPressed: () {}),
          ),
        ),
      ));
      expect(find.text('No verses yet'), findsOneWidget);
      expect(find.text('Finish a race to see one.'), findsOneWidget);
      expect(find.text('Race'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('NavBar', () {
    testWidgets('shows the brand on a top-level screen and no back button', (WidgetTester tester) async {
      await tester.pumpWidget(_host(const NavBar(title: 'Home', brand: 'Ruach')));
      expect(find.text('Ruach'), findsOneWidget);
      expect(find.byIcon(AppIcons.back), findsNothing);
    });

    testWidgets('the back button is 48 square, taps, and mirrors in right-to-left', (WidgetTester tester) async {
      int backs = 0;
      await tester.pumpWidget(_host(NavBar(title: 'Garage', onBack: () => backs++, backLabel: 'Back')));
      await tester.tap(find.byIcon(AppIcons.back));
      expect(backs, 1);
      final double ltr = tester.getCenter(find.byIcon(AppIcons.back)).dx;
      await tester.pumpWidget(_host(
        NavBar(title: 'مرآب', onBack: () => backs++, backLabel: 'رجوع'),
        direction: TextDirection.rtl,
      ));
      final double rtl = tester.getCenter(find.byIcon(AppIcons.back)).dx;
      expect(ltr, lessThan(180));
      expect(rtl, greaterThan(180));
    });

    testWidgets('action chips sit on the end side and the title still fits at 200% text', (WidgetTester tester) async {
      await tester.pumpWidget(_host(
        NavBar(
          title: 'Journey',
          onBack: () {},
          backLabel: 'Back',
          actions: <Widget>[
            AppChip(label: '12', icon: AppIcons.gift, onTap: () {}),
            AppChip(label: '4', icon: AppIcons.dailyRun, onTap: () {}),
          ],
        ),
        textScale: 2,
        width: 320,
      ));
      expect(tester.takeException(), isNull);
      expect(find.text('Journey'), findsOneWidget);
    });
  });
}
