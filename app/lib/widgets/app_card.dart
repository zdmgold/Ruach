import 'package:flutter/widgets.dart';
import 'package:ruach/theme/app_icon.dart';
import 'package:ruach/theme/app_theme.dart';
import 'package:ruach/theme/icons.dart';
import 'package:ruach/theme/tokens.dart';
import 'package:ruach/widgets/pressable.dart';

/// A card: [bgSecondary] fill, hairline border, radius 16, with an optional
/// leading icon, a label, an optional value and, when tappable, a chevron.
/// Pressing fades it to 70%.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.label,
    super.key,
    this.icon,
    this.value,
    this.onTap,
    this.semanticLabel,
    this.child,
  });

  final String label;
  final IconData? icon;

  /// Secondary text under the label.
  final String? value;

  /// Null makes it a plain, non-tappable card.
  final VoidCallback? onTap;
  final String? semanticLabel;

  /// Extra content below the label and value (a progress bar, a verse).
  final Widget? child;

  Widget _body(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: theme.colors.border, width: AppStroke.hairline),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppHit.min),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                AppIcon(icon!, color: theme.colors.accent),
                const SizedBox(width: AppSpacing.s16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(label, style: theme.type.title2),
                    if (value != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.s2),
                      Text(value!, style: theme.type.footnote),
                    ],
                    if (child != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.s8),
                      child!,
                    ],
                  ],
                ),
              ),
              if (onTap != null) ...<Widget>[
                const SizedBox(width: AppSpacing.s16),
                AppIcon(
                  AppIcons.forward,
                  size: AppIconSizes.rowTrailing,
                  color: theme.colors.textTertiary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (onTap == null) return _body(context);
    return Pressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      builder: (BuildContext context, bool pressed) => _body(context),
    );
  }
}
