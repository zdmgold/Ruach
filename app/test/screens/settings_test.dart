import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/models/ad_state.dart';
import 'package:ruach/core/models/settings.dart';
import 'package:ruach/core/ports/consent_port.dart';
import 'package:ruach/screens/routes.dart';
import 'package:ruach/screens/settings_screen.dart';
import 'package:ruach/widgets/app_switch.dart';

import '../support/scope_host.dart';

void _size(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<TestScope> _open(WidgetTester tester, {OpenUrl? onOpenUrl}) async {
  _size(tester);
  final TestScope s = TestScope();
  await tester.pumpWidget(s.app(SettingsScreen(onOpenUrl: onOpenUrl)));
  await tester.pump();
  return s;
}

void main() {
  testWidgets('Privacy choices appears only when the region requires it', (WidgetTester tester) async {
    final TestScope s = await _open(tester);
    expect(find.text('Privacy choices'), findsNothing);

    s.consentPort.next = const ConsentSnapshot(
      status: ConsentStatus.obtained,
      canRequestAds: true,
      privacyOptionsRequired: true,
    );
    await s.consent.refresh();
    await tester.pump();
    expect(find.text('Privacy choices'), findsOneWidget);
  });

  testWidgets('Tilt setup shows only while Tilt is the chosen control', (WidgetTester tester) async {
    final TestScope s = await _open(tester);
    expect(find.text('Tilt setup'), findsNothing);

    await tester.tap(find.text('Tilt'));
    await tester.pump();
    expect(s.settings.value.controlScheme, ControlScheme.tilt);
    expect(find.text('Tilt setup'), findsOneWidget);

    await tester.tap(find.text('Tilt setup'));
    await tester.pumpAndSettle();
    expect(s.pushed.last.$1, Routes.tiltCalibration);

    await tester.tap(find.text('Buttons'));
    await tester.pump();
    expect(find.text('Tilt setup'), findsNothing);
  });

  testWidgets('theme, hand and the one-handed layout are saved', (WidgetTester tester) async {
    final TestScope s = await _open(tester);

    await tester.tap(find.text('Dark'));
    await tester.tap(find.text('Left'));
    await tester.pump();
    expect(s.settings.value.themeChoice, ThemeChoice.dark);
    expect(s.settings.value.handedness, Handedness.left);

    await tester.tap(find.byType(AppSwitch).first);
    await tester.pump();
    expect(s.settings.value.oneHandedLayout, isTrue);
  });

  testWidgets('turning sound off hides its volume slider', (WidgetTester tester) async {
    final TestScope s = await _open(tester);
    expect(find.text('Effects volume'), findsOneWidget);

    await tester.tap(find.byType(AppSwitch).at(1));
    await tester.pump();
    expect(s.settings.value.soundEnabled, isFalse);
    expect(find.text('Effects volume'), findsNothing);
  });

  testWidgets('the reminder is scheduled when allowed, and explains when it is not', (WidgetTester tester) async {
    final TestScope s = await _open(tester);
    await tester.tap(find.byType(AppSwitch).at(4));
    await tester.pumpAndSettle();
    expect(s.settings.value.remindersEnabled, isTrue);
    expect(s.notifications.calls, isNotEmpty);
    expect(find.text('Reminder time'), findsOneWidget);

    await tester.tap(find.byType(AppSwitch).at(4));
    await tester.pumpAndSettle();
    expect(s.settings.value.remindersEnabled, isFalse);

    s.notifications.permitted = false;
    await tester.tap(find.byType(AppSwitch).at(4));
    await tester.pumpAndSettle();
    expect(s.settings.value.remindersEnabled, isFalse);
    expect(find.textContaining('Notifications are off'), findsOneWidget);
  });

  testWidgets('Restore purchase says whether it found one', (WidgetTester tester) async {
    final TestScope s = await _open(tester);
    await tester.tap(find.text('Restore purchase'));
    await tester.pumpAndSettle();
    expect(find.text('No earlier purchase was found.'), findsOneWidget);

    s.billing.restoreFinds = true;
    await tester.tap(find.text('Restore purchase'));
    await tester.pumpAndSettle();
    expect(find.text('Purchase restored.'), findsOneWidget);
    expect(s.entitlement.adsRemoved, isTrue);
    expect(find.text('Ads removed'), findsOneWidget);
  });

  testWidgets('Help and feedback opens a mail link; Licenses and Language navigate', (WidgetTester tester) async {
    Uri? opened;
    final TestScope s = await _open(tester, onOpenUrl: (Uri u) async {
      opened = u;
      return true;
    });

    await tester.tap(find.text('Help and feedback'));
    await tester.pump();
    expect(opened?.scheme, 'mailto');

    await tester.tap(find.text('Licenses'));
    await tester.pumpAndSettle();
    expect(s.pushed.last.$1, Routes.licenses);
  });
}
