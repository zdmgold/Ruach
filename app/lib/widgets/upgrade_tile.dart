import 'package:flutter/widgets.dart';
import 'package:ruach/theme/app_theme.dart';
import 'package:ruach/theme/tokens.dart';
import 'package:ruach/widgets/app_chip.dart';

/// One Isaiah 11:2 upgrade in the Garage: its name, a plain-language effect
/// line, five level pips, the verse reference, and a buy action.
class UpgradeTile extends StatelessWidget {
  const UpgradeTile({
    required this.name,
    required this.effectLine,
    required this.verseReference,
    required this.level,
    required this.levelLabel,
    super.key,
    this.maxLevel = 5,
    this.verseText,
    this.buyLabel,
    this.onBuy,
    this.buySemanticLabel,
  });

  final String name;

  /// For example "Top speed +10%".
  final String effectLine;
  final String verseReference;

  /// The verse itself, shown above its reference when loaded.
  final String? verseText;
  final int level;
  final int maxLevel;

  /// Spoken level, for example "Level 2 of 5".
  final String levelLabel;

  /// Text of the buy chip. Null hides it (maxed out). With a label but no
  /// [onBuy] it shows as a plain chip (cannot afford yet).
  final String? buyLabel;
  final VoidCallback? onBuy;
  final String? buySemanticLabel;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final int shown = level.clamp(0, maxLevel).toInt();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: theme.colors.border, width: AppStroke.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            MergeSemantics(
              child: Semantics(
                value: levelLabel,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(child: Text(name, style: theme.type.title2)),
                        const SizedBox(width: AppSpacing.s8),
                        ExcludeSemantics(child: _Pips(level: shown, max: maxLevel, colors: theme.colors)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      effectLine,
                      style: theme.type.footnote.copyWith(color: theme.colors.textPrimary),
                    ),
                    if (verseText != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.s8),
                      Text(
                        verseText!,
                        style: theme.type.footnote.copyWith(color: theme.colors.textSecondary),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.s2),
                    Text(verseReference, style: theme.type.caption),
                  ],
                ),
              ),
            ),
            if (buyLabel != null) ...<Widget>[
              const SizedBox(height: AppSpacing.s8),
              AppChip(
                label: buyLabel!,
                tone: onBuy != null ? ChipTone.accent : ChipTone.neutral,
                onTap: onBuy,
                semanticLabel: buySemanticLabel,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Pips extends StatelessWidget {
  const _Pips({required this.level, required this.max, required this.colors});

  final int level;
  final int max;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < max; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: AppSpacing.s4),
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < level ? colors.accent : colors.bgTertiary,
              border: Border.all(color: colors.border, width: AppStroke.hairline),
            ),
            child: const SizedBox(width: 10, height: 10),
          ),
        ],
      ],
    );
  }
}
