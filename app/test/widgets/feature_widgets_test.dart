import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/theme/app_theme.dart';
import 'package:ruach/widgets/ad_slot.dart';
import 'package:ruach/widgets/boost_meter.dart';
import 'package:ruach/widgets/error_view.dart';
import 'package:ruach/widgets/gift_badge.dart';
import 'package:ruach/widgets/star_badge.dart';
import 'package:ruach/widgets/upgrade_tile.dart';
import 'package:ruach/widgets/verse_card.dart';

Widget _host(
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  double textScale = 1,
  double keyboard = 0,
  double width = 360,
}) {
  return Directionality(
    textDirection: direction,
    child: MediaQuery(
      data: MediaQueryData(
        size: Size(width, 640),
        textScaler: TextScaler.linear(textScale),
        viewInsets: EdgeInsets.only(bottom: keyboard),
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
  group('AdSlot', () {
    testWidgets('has no size at all when there is no ad', (WidgetTester tester) async {
      await tester.pumpWidget(_host(const AdSlot(height: 50)));
      expect(tester.getSize(find.byType(AdSlot)), Size.zero);
      expect(find.byType(DecoratedBox), findsNothing);
    });

    testWidgets('is the banner height plus 8 above and below when an ad is present', (WidgetTester tester) async {
      await tester.pumpWidget(_host(const AdSlot(height: 50, ad: SizedBox(width: 320, height: 50))));
      expect(tester.getSize(find.byType(AdSlot)).height, 66 + 0.5);
    });

    testWidgets('collapses while the keyboard is open', (WidgetTester tester) async {
      await tester.pumpWidget(_host(
        const AdSlot(height: 50, ad: SizedBox(width: 320, height: 50)),
        keyboard: 300,
      ));
      expect(tester.getSize(find.byType(AdSlot)), Size.zero);
    });

    testWidgets('a zero height collapses even with an ad', (WidgetTester tester) async {
      await tester.pumpWidget(_host(const AdSlot(height: 0, ad: SizedBox(width: 320, height: 50))));
      expect(tester.getSize(find.byType(AdSlot)), Size.zero);
    });
  });

  group('BoostMeter', () {
    double widthFactorOf(WidgetTester tester, int segment) {
      final List<FractionallySizedBox> boxes =
          tester.widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox)).toList();
      return boxes[segment].widthFactor!;
    }

    testWidgets('fills whole segments first and a fraction in the next', (WidgetTester tester) async {
      await tester.pumpWidget(_host(const BoostMeter(fill: 1.5, label: 'Ruach', semanticValue: '1 of 3')));
      expect(widthFactorOf(tester, 0), 1);
      expect(widthFactorOf(tester, 1), 0.5);
      expect(widthFactorOf(tester, 2), 0);
    });

    testWidgets('out-of-range and NaN values are held inside 0 to 3', (WidgetTester tester) async {
      await tester.pumpWidget(_host(const BoostMeter(fill: 9, label: 'Ruach', semanticValue: '3 of 3')));
      expect(widthFactorOf(tester, 2), 1);
      await tester.pumpWidget(_host(const BoostMeter(fill: double.nan, label: 'Ruach', semanticValue: '0 of 3')));
      expect(widthFactorOf(tester, 0), 0);
    });

    testWidgets('carries a visible label and a spoken state', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const BoostMeter(fill: 2, label: 'Ruach', semanticValue: '2 of 3 segments')));
      expect(find.text('Ruach'), findsOneWidget);
      expect(tester.getSemantics(find.byType(BoostMeter)), isSemantics(label: 'Ruach', value: '2 of 3 segments'));
      handle.dispose();
    });

    testWidgets('fills from the start side in right-to-left', (WidgetTester tester) async {
      await tester.pumpWidget(_host(
        const BoostMeter(fill: 0.5, label: 'روح', semanticValue: '0.5'),
        direction: TextDirection.rtl,
      ));
      final Rect segment = tester.getRect(find.byType(FractionallySizedBox).first);
      final Rect parent = tester.getRect(find.byType(ClipRRect).first);
      expect(segment.right, parent.right);
    });
  });

  group('StarBadge and GiftBadge', () {
    testWidgets('stars clamp to 0 to 3 and speak their label', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const StarBadge(stars: 7, semanticLabel: '3 of 3 stars')));
      expect(tester.getSemantics(find.byType(StarBadge)), isSemantics(label: '3 of 3 stars'));
      await tester.pumpWidget(_host(const StarBadge(stars: -2, semanticLabel: '0 of 3 stars')));
      expect(tester.takeException(), isNull);
      handle.dispose();
    });

    testWidgets('only earned stars are fully opaque', (WidgetTester tester) async {
      await tester.pumpWidget(_host(const StarBadge(stars: 2, semanticLabel: 'x')));
      final List<double> opacities =
          tester.widgetList<Opacity>(find.byType(Opacity)).map((Opacity o) => o.opacity).toList();
      expect(opacities, <double>[1, 1, 0.3]);
    });

    testWidgets('the Gift badge shows the count and never a negative one', (WidgetTester tester) async {
      await tester.pumpWidget(_host(const GiftBadge(count: 12, semanticLabel: '12 Gifts')));
      expect(find.text('12'), findsOneWidget);
      await tester.pumpWidget(_host(const GiftBadge(count: -3, semanticLabel: '0 Gifts')));
      expect(find.text('0'), findsOneWidget);
    });
  });

  group('VerseCard', () {
    testWidgets('shows the verse and reference, and actions only when given', (WidgetTester tester) async {
      await tester.pumpWidget(_host(const VerseCard(text: 'The Lord is my shepherd.', reference: 'Psalm 23:1')));
      expect(find.text('The Lord is my shepherd.'), findsOneWidget);
      expect(find.text('Psalm 23:1'), findsOneWidget);
      expect(find.text('Share'), findsNothing);
    });

    testWidgets('Share and Read chapter call back', (WidgetTester tester) async {
      int shares = 0;
      int reads = 0;
      await tester.pumpWidget(_host(VerseCard(
        text: 'v',
        reference: 'r',
        onShare: () => shares++,
        shareLabel: 'Share',
        onReadChapter: () => reads++,
        readLabel: 'Read chapter',
      )));
      await tester.tap(find.text('Share'));
      await tester.tap(find.text('Read chapter'));
      expect((shares, reads), (1, 1));
    });

    testWidgets('right-to-left text starts on the right', (WidgetTester tester) async {
      await tester.pumpWidget(_host(
        const VerseCard(text: 'الرب راعي فلا يعوزني شيء', reference: 'مزمور ٢٣: ١'),
        direction: TextDirection.rtl,
      ));
      final Rect card = tester.getRect(find.byType(VerseCard));
      final Rect text = tester.getRect(find.text('مزمور ٢٣: ١'));
      expect(text.right, greaterThan(card.center.dx));
    });

    testWidgets('survives 200% text with long German words', (WidgetTester tester) async {
      await tester.pumpWidget(_host(
        VerseCard(
          text: 'Der Herr ist mein Hirte, mir wird nichts mangeln. Er weidet mich auf einer grünen Aue.',
          reference: 'Psalm 23,1',
          onShare: () {},
          shareLabel: 'Teilen',
          onReadChapter: () {},
          readLabel: 'Kapitel lesen',
        ),
        textScale: 2,
        width: 320,
      ));
      expect(tester.takeException(), isNull);
    });
  });

  group('UpgradeTile', () {
    testWidgets('shows name, effect, reference and the right number of filled pips', (WidgetTester tester) async {
      await tester.pumpWidget(_host(const UpgradeTile(
        name: 'Might',
        effectLine: 'Top speed +10%',
        verseReference: 'Isaiah 11:2',
        level: 2,
        levelLabel: 'Level 2 of 5',
      )));
      expect(find.text('Might'), findsOneWidget);
      expect(find.text('Top speed +10%'), findsOneWidget);
      expect(find.text('Isaiah 11:2'), findsOneWidget);
      final int filled = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .where((DecoratedBox d) => d.decoration is BoxDecoration && (d.decoration as BoxDecoration).shape == BoxShape.circle)
          .length;
      expect(filled, 5);
    });

    testWidgets('buy chip taps when affordable and is inert when not', (WidgetTester tester) async {
      int buys = 0;
      await tester.pumpWidget(_host(UpgradeTile(
        name: 'Might',
        effectLine: 'e',
        verseReference: 'r',
        level: 0,
        levelLabel: 'Level 0 of 5',
        buyLabel: 'Upgrade: 1 Gift',
        onBuy: () => buys++,
      )));
      await tester.tap(find.text('Upgrade: 1 Gift'));
      expect(buys, 1);
      await tester.pumpWidget(_host(const UpgradeTile(
        name: 'Might',
        effectLine: 'e',
        verseReference: 'r',
        level: 0,
        levelLabel: 'Level 0 of 5',
        buyLabel: 'Needs 1 Gift',
      )));
      expect(find.text('Needs 1 Gift'), findsOneWidget);
    });

    testWidgets('a maxed tile has no buy chip', (WidgetTester tester) async {
      await tester.pumpWidget(_host(const UpgradeTile(
        name: 'Might',
        effectLine: 'e',
        verseReference: 'r',
        level: 5,
        levelLabel: 'Level 5 of 5',
      )));
      expect(find.byType(Text), findsNWidgets(3));
    });

    testWidgets('survives 200% text', (WidgetTester tester) async {
      await tester.pumpWidget(_host(
        UpgradeTile(
          name: 'Furcht des Herrn',
          effectLine: 'Mehr Stabilität auf rauem Untergrund und bei Berührung +10%',
          verseReference: 'Jesaja 11,2',
          level: 3,
          levelLabel: 'Stufe 3 von 5',
          buyLabel: 'Verbessern: 4 Gaben',
          onBuy: () {},
        ),
        textScale: 2,
        width: 320,
      ));
      expect(tester.takeException(), isNull);
    });
  });

  group('ErrorView', () {
    testWidgets('Retry and the report link call back', (WidgetTester tester) async {
      int retries = 0;
      int reports = 0;
      await tester.pumpWidget(_host(
        SizedBox(
          height: 640,
          child: ErrorView(
            title: 'Something went wrong',
            message: 'Your progress is safe.',
            retryLabel: 'Try again',
            onRetry: () => retries++,
            reportLabel: 'Email the log',
            onReport: () => reports++,
          ),
        ),
      ));
      await tester.tap(find.text('Try again'));
      await tester.tap(find.text('Email the log'));
      expect((retries, reports), (1, 1));
    });

    testWidgets('scrolls instead of overflowing at 200% text on a small screen', (WidgetTester tester) async {
      await tester.pumpWidget(_host(
        SizedBox(
          height: 320,
          child: ErrorView(
            title: 'Something went wrong',
            message: 'Your progress is safe. Try again, and if it keeps happening, send us the log.',
            retryLabel: 'Try again',
            onRetry: () {},
            reportLabel: 'Email the log',
            onReport: () {},
          ),
        ),
        textScale: 2,
        width: 320,
      ));
      expect(tester.takeException(), isNull);
    });
  });
}
