import 'package:flutter/widgets.dart';
import 'package:ruach/theme/app_icon.dart';
import 'package:ruach/theme/app_theme.dart';
import 'package:ruach/theme/icons.dart';
import 'package:ruach/theme/tokens.dart';

/// A Gift count with its icon. The spoken label ("12 Gifts") comes from the
/// caller, so plurals stay in the language files.
class GiftBadge extends StatelessWidget {
  const GiftBadge({required this.count, required this.semanticLabel, super.key});

  final int count;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    return Semantics(
      label: semanticLabel,
      container: true,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppIcon(AppIcons.gift, size: AppIconSizes.rowTrailing, color: theme.colors.giftFill),
          const SizedBox(width: AppSpacing.s4),
          Text(
            '${count < 0 ? 0 : count}',
            style: theme.type.callout.copyWith(
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
