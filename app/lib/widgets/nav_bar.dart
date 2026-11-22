import 'package:flutter/widgets.dart';
import 'package:ruach/theme/app_icon.dart';
import 'package:ruach/theme/app_theme.dart';
import 'package:ruach/theme/icons.dart';
import 'package:ruach/theme/tokens.dart';
import 'package:ruach/widgets/pressable.dart';

/// The bar at the top of every screen: the brand or a back button on the
/// start side, the title, and action chips on the end side. It sits under the
/// status bar and stays fixed while content scrolls.
class NavBar extends StatelessWidget {
  const NavBar({
    required this.title,
    super.key,
    this.brand,
    this.onBack,
    this.backLabel,
    this.actions = const <Widget>[],
  }) : assert(onBack == null || backLabel != null, 'a back button needs a spoken label');

  final String title;

  /// The brand name, shown instead of a back button on top-level screens.
  final String? brand;

  /// Shows a back button when set.
  final VoidCallback? onBack;

  /// Spoken label of the back button.
  final String? backLabel;

  /// Usually `AppChip`s (Gifts, streak).
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final double top = MediaQuery.maybePaddingOf(context)?.top ?? 0;
    final Widget? leading = onBack != null
        ? Pressable(
            onTap: onBack,
            semanticLabel: backLabel,
            builder: (BuildContext context, bool pressed) => AppIcon(
              AppIcons.back,
              size: AppIconSizes.navBar,
              color: theme.colors.textPrimary,
            ),
          )
        : (brand != null ? Text(brand!, style: theme.type.title1.copyWith(color: theme.colors.accent)) : null);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.bgPrimary,
        border: Border(
          bottom: BorderSide(color: theme.colors.border, width: AppStroke.hairline),
        ),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          top: top,
          start: AppSpacing.s8,
          end: AppSpacing.s16,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppHit.min + AppSpacing.s8),
          child: Row(
            children: <Widget>[
              if (leading != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpacing.s8, start: AppSpacing.s8),
                  child: leading,
                ),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.type.title2,
                  ),
                ),
              ),
              for (final Widget action in actions) ...<Widget>[
                const SizedBox(width: AppSpacing.s8),
                action,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
