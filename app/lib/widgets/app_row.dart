import 'package:flutter/widgets.dart';
import 'package:ruach/theme/app_icon.dart';
import 'package:ruach/theme/app_theme.dart';
import 'package:ruach/theme/icons.dart';
import 'package:ruach/theme/tokens.dart';
import 'package:ruach/widgets/pressable.dart';

/// A list row: transparent, with a leading icon, a label and a trailing
/// chevron (or a [trailing] widget such as a switch or a value). Pressing
/// tints the background; the row does not fade.
class AppRow extends StatelessWidget {
  const AppRow({
    required this.label,
    super.key,
    this.icon,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.semanticLabel,
  });

  final String label;
  final IconData? icon;
  final String? subtitle;

  /// Replaces the chevron.
  final Widget? trailing;

  /// Null makes it a plain row with no chevron.
  final VoidCallback? onTap;
  final String? semanticLabel;

  /// The most of the row's width the trailing widget may take.
  static const double trailingShare = 0.45;

  Widget _body(BuildContext context, bool pressed) {
    final AppThemeData theme = AppTheme.of(context);
    final Widget? end = trailing ??
        (onTap != null
            ? AppIcon(
                AppIcons.forward,
                size: AppIconSizes.rowTrailing,
                color: theme.colors.textTertiary,
              )
            : null);
    return ColoredBox(
      color: pressed ? theme.colors.bgTertiary : const Color(0x00000000),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppHit.min),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s8,
          ),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints box) => Row(
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
                    Text(label, style: theme.type.callout),
                    if (subtitle != null) Text(subtitle!, style: theme.type.footnote),
                  ],
                ),
              ),
              if (end != null) ...<Widget>[
                const SizedBox(width: AppSpacing.s16),
                // A long trailing label (a chip in a long language or at large
                // text) wraps within this share instead of overflowing.
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: box.maxWidth * trailingShare),
                  child: end,
                ),
              ],
            ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (onTap == null) return _body(context, false);
    return Pressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      fadeWhenPressed: false,
      minSize: 0,
      builder: _body,
    );
  }
}
