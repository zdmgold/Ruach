import 'package:flutter/widgets.dart';
import 'package:ruach/theme/app_theme.dart';
import 'package:ruach/theme/tokens.dart';

/// The uppercase, letter-spaced label above a list or group of cards.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          start: AppSpacing.s16,
          end: AppSpacing.s16,
          top: AppSpacing.s24,
          bottom: AppSpacing.s8,
        ),
        child: Text(label.toUpperCase(), style: theme.type.sectionHeader),
      ),
    );
  }
}
