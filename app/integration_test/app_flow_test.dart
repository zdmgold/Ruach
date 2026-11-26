import 'dart:ui';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ruach/main.dart' as app;

/// End-to-end flow on a real (emulated) device with the real services and
/// Google's test ad IDs: first launch, Home, Settings, a Daily Run, and the
/// start of a race, with frame timings printed for the performance review.
/// Run by the manual emulator workflow; the device language must be English.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first launch to the start of a race', (WidgetTester tester) async {
    final List<FrameTiming> timings = <FrameTiming>[];
    void collect(List<FrameTiming> t) => timings.addAll(t);
    SchedulerBinding.instance.addTimingsCallback(collect);
    addTearDown(() => SchedulerBinding.instance.removeTimingsCallback(collect));

    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // A new install starts at onboarding; skipping leads Home.
    if (find.text('Skip for now').evaluate().isNotEmpty) {
      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Journey'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Help and feedback'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Daily Run'));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Start today's run"));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start race'));
    await tester.pump();

    // Countdown, then a few seconds of racing.
    final Stopwatch clock = Stopwatch()..start();
    while (clock.elapsed < const Duration(seconds: 8)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Start race'), findsNothing);
    expect(tester.takeException(), isNull);

    if (timings.isNotEmpty) {
      final List<int> ms = timings
          .map((FrameTiming t) => t.totalSpan.inMicroseconds ~/ 1000)
          .toList()
        ..sort();
      final int slow = ms.where((int v) => v > 16).length;
      debugPrint(
        'frame timings: frames=${ms.length} median=${ms[ms.length ~/ 2]}ms '
        'p95=${ms[(ms.length * 0.95).floor().clamp(0, ms.length - 1)]}ms '
        'over16ms=$slow',
      );
    }
  });
}
