import 'package:flutter/widgets.dart';

import 'package:ruach/theme/app_theme.dart';
import 'package:ruach/theme/tokens.dart';

/// The only widget that draws an icon. It fixes the size scale and the colour
/// default.
///
/// Whether a symbol mirrors in right-to-left languages is part of the icon
/// itself (see `AppIcons`), so this widget needs no flag for it. It never
/// builds a new [IconData], which would stop the build tool from trimming
/// unused symbols from the icon font.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    super.key,
    this.size = AppIconSizes.rowLeading,
    this.color,
    this.semanticLabel,
  });

  /// The symbol, taken from `AppIcons` in `icons.dart`.
  final IconData icon;

  /// One of the sizes in [AppIconSizes].
  final double size;

  /// Defaults to the primary text colour of the current theme.
  final Color? color;

  /// Read aloud by screen readers. Leave null for a purely decorative icon.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: color ?? AppTheme.of(context).colors.textPrimary,
      semanticLabel: semanticLabel,
    );
  }
}
