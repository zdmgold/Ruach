import 'package:flutter/widgets.dart';
import 'package:ruach/theme/app_icon.dart';
import 'package:ruach/theme/app_theme.dart';
import 'package:ruach/theme/icons.dart';
import 'package:ruach/theme/tokens.dart';

/// Three stars, 0 to 3 earned. Earned stars are drawn in the star colour,
/// the rest faded. The spoken label ("2 of 3 stars") comes from the caller.
class StarBadge extends StatelessWidget {
  const StarBadge({
    required this.stars,
    required this.semanticLabel,
    super.key,
    this.size = AppIconSizes.rowTrailing,
  });

  final int stars;
  final String semanticLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final int earned = stars.clamp(0, 3).toInt();
    return Semantics(
      label: semanticLabel,
      container: true,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < 3; i++)
            Opacity(
              opacity: i < earned ? 1 : 0.3,
              child: AppIcon(
                AppIcons.star,
                size: size,
                color: i < earned ? theme.colors.starFill : theme.colors.textTertiary,
              ),
            ),
        ],
      ),
    );
  }
}
