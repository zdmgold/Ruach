import 'package:flutter/widgets.dart';
import 'package:ruach/theme/app_icon.dart';
import 'package:ruach/theme/app_theme.dart';
import 'package:ruach/theme/tokens.dart';
import 'package:ruach/widgets/pressable.dart';

/// The filled accent button: 48 high, radius 12, disabled at 40% opacity.
/// There is one per screen at most.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.expand = true,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;

  /// Optional symbol from `AppIcons`, shown before the label.
  final IconData? icon;

  /// Fill the available width (the default) or wrap the label.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final Color onAccent = theme.colors.onAccent;
    return Pressable(
      onTap: onPressed,
      pressedScale: 0.97,
      builder: (BuildContext context, bool pressed) {
        final Widget text = Text(
          label,
          textAlign: TextAlign.center,
          style: theme.type.callout.copyWith(color: onAccent),
        );
        return DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colors.accent,
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: AppHit.min,
              minWidth: expand ? double.infinity : AppHit.min,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s24,
                vertical: AppSpacing.s8,
              ),
              child: Row(
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    AppIcon(icon!, color: onAccent),
                    const SizedBox(width: AppSpacing.s8),
                  ],
                  Flexible(child: text),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
