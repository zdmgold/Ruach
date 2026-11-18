import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/main.dart';

void main() {
  testWidgets('the placeholder app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const RuachApp());
    expect(find.byType(ColoredBox), findsOneWidget);
  });
}
