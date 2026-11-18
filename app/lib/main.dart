import 'package:flutter/widgets.dart';

void main() {
  runApp(const RuachApp());
}

/// Placeholder root. It shows a flat dark surface only. Batch p6a replaces it
/// with the real boot sequence (services, consent, providers, routes), and the
/// colour moves into the design tokens in batch p1d.
class RuachApp extends StatelessWidget {
  const RuachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: Color(0xFF14110D));
  }
}
