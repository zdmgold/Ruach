import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/logic/catalog_ids.dart';
import 'package:ruach/core/models/race_config.dart';
import 'package:ruach/core/models/settings.dart';
import 'package:ruach/core/ports/billing_port.dart';
import 'package:ruach/screens/error_screen.dart';
import 'package:ruach/screens/language_screen.dart';
import 'package:ruach/screens/licenses_screen.dart';
import 'package:ruach/screens/onboarding_screen.dart';
import 'package:ruach/screens/routes.dart';
import 'package:ruach/screens/tilt_calibration_screen.dart';
import 'package:ruach/screens/upgrade_screen.dart';

import '../support/scope_host.dart';

void _size(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('UpgradeScreen', () {
    testWidgets('shows the price, buys, and then says ads are removed', (WidgetTester tester) async {
      _size(tester);
      final TestScope s = TestScope();
      await tester.pumpWidget(s.app(const UpgradeScreen()));
      await tester.pumpAndSettle();

      expect(find.text(r'Remove ads for $2.99'), findsOneWidget);
      await tester.tap(find.text(r'Remove ads for $2.99'));
      await tester.pumpAndSettle();

      expect(s.entitlement.adsRemoved, isTrue);
      expect(find.text('Ads are removed. Thank you.'), findsOneWidget);
      expect(find.text('Restore purchase'), findsNothing);
    });

    testWidgets('a cancelled or failed purchase says so and changes nothing', (WidgetTester tester) async {
      _size(tester);
      final TestScope s = TestScope();
      s.billing.purchaseResult = PurchaseResult.cancelled;
      await tester.pumpWidget(s.app(const UpgradeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Remove ads for'));
      await tester.pumpAndSettle();
      expect(find.text('Purchase cancelled.'), findsOneWidget);
      expect(s.entitlement.adsRemoved, isFalse);

      s.billing.purchaseResult = PurchaseResult.failed;
      await tester.tap(find.textContaining('Remove ads for'));
      await tester.pumpAndSettle();
      expect(find.text('The purchase did not complete. Please try again.'), findsOneWidget);
    });
  });

  group('TiltCalibrationScreen', () {
    testWidgets('Set level saves the current angle', (WidgetTester tester) async {
      _size(tester);
      final TestScope s = TestScope();
      final StreamController<double> roll = StreamController<double>.broadcast();
      addTearDown(() {
        roll.close().ignore();
      });
      await tester.pumpWidget(s.app(TiltCalibrationScreen(tilt: roll.stream)));
      await tester.pump();

      roll.add(0.3);
      await tester.pump();
      await tester.tap(find.text('Set level'));
      await tester.pump();
      expect(s.settings.value.tiltCalibration, closeTo(0.3, 1e-9));
    });

    testWidgets('without a sensor it says so and offers no controls', (WidgetTester tester) async {
      _size(tester);
      final TestScope s = TestScope();
      await tester.pumpWidget(s.app(const TiltCalibrationScreen(tiltAvailable: false)));
      await tester.pump();

      expect(find.text('No tilt sensor was found. Buttons are used instead.'), findsOneWidget);
      expect(find.text('Set level'), findsNothing);
    });
  });

  group('LicensesScreen', () {
    testWidgets('lists the notices and expands one on tap', (WidgetTester tester) async {
      _size(tester);
      final TestScope s = TestScope();
      await tester.pumpWidget(
        s.app(
          LicensesScreen(
            loadText: (String path) async => 'Notice for $path',
            loadPackages: () async => const <LicenseNotice>[
              LicenseNotice(title: 'flame', text: 'MIT text'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('English'), findsOneWidget);
      expect(find.text('Barlow font'), findsOneWidget);
      expect(find.text('flame'), findsOneWidget);
      expect(find.text('Notice for assets/notices/scripture-en.txt'), findsNothing);

      await tester.tap(find.text('English'));
      await tester.pump();
      expect(find.text('Notice for assets/notices/scripture-en.txt'), findsOneWidget);
    });

    testWidgets('a load failure shows a message, not a blank page', (WidgetTester tester) async {
      _size(tester);
      final TestScope s = TestScope();
      await tester.pumpWidget(
        s.app(
          LicensesScreen(
            loadText: (String path) async => throw StateError('missing'),
            loadPackages: () async => const <LicenseNotice>[],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('These notices could not be loaded.'), findsOneWidget);
    });
  });

  group('OnboardingScreen', () {
    testWidgets('saves the chosen control and goes to the first Journey race', (WidgetTester tester) async {
      _size(tester);
      final TestScope s = TestScope();
      await tester.pumpWidget(s.app(const OnboardingScreen()));
      await tester.pump();

      await tester.tap(find.text('Drag'));
      await tester.pump();
      await tester.tap(find.text('Start first race'));
      await tester.pumpAndSettle();

      expect(s.settings.value.controlScheme, ControlScheme.dragSteer);
      expect(s.settings.value.onboardingDone, isTrue);
      final TrackIntroArgs args = s.pushed.last.$2! as TrackIntroArgs;
      expect(args.mode, RaceMode.journey);
      expect(args.trackId, TrackIds.journey.first);
    });

    testWidgets('Skip is remembered; Tilt is off when there is no sensor', (WidgetTester tester) async {
      _size(tester);
      final TestScope s = TestScope();
      await tester.pumpWidget(s.app(const OnboardingScreen(tiltAvailable: false)));
      await tester.pump();

      await tester.tap(find.text('Tilt'));
      await tester.pump();
      expect(find.text('No tilt sensor was found. Buttons are used instead.'), findsOneWidget);

      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle();
      expect(s.settings.value.onboardingDone, isTrue);
      expect(s.settings.value.controlScheme, ControlScheme.buttons);
    });
  });

  testWidgets('the language list picks a language or follows the device', (WidgetTester tester) async {
    _size(tester);
    final TestScope s = TestScope();
    await tester.pumpWidget(s.app(const LanguageScreen()));
    await tester.pump();

    await tester.tap(find.text('Español'));
    await tester.pumpAndSettle();
    expect(s.locale.code, 'es');
    expect(s.locale.isOverridden, isTrue);

    await tester.tap(find.text('Device language'));
    await tester.pumpAndSettle();
    expect(s.locale.isOverridden, isFalse);
  });

  testWidgets('the error screen retries, and offers a report only when it can send one', (WidgetTester tester) async {
    _size(tester);
    final TestScope s = TestScope();
    int retries = 0;
    await tester.pumpWidget(s.app(ErrorScreen(onRetry: () => retries++)));
    await tester.pump();

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Email report'), findsNothing);
    await tester.tap(find.text('Try again'));
    expect(retries, 1);

    bool reported = false;
    await tester.pumpWidget(s.app(ErrorScreen(onRetry: () {}, onReport: () => reported = true)));
    await tester.pump();
    await tester.tap(find.text('Email report'));
    expect(reported, isTrue);
  });
}
