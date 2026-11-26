import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/app.dart';
import 'package:ruach/core/logic/catalog_ids.dart';
import 'package:ruach/core/logic/locale_rules.dart';
import 'package:ruach/core/models/race_config.dart';
import 'package:ruach/core/models/settings.dart';
import 'package:ruach/screens/routes.dart';
import 'package:ruach/widgets/nav_bar.dart';

import '../support/app_host.dart';
import '../support/scope_host.dart';

/// Layout gate for every language: the main screens build with no overflow or
/// other error on a small phone at normal and doubled text size, and Arabic
/// and Hebrew lay out right to left. (Pixel screenshots are taken on the
/// emulator run; see D-048.)
void main() {
  final List<(String, Object?)> screens = <(String, Object?)>[
    (Routes.settings, null),
    (Routes.garage, null),
    (Routes.verseLibrary, null),
    (Routes.dailyRun, null),
    (Routes.language, null),
    (Routes.upgrade, null),
    (Routes.licenses, null),
    (Routes.mode, const ModeArgs(RaceMode.journey)),
    (Routes.mode, const ModeArgs(RaceMode.quickRace)),
    (Routes.trackIntro, TrackIntroArgs(mode: RaceMode.journey, trackId: TrackIds.journey.first)),
  ];

  for (final String code in LocaleRules.supported) {
    for (final double scale in <double>[1.0, 2.0]) {
      testWidgets('$code at ${scale}x text: every main screen lays out', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final List<String> problems = <String>[];
        final FlutterExceptionHandler? previous = FlutterError.onError;
        FlutterError.onError = (FlutterErrorDetails d) => problems.add(d.toString());
        addTearDown(() => FlutterError.onError = previous);

        final TestScope s = TestScope();
        await s.settings.update(
          (Settings v) => v.copyWith(onboardingDone: true, languageCode: code),
        );
        await tester.pumpWidget(RuachApp(services: testServices(s)));
        await tester.pumpAndSettle();
        expect(problems, isEmpty, reason: 'home');

        final TextDirection want =
            LocaleRules.isRtl(code) ? TextDirection.rtl : TextDirection.ltr;
        expect(Directionality.of(tester.element(find.byType(NavBar).first)), want);

        final NavigatorState navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
        for (final (String route, Object? args) in screens) {
          navigator.pushNamed(route, arguments: args).ignore();
          await tester.pumpAndSettle();
          if (problems.isNotEmpty) {
            fail('$route in $code at ${scale}x: ${problems.first}');
          }
          navigator.pop();
          await tester.pumpAndSettle();
        }
      });
    }
  }
}
