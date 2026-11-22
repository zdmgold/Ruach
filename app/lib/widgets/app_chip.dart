import 'package:flutter/widgets.dart';
import 'package:ruach/theme/app_icon.dart';
import 'package:ruach/theme/app_theme.dart';
import 'package:ruach/theme/tokens.dart';
import 'package:ruach/widgets/pressable.dart';

enum ChipTone { neutral, accent }

/// A small labelled pill for metadata (a Gift count, a streak, an era). With
/// [onTap] it is also a button; the hit area stays at least 48 square.
class AppChip extends StatelessWidget {
  const AppChip({
    required this.label,
    super.key,
    this.icon,
    this.tone = ChipTone.neutral,
    this.onTap,
    this.semanticLabel,
  });

  final String label;
  final IconData? icon;
  final ChipTone tone;
  final VoidCallback? onTap;

  /// Spoken instead of [label], for chips whose text is only a number.
  final String? semanticLabel;

  Widget _chip(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final bool accent = tone == ChipTone.accent;
    final Color fill = accent ? theme.colors.accent : theme.colors.bgTertiary;
    final Color ink = accent ? theme.colors.onAccent : theme.colors.textPrimary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s8,
          vertical: AppSpacing.s4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              AppIcon(icon!, size: AppIconSizes.rowTrailing, color: ink),
              const SizedBox(width: AppSpacing.s4),
            ],
            Flexible(
              child: Text(label, style: theme.type.footnote.copyWith(color: ink)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (onTap == null) {
      return Semantics(
        label: semanticLabel,
        container: semanticLabel != null,
        excludeSemantics: semanticLabel != null,
        child: _chip(context),
      );
    }
    return Pressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      builder: (BuildContext context, bool pressed) => _chip(context),
    );
  }
}
