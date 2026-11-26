import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/app.dart';
import 'package:ruach/app_services.dart';
import 'package:ruach/core/logic/catalog_ids.dart';
import 'package:ruach/core/models/settings.dart';
import 'package:ruach/screens/race_screen.dart';
import 'package:ruach/screens/routes.dart';
import 'package:ruach/utils/error_handler.dart';

import 'support/fakes.dart';
import 'support/scope_host.dart';

AppServices _services(TestScope s, {FakeUrl? url, FakeLog? log}) => AppServices(
      settings: s.settings,
      theme: s.theme,
      locale: s.locale,
      progress: s.progress,
      garage: s.garage,
      entitlement: s.entitlement,
      race: s.race,
      consent: s.consent,
      ads: s.ads,
      daily: s.daily,
      verses: s.verses,
      flags: s.flags,
      ports: ShellPorts(
        share: FakeShare(),
        url: url ?? FakeUrl(),
        tilt: FakeTilt(),
        log: log ?? FakeLog(),
        review: FakeReview(),
      ),
      errors: AppErrorHandler((Object e, StackTrace? st, {required bool fatal}) {}),
    );

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('the app opens straight into a race', (WidgetTester tester) async {
    _phone(tester);
    final TestScope s = TestScope();
    await tester.pumpWidget(RuachApp(services: _services(s)));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(RaceScreen), findsOneWidget);
    expect(s.race.simulation, isNotNull);
    expect(s.race.simulation!.config.track.id, TrackIds.journey.first);
    expect(find.text('Start race'), findsNothing);
  });

  testWidgets('a returning player opens Home; Settings opens and goes back', (WidgetTester tester) async {
    _phone(tester);
    final TestScope s = TestScope();
    await s.settings.update((Settings v) => v.copyWith(onboardingDone: true));
    await tester.pumpWidget(RuachApp(services: _services(s), initialRoute: Routes.home));
    await tester.pumpAndSettle();
    expect(find.text('Journey'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Help and feedback'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Journey'), findsOneWidget);
  });

  testWidgets('the Daily Run card opens the Daily Run screen, and Start reaches the track introduction', (WidgetTester tester) async {
    _phone(tester);
    final TestScope s = TestScope();
    await s.settings.update((Settings v) => v.copyWith(onboardingDone: true));
    await tester.pumpWidget(RuachApp(services: _services(s), initialRoute: Routes.home));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Daily Run'));
    await tester.pumpAndSettle();
    expect(find.text("Start today's run"), findsOneWidget);

    await tester.tap(find.text("Start today's run"));
    await tester.pumpAndSettle();
    expect(find.text('Start race'), findsOneWidget);
  });

  testWidgets('a fatal error shows the fallback; Retry returns to Home; Email report opens mail', (WidgetTester tester) async {
    _phone(tester);
    final TestScope s = TestScope();
    final FakeUrl url = FakeUrl();
    final FakeLog log = FakeLog()..log('boom');
    await s.settings.update((Settings v) => v.copyWith(onboardingDone: true));
    final AppServices services = _services(s, url: url, log: log);
    await tester.pumpWidget(RuachApp(services: services, initialRoute: Routes.home));
    await tester.pumpAndSettle();

    services.errors.report(StateError('x'), StackTrace.current, fatal: true);
    await tester.pumpAndSettle();
    expect(find.text('Something went wrong'), findsOneWidget);

    await tester.tap(find.text('Email report'));
    await tester.pumpAndSettle();
    expect(url.opened.single.scheme, 'mailto');
    expect(url.opened.single.toString(), contains('boom'));

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Journey'), findsOneWidget);
  });
}
