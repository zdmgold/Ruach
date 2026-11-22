import 'package:flutter/widgets.dart';
import 'package:ruach/theme/app_icon.dart';
import 'package:ruach/theme/app_theme.dart';
import 'package:ruach/theme/tokens.dart';

/// What a list shows when it has nothing to show: an icon, a title and an
/// optional line of explanation, centred. Never a blank box.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    super.key,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Optional next step, for example a `PrimaryButton`.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppIcon(icon, size: AppIconSizes.hero, color: theme.colors.textTertiary),
            const SizedBox(height: AppSpacing.s16),
            Text(title, textAlign: TextAlign.center, style: theme.type.title2),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: AppSpacing.s8),
              Text(subtitle!, textAlign: TextAlign.center, style: theme.type.footnote),
            ],
            if (action != null) ...<Widget>[
              const SizedBox(height: AppSpacing.s24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
