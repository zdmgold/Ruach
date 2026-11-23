import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/core/models/verse.dart';
import 'package:ruach/screens/home_screen.dart';
import 'package:ruach/screens/routes.dart';
import 'package:ruach/screens/verse_library_screen.dart';

import '../support/scope_host.dart';

void _size(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('an empty library says how verses are collected', (WidgetTester tester) async {
    _size(tester);
    final TestScope s = TestScope();
    await tester.pumpWidget(s.app(const VerseLibraryScreen()));
    await tester.pumpAndSettle();

    expect(find.text('No verses yet'), findsOneWidget);
    expect(find.text('Race to collect verses. Each one you meet is kept here.'), findsOneWidget);
  });

  testWidgets('a verse met in play appears with its reference', (WidgetTester tester) async {
    _size(tester);
    final TestScope s = TestScope();
    await s.verses.pick(VerseMoment.win, seed: 1);
    await tester.pumpWidget(s.app(const VerseLibraryScreen()));
    await tester.pumpAndSettle();

    expect(find.text('1 verse collected'), findsOneWidget);
    expect(find.text('The LORD is my shepherd.'), findsOneWidget);
    expect(find.text('Psalm 23:1'), findsOneWidget);
    expect(find.text('Read the chapter'), findsNothing);
  });

  testWidgets('the reader link and share show only when the shell supplies them', (WidgetTester tester) async {
    _size(tester);
    final TestScope s = TestScope();
    await s.verses.pick(VerseMoment.win, seed: 1);
    String? shared;
    await tester.pumpWidget(
      s.app(
        VerseLibraryScreen(
          onShare: (String text) async {
            shared = text;
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Share'));
    await tester.pump();
    expect(shared, '“The LORD is my shepherd.” Psalm 23:1');
  });

  testWidgets('Home links to the library', (WidgetTester tester) async {
    _size(tester);
    final TestScope s = TestScope();
    await tester.pumpWidget(s.app(const HomeScreen()));
    await tester.pump();

    await tester.tap(find.text('Verse library'));
    await tester.pumpAndSettle();
    expect(s.pushed.last.$1, Routes.verseLibrary);
  });
}
