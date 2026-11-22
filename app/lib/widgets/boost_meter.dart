import 'package:flutter/widgets.dart';
import 'package:ruach/theme/app_icon.dart';
import 'package:ruach/theme/app_theme.dart';
import 'package:ruach/theme/icons.dart';
import 'package:ruach/theme/tokens.dart';

/// The Ruach meter: three segments that fill from clean driving. It carries
/// an icon and a label so the state never depends on colour alone.
class BoostMeter extends StatelessWidget {
  const BoostMeter({
    required this.fill,
    required this.label,
    required this.semanticValue,
    super.key,
    this.segments = 3,
  });

  /// How many segments are full, 0 to [segments]; a fraction fills the
  /// segment part way.
  final double fill;
  final int segments;

  /// Short visible label (the localized word for the meter).
  final String label;

  /// Spoken state, for example "2 of 3 segments".
  final String semanticValue;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final double clamped = fill.isNaN ? 0 : fill.clamp(0, segments.toDouble()).toDouble();
    return Semantics(
      label: label,
      value: semanticValue,
      container: true,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppIcon(AppIcons.boost, size: AppIconSizes.navBar, color: theme.colors.ruachMeter),
          const SizedBox(width: AppSpacing.s8),
          for (int i = 0; i < segments; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: AppSpacing.s4),
            _Segment(share: (clamped - i).clamp(0, 1).toDouble(), colors: theme.colors),
          ],
          const SizedBox(width: AppSpacing.s8),
          Text(label, style: theme.type.caption.copyWith(color: theme.colors.textPrimary)),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.share, required this.colors});

  final double share;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bgTertiary,
        borderRadius: BorderRadius.circular(AppRadii.chip / 2),
        border: Border.all(color: colors.border, width: AppStroke.hairline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.chip / 2),
        child: SizedBox(
          width: 28,
          height: 12,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              widthFactor: share,
              heightFactor: 1,
              child: ColoredBox(color: colors.ruachMeter),
            ),
          ),
        ),
      ),
    );
  }
}
