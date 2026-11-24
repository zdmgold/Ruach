import 'package:flutter/widgets.dart';
import 'package:ruach/theme/app_theme.dart';
import 'package:ruach/theme/tokens.dart';
import 'package:ruach/widgets/pressable.dart';

/// An on/off control. The state is carried by position and fill, and spoken
/// as "on" or "off" by the platform through the toggled semantics, so colour
/// is never the only signal.
class AppSwitch extends StatelessWidget {
  const AppSwitch({
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    super.key,
  });

  final bool value;

  /// Null disables the switch.
  final ValueChanged<bool>? onChanged;
  final String semanticLabel;

  static const double trackWidth = 52;
  static const double trackHeight = 32;
  static const double thumb = 24;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final ValueChanged<bool>? change = onChanged;
    return Semantics(
      toggled: value,
      child: Pressable(
        semanticLabel: semanticLabel,
        onTap: change == null ? null : () => change(!value),
        builder: (BuildContext context, bool pressed) => SizedBox(
          width: trackWidth,
          height: trackHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: value ? theme.colors.accent : theme.colors.bgTertiary,
              borderRadius: BorderRadius.circular(trackHeight / 2),
              border: Border.all(color: theme.colors.border, width: AppStroke.hairline),
            ),
            child: Align(
              alignment: value ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s4),
                child: SizedBox(
                  width: thumb,
                  height: thumb,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: value ? theme.colors.onAccent : theme.colors.textSecondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
