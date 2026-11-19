import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/theme/app_icon.dart';
import 'package:ruach/theme/app_theme.dart';
import 'package:ruach/theme/icons.dart';
import 'package:ruach/theme/tokens.dart';
import 'package:ruach/theme/typography.dart';

Widget _host({required TextDirection direction, required Widget child}) {
  return Directionality(
    textDirection: direction,
    child: AppTheme(data: AppThemeData.light(), child: child),
  );
}

void main() {
  test('light and dark themes differ and are equal to themselves', () {
    expect(AppThemeData.light(), AppThemeData.light());
    expect(AppThemeData.light() == AppThemeData.dark(), isFalse);
    expect(AppThemeData.of(Brightness.dark).colors.bgPrimary, AppColors.dark.bgPrimary);
  });

  test('text styles take their colour from the theme', () {
    final AppThemeData dark = AppThemeData.dark();
    expect(dark.type.body.color, AppColors.dark.textPrimary);
    expect(dark.type.footnote.color, AppColors.dark.textSecondary);
    expect(dark.type.display.fontFamily, AppTypography.family);
  });

  test('the display style uses tabular figures', () {
    final TextStyle display = AppThemeData.light().type.display;
    expect(display.fontFeatures, isNotNull);
    expect(display.fontFeatures!.any((FontFeature f) => f.feature == 'tnum'), isTrue);
  });

  testWidgets('AppTheme.of finds the theme above a widget', (WidgetTester tester) async {
    late AppThemeData found;
    await tester.pumpWidget(
      _host(
        direction: TextDirection.ltr,
        child: Builder(
          builder: (BuildContext context) {
            found = AppTheme.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(found.brightness, Brightness.light);
  });

  testWidgets('AppIcon draws the symbol in the theme text colour', (WidgetTester tester) async {
    await tester.pumpWidget(
      _host(direction: TextDirection.rtl, child: const AppIcon(AppIcons.star)),
    );
    final Icon drawn = tester.widget<Icon>(find.byType(Icon));
    expect(drawn.icon, AppIcons.star);
    expect(drawn.color, AppColors.light.textPrimary);
  });

  test('only direction icons mirror in right-to-left languages', () {
    expect(AppIcons.back.matchTextDirection, isTrue);
    expect(AppIcons.forward.matchTextDirection, isTrue);
    expect(AppIcons.star.matchTextDirection, isFalse);
    expect(AppIcons.settings.matchTextDirection, isFalse);
  });

  test('icons come from the bundled Phosphor Bold font', () {
    expect(AppIcons.home.fontFamily, 'PhosphorBold');
    expect(AppIcons.home.fontPackage, isNull);
  });
}
