import 'package:flutter/widgets.dart';
import 'package:ruach/theme/tokens.dart';

void main() {
  runApp(const RuachApp());
}

/// Placeholder root. It shows a flat dark surface only. Batch p6a replaces it
/// with the real boot sequence (services, consent, providers, routes).
class RuachApp extends StatelessWidget {
  const RuachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: AppColors.dark.bgPrimary);
  }
}
